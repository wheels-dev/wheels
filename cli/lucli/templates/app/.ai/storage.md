# Storage

Part of the Wheels application guide; start with `../CLAUDE.md`.

Named disks behind one interface — `put` / `get` / `exists` / `delete` / `url` / `signedUrl` — resolved through `wheels.storage.StorageManager`. Drivers: `local` (filesystem + URL prefix) and `s3` (from-scratch SigV4 over `cfhttp`, no AWS SDK).

```cfm
// config/settings.cfm
set(storage = {
    default = "local",
    disks = {
        local = { driver="local", root=ExpandPath("../storage/uploads"), urlPrefix="/uploads", signingKey=env("STORAGE_SIGNING_KEY") },
        s3 = { driver="s3", bucket="my-bucket", region="us-east-1", accessKeyId=env("S3_KEY"), secretAccessKey=env("S3_SECRET") }
    }
});

// config/services.cfm: nothing registers "storage" for you. asSingleton() keeps one manager
// (a factory binding is transient, so each service("storage") call would build a new one).
local.di.map("storage").toFactory(function() {
    return new wheels.storage.StorageManager(config = get("storage"));
}).asSingleton();
```

```cfm
service("storage").disk().put("avatars/42.png", bytes, contentType="image/png", visibility="public");
bytes = service("storage").disk().get("avatars/42.png");
url = service("storage").disk("s3").signedUrl(key="reports/q3.pdf", expiresIn=900);
```

`disk()` returns the default disk; `disk("name")` a named one. `get()` returns binary; `put()` round-trips bytes exactly. Errors: `Wheels.Storage.NotFound`, `.UnknownDisk`, `.UnknownDriver`, `.InvalidKey`, `.InvalidExpiresIn` (`expiresIn` must be `1..604800`), `.MissingSigningKey` (local `signedUrl()` without a `signingKey`).

`LocalDisk` keys are relative to `root`; traversal (`../`), dot/space-only segments, and drive-letter prefixes are rejected with `.InvalidKey` (lexical check, all engines). Leading/trailing/doubled slashes and UNC prefixes (`//server/share`) are normalised to a relative key under `root`, not rejected (#4023). For a hardened deployment, add `resolveSymlinks=true` to the local disk config to also reject a symlink under `root` that escapes it (a point-in-time check, not for untrusted concurrent writers); a non-boolean value or a runtime that can't resolve symlinks (RustCFML, Windows without symlink privilege) fails closed with `.InvalidConfiguration` at construction.

## Deleting files, and files that belong to records

`service("storage").disk().delete(key)` returns `true` when it removed an object and `false` when nothing was there; `exists(key)` likewise. Neither returns `false` for a failure: an invalid key throws `.InvalidKey`, and an S3 error or unreachable endpoint throws `.RequestFailed`. `put()` returns the key.

There is no attachment API on models. Store the key in a column, write the file with `put()`, and delete it yourself. Delete in `afterCommit`, not in `beforeDelete` / `afterDelete`: if the transaction rolls back, the row survives and must still find its file.

```cfm
// app/models/Document.cfc
function config() {
    afterCommit(methods="removeStoredFile", on="delete");
}
private void function removeStoredFile() {
    if (Len(this.fileKey)) service("storage").disk().delete(this.fileKey);
}
```

A model with a `deletedAt` column is soft-deleted by default (`.ai/models.md`). `afterCommit(on="delete")` fires for a soft delete exactly as for a permanent one, and can't tell them apart. If soft-deleted rows can be restored, don't remove their files in this callback; remove them in the code that purges rows for good.
