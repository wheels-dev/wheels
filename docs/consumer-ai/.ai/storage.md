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

// config/services.cfm
local.di.map("storage").toFactory(function() {
    return new wheels.storage.StorageManager(config = get("storage"));
});
```

```cfm
service("storage").disk().put("avatars/42.png", bytes, contentType="image/png", visibility="public");
bytes = service("storage").disk().get("avatars/42.png");
url = service("storage").disk("s3").signedUrl(key="reports/q3.pdf", expiresIn=900);
```

`disk()` returns the default disk; `disk("name")` a named one. `get()` returns binary; `put()` round-trips bytes exactly. Errors: `Wheels.Storage.NotFound`, `.UnknownDisk`, `.UnknownDriver`, `.InvalidKey`, `.InvalidExpiresIn` (`expiresIn` must be `1..604800`), `.MissingSigningKey` (local `signedUrl()` without a `signingKey`).

`LocalDisk` keys are relative to `root`; traversal (`../`), dot/space-only segments, and drive-letter/UNC prefixes are rejected with `.InvalidKey` (lexical check, all engines). For a hardened deployment, add `resolveSymlinks=true` to the local disk config to also reject a symlink under `root` that escapes it; it fails closed with `.InvalidConfiguration` at construction on runtimes that can't resolve symlinks (RustCFML, Windows without symlink privilege).
