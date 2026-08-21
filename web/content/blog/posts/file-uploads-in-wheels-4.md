---
title: 'File Uploads in Wheels 4.0, the Idiomatic Way'
slug: file-uploads-in-wheels-4
publishedAt: '2026-07-07T14:00:00.000Z'
updatedAt: '2026-06-19T15:10:00.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - uploads
  - forms
  - controllers
categories: []
excerpt: >-
  Wheels 4.0 has no ActiveStorage-style attachment system — and that's fine.
  This how-to walks the honest idiomatic upload flow end to end:
  fileField/fileFieldTag form helpers, the startFormTag multipart trap, native
  cffile in the controller, model validation over the result, and
  traversal-safe downloads with sendFile.
coverImage: null
---

You've got a `User` model, an edit form, and a product manager who wants profile pictures by Friday. You reach for the Wheels docs, search "upload," and find… a form helper called `fileField` and not much else. No `hasAttachment`. No `mount`. No storage service. No `params.file` object waiting for you with a `.save()` method.

So you do what you always do — you Google "Rails Active Storage Wheels equivalent," find nothing, and start to wonder if you're holding the framework wrong.

You're not. Wheels 4.0 has no dedicated file-upload abstraction, and that's a deliberate, honest design rather than a gap someone forgot to fill. The framework gives you the two ends that genuinely need framework knowledge — emitting the right form field, and serving a stored file back safely — and gets out of the way for the middle, which is plain CFML `cffile` that the language has done well for two decades. This post walks the whole flow end to end: the form, the controller, the model, and the download. It also calls out the one trap that silently eats more uploads than every other mistake combined.

Let's build avatar uploads for a `User`.

## There is no upload abstraction, and that's the point

Before the code, set your expectations correctly, because half the frustration with Wheels uploads comes from looking for a thing that isn't there.

Grep the framework for a storage layer — `storeFile`, `saveFile`, `mountUploader`, `activeStorage`, anything that processes your bytes — and you find nothing in `vendor/wheels/`. The word "upload" turns up, but only in comments and doc strings (for example the `@multipart` note on `startFormTag` that says it lets "the form be able to upload files") — never as an abstraction that does the work. There is no model macro that mounts a file column. There is no service you register in `config/services.cfm`. `cffile` and `fileUpload()` appear **zero** times in `vendor/wheels/controller/`. The framework genuinely does not process your multipart bytes for you.

What it gives you instead is a five-step idiom, and every step maps to a tool that already exists:

| Step | Tool | Who owns it |
|---|---|---|
| 1. Emit the file input | `fileField` / `fileFieldTag` | Wheels view helper |
| 2. Make the form send bytes | `startFormTag(multipart=true)` | Wheels view helper |
| 3. Receive the upload | `cffile action=&quot;upload&quot;` / `fileUpload()` | **Native CFML — no wrapper** |
| 4. Validate size/type | `validatesFormatOf` + custom `validate()` | Wheels model |
| 5. Serve it back safely | `sendFile` | Wheels controller helper |

Notice where the framework shows up and where it doesn't. Steps 1, 2, 4, and 5 are Wheels. Step 3 — the actual receiving of the file — is you calling `cffile`. That's not the framework being lazy; it's the framework declining to wrap a perfectly good language primitive in a leaky abstraction.

If you want corroboration that this is the intended path and not a workaround, the framework's own AI-reference doc agrees with it. Inside `vendor/wheels/public/views/ai.cfm` (a JSON blob the framework ships to describe itself to coding assistants), the canonical "File Uploads" pattern is literally `fileUpload(expandPath('./public/uploads/'), 'avatar', 'image/*', 'MakeUnique')` reading `.serverFile`, paired with a `startFormTag(enctype='multipart/form-data')`. The framework documents native CFML as *the* upload path. It's illustrative snippet text, not executed code — but it's the framework telling you, in its own voice, "use `cffile`."

Good. Now build it.

## Step 1 + 2: the form, and the trap that will get you

Here's the edit view, `app/views/users/edit.cfm`. `cfparam` every variable that comes from the controller — that's a Wheels habit you keep regardless of what the form does:

```cfm
<!--- app/views/users/edit.cfm --->
<cfparam name="user" default="">

#startFormTag(route="user", key=user.key(), method="patch", multipart=true)#
    #textField(objectName="user", property="firstName")#
    #fileField(objectName="user", property="avatar", label="Profile picture")#
    #submitTag(value="Save")#
#endFormTag()#
```

That `multipart=true` on `startFormTag` is the single most important character in this entire post. Read this twice:

**`startFormTag` does NOT detect that you have a `fileField` on the form. It does NOT add the multipart enctype on its own. The framework default is `multipart=false`.**

The logic inside `vendor/wheels/view/forms.cfc` is exactly:

```cfm
// set the form to be able to handle file uploads
if (!StructKeyExists(arguments, "enctype") && arguments.multipart) {
    arguments.enctype = "multipart/form-data";
}
```

The enctype only gets added when `multipart` is true *and* you didn't pass an explicit `enctype`. The init default for `multipart` is `false`. So if you write a perfectly correct-looking form with a `fileField` in it and forget `multipart=true`, here's what happens:

- The form renders without `enctype="multipart/form-data"`.
- The browser submits the file input as a plain text field containing only the **filename string**.
- `params` has no file. `form["user[avatar]"]` is `"vacation.jpg"`, a string, not an upload.
- `cffile action="upload"` finds nothing and either errors or no-ops.
- **No exception is thrown by the framework. The upload silently fails.**

This is the classic Wheels upload bug, and it's nasty precisely because everything looks right. The field is there, the label is there, the form posts, the page redirects — and the file just isn't anywhere. You'll burn an hour adding `writeDump` calls before you notice the missing enctype in View Source.

There are two ways to be correct, and you only need one:

```cfm
<!--- Idiomatic: let Wheels build the enctype from the multipart flag --->
#startFormTag(route="user", key=user.key(), method="patch", multipart=true)#

<!--- Explicit escape hatch: set enctype yourself --->
#startFormTag(route="user", key=user.key(), method="patch", enctype="multipart/form-data")#
```

Both produce `enctype="multipart/form-data"`. Pick `multipart=true` — it reads as intent ("this form carries files") rather than as a protocol detail, and it's the form the framework treats as canonical.

While we're here: `startFormTag` with `method="patch"` does two more useful things for free. It rewrites the method to `post` and injects a hidden `_method` field so Wheels' routing sees a PATCH, and it injects the CSRF `authenticityTokenField` because the method is non-GET. You don't have to think about either — they just work alongside the multipart enctype.

### What `fileField` actually emits

`fileField(objectName="user", property="avatar")` is object-bound, which means it follows the standard Wheels bracket naming convention. It runs the usual `$objectName` / `$primeBoundObject` / `$applyAutoId` pipeline, then hard-sets `type="file"` and a name of `$tagName(objectName, property)`. The result is an input whose name is `user[avatar]` (HTML-escaped in the markup, but `user[avatar]` is what arrives server-side).

That bracketed name matters in Step 3 — it's the exact string you hand to `cffile`. Write it down: **`fileField(objectName="user", property="avatar")` posts under `user[avatar]`.**

One thing `fileField` does *not* do, and cannot do: pre-populate. A file `<input>` never round-trips a value across requests — browsers won't let a server pre-fill a file picker, for obvious security reasons. So binding here is purely about producing the right `name` attribute and wrapping a `<label>`. It will never show the previously-uploaded file. If you want to show "current avatar: vacation.jpg," render that yourself next to the field from the model's stored path.

### When there's no model property: `fileFieldTag`

Sometimes the upload isn't tied to a model attribute at all — a CSV import, a one-off document. Use the unbound variant, `fileFieldTag`:

```cfm
<!--- A standalone upload not tied to a model attribute --->
#startFormTag(action="import", method="post", multipart=true)#
    #fileFieldTag(name="document", label="CSV to import")#
    #submitTag(value="Import")#
#endFormTag()#
```

`fileFieldTag(name="document")` renders `<input id="document" name="document" type="file">` — a plain, unbracketed name. Under the hood it's a thin shim: it synthesizes a throwaway objectName struct (`{document: ""}`) and delegates straight to `fileField`, which is why the two helpers behave identically except for the name shape. Bound field → bracketed `user[avatar]`. Unbound field → plain `document`. That's the only difference you care about, and it's the difference that determines what you type in the controller.

## Step 3: the controller, where native CFML does the work

No Wheels helper receives the file. You call `cffile action="upload"` yourself, then hand the *result* to the model. Here's `app/controllers/Users.cfc`:

```cfm
// app/controllers/Users.cfc
function update() {
    user = model("User").findByKey(params.key);

    // The fileField above posts under the bracketed name user[avatar].
    // Process the multipart part with native CFML -- Wheels has no wrapper.
    if (StructKeyExists(form, "user[avatar]") && Len(form["user[avatar]"])) {
        local.dest = ExpandPath("/public/uploads/avatars");
        cffile(
            action       = "upload",
            fileField    = "user[avatar]",   // the form field name from fileField
            destination  = local.dest,
            nameConflict = "makeUnique",      // never trust the client filename
            accept       = "image/png,image/jpeg",
            strict       = true
        );
        // cffile populates the `cffile` result struct on success.
        params.user.avatar     = "/uploads/avatars/" & cffile.serverFile;
        params.user.avatarSize = cffile.fileSize;       // bytes, for model validation
        params.user.avatarType = cffile.contentType & "/" & cffile.contentSubType;
    }

    if (user.update(params.user)) {
        redirectTo(route="user", key=user.key(), success="Saved.");
    } else {
        renderView(action="edit");
    }
}
```

Walk through the load-bearing lines:

**The field name.** `fileField` posted under `user[avatar]`, so that's the `fileField` argument to `cffile` and the key you check in the `form` scope. If you'd used `fileFieldTag(name="document")`, it'd be `"document"` everywhere instead. The name on the form is the contract; match it exactly.

**`nameConflict="makeUnique"`.** This is your first and best line of defense against a hostile filename. The client controls the original name, and a client who names their file `../../../config/settings.cfm` is trying to ruin your afternoon. `makeUnique` makes `cffile` generate a non-colliding server filename, so an attacker can neither overwrite an existing file nor steer the write outside your directory. Use it by default.

**`accept` + `strict=true`.** A first cut at type filtering at the CFML layer. Don't trust it as your only check — `accept` can be fooled by content-type spoofing on some engines — but combined with the model-level validation in Step 4 it's a solid belt-and-suspenders.

**Copying the result onto `params.user`.** This is the move that connects native CFML back to Wheels. The `cffile` result struct (`cffile.serverFile`, `cffile.fileSize`, `cffile.contentType`, `cffile.contentSubType`) holds everything about the saved file. You copy the bits you want to persist or validate onto the params struct that feeds `user.update()`. The model never sees a multipart object — it sees plain strings and numbers you handed it. That's what makes the next step possible.

**You persist the path, not the bytes.** `params.user.avatar` becomes `/uploads/avatars/whatever-unique-name.png`. The file lives on disk; the model column holds a string pointing at it. There is no convention forcing this — the framework won't stop you from doing something worse — but storing a relative path and keeping the bytes on the filesystem (or in object storage) is the sane default. The framework's own ai.cfm example does exactly this: it writes to `./public/uploads/` and saves `'/uploads/' & serverFile`.

A note on storage location: keep uploads either fully outside the web-servable tree or under a controlled public path you understand. There's no enforced convention, which means the decision — and its security consequences — is yours. If files must be access-controlled (private documents, anything per-user), do **not** put them somewhere the web server hands out directly; store them outside the docroot and serve them through a controller with `sendFile` (Step 5), where you can run an authorization check first.

## Step 4: validation runs on strings, not on the upload

Here's the part that trips people who expect a `validatesFileSize` helper: **Wheels validators cannot inspect a multipart upload.** `validatesFormatOf`, `validatesLengthOf`, `validatesInclusionOf` — none of them understand file objects, byte sizes, or MIME types. They validate *string properties on the model*. That's it.

Which is fine, because you already did the work to make them useful. In Step 3 you copied `cffile.fileSize` and the content type onto `params.user`, so by the time the model validates, those are ordinary properties it can reason about. The model, `app/models/User.cfc`:

```cfm
// app/models/User.cfc
component extends="Model" {
    function config() {
        // Validate the stored path/extension as a plain string.
        validatesFormatOf(property="avatar", regEx="\.(png|jpe?g)$", allowBlank=true,
            message="Avatar must be a PNG or JPEG.");

        // File-specific rules the built-ins can't express -> custom callback.
        validate("validateAvatarUpload");
    }

    void function validateAvatarUpload() {
        // avatarSize was set in the controller from cffile.fileSize.
        if (StructKeyExists(this, "avatarSize") && Val(this.avatarSize) > 2 * 1024 * 1024) {
            addError(property="avatar", message="Avatar must be 2 MB or smaller.");
        }
        if (StructKeyExists(this, "avatarType")
            && Len(this.avatarType)
            && !ListFindNoCase("image/png,image/jpeg", this.avatarType)) {
            addError(property="avatar", message="Unsupported image type.");
        }
    }
}
```

Two layers, two jobs:

**`validatesFormatOf` for the cheap string check.** The stored `avatar` value ends in `.png` / `.jpg` / `.jpeg` or it's blank. `allowBlank=true` lets a user save the form without re-uploading. All arguments named — never mix positional and named in a Wheels call; that's the number-one error source in the framework, and validators are a prime offender. It's `validatesFormatOf(property=..., regEx=..., message=...)`, all named, every time. (`property` is the singular alias for `properties` — both resolve through `$combineArguments`, so either spelling is correct.)

**A custom `validate()` callback for everything format can't express.** `validate("validateAvatarUpload")` registers a method that runs at save time, and inside it you have the full model instance — `this.avatarSize`, `this.avatarType` — to apply any rule you want. Max byte size? `Val(this.avatarSize) > 2 * 1024 * 1024`. Allowed MIME types? `ListFindNoCase(...)`. Image dimensions, aspect ratios, a virus-scan flag you set earlier — all of it goes here. When a rule fails, call `addError(property="avatar", message="...")` and the save fails with that message attached to the field, exactly like a built-in validator. (Follow the framework's own reference and declare the callback as a plain `function` on the model — it's invoked internally at save time, so it doesn't need to be public-facing, but don't mark it `private`; the documented pattern uses default access.)

This is *the* idiomatic hook for file rules. The built-ins handle the string; the custom `validate()` handles the file-ness.

One ordering subtlety worth internalizing: by the time the model validates, **the file is already on disk.** `cffile action="upload"` ran in the controller and physically wrote the bytes before `user.update()` was ever called. So a model validation failure stops the database row from saving — but it does not un-write the file. If a 5 MB upload fails your 2 MB check, the model correctly refuses to save, but a 5 MB orphan is now sitting in `/public/uploads/avatars`. Reject-and-delete cleanup belongs in your controller or your `validate` method, not in the DB layer — because the DB layer runs too late to prevent the write. For most apps a periodic sweep of orphaned uploads is simpler than trying to delete inline; just know the orphan exists and decide deliberately.

## Step 5: serving it back, the one direction with a real helper

Upload is native CFML. Download is where Wheels finally hands you a purpose-built helper: `sendFile`. Use it especially when the file lives outside the docroot or needs an auth check before it's served.

```cfm
// app/controllers/Users.cfc
function avatar() {
    user = model("User").findByKey(params.key);
    // sendFile strips null bytes and throws Wheels.InvalidPath on ".." segments.
    sendFile(
        file        = ListLast(user.avatar, "/"),
        directory   = ExpandPath("/public/uploads/avatars"),
        disposition = "inline"   // "attachment" (default) forces a download dialog
    );
}
```

`sendFile` streams a stored file back to the browser, and crucially it guards the path on the way out. It strips null bytes from both `file` and `directory`, and it throws `Wheels.InvalidPath` if a `..` segment appears after URL-decoding and backslash-normalizing the arguments — so encoded traversal variants get caught too. That's why this `avatar()` action is safe even though `user.avatar` ultimately traces back to a user-supplied upload: even if a malicious filename slipped past your upload sanitization, `sendFile` refuses to walk out of the directory.

`disposition` controls the browser's behavior. The framework default is `"attachment"`, which forces a download dialog — right for documents, PDFs, exports. Pass `"inline"` when you want the browser to render the file in place, which is what you want for an avatar shown in an `<img>` tag pointing at `/users/42/avatar`.

There is no symmetric upload helper — `sendFile` is download-only. But it pairs naturally with the storage decision you made in Step 3: the relative path you persisted on the model is exactly what you decompose into `sendFile`'s `file` + `directory` arguments. Store deliberately on the way in, serve safely on the way out.

## Sharp edges

Everything below is a real, source-confirmed trap. None of it is hypothetical.

**The multipart enctype is not automatic — this is the one that gets everyone.** `startFormTag` does not scan the form for `fileField`s and does not set the enctype by itself. The default is `multipart=false`. Forget `multipart=true` (or an explicit `enctype="multipart/form-data"`) and the file posts as a plain-text filename, `params` has no upload, and the framework throws no error. It fails silently. If an upload "isn't working" and you've checked everything else, check View Source for `enctype` first.

**There is no upload abstraction, full stop.** No `hasAttachment`, no `mount`, no upload service, no `params.file`. Don't go looking for one, and don't let an AI assistant invent one for you — if you see `mountUploader` or `hasAttachment` in generated code, it's hallucinated. The real flow is the five steps above. (There *is* an internal `$file()` in `vendor/wheels/Global.cfc`, but it is **not** an upload API — it's an internal (`$`-prefixed) `cffile` wrapper that exists solely for a cross-engine `attributeCollection` gotcha. It is not your upload path. Native `cffile` in your controller is.)

**Validators can't see the upload — only strings.** `validatesFormatOf` and friends validate model properties, never multipart objects. To validate size or MIME type you must (a) process the upload in the controller, (b) copy `cffile.fileSize` / content type onto model properties, then (c) validate those — ideally in a custom `validate()` callback. There is no shortcut that skips the controller step.

**The file is on disk before validation runs.** `cffile` writes the bytes in the controller; the model validates afterward. A validation failure prevents the DB row but leaves the file behind. Handle reject-and-delete in the controller or `validate` method, and accept that orphans are possible — plan a cleanup strategy.

**Path-traversal safety on the way *in* is your job.** `sendFile` guards the *download* path (it throws `Wheels.InvalidPath` on `..` and strips null bytes), but nothing guards the *upload destination*. When you build a storage path from a user-supplied filename, sanitize it yourself — and lean on `nameConflict="makeUnique"` so an attacker-chosen name can neither overwrite a file nor escape the directory.

**Match the field name exactly across all three places.** `fileField(objectName="user", property="avatar")` → name `user[avatar]` → `cffile fileField="user[avatar]"` → `StructKeyExists(form, "user[avatar]")`. `fileFieldTag(name="document")` → name `document` → `cffile fileField="document"`. Bound fields are bracketed; unbound fields are plain. Mismatch the name and `cffile` finds nothing — another flavor of the silent failure.

## The whole flow, in one breath

You wanted profile pictures by Friday, and the framework didn't hand you a magic attachment macro. What it handed you is better understood than magic: a form helper that emits the right field, a flag that makes the form send bytes, a language primitive that's been receiving uploads reliably for twenty years, a validation hook that runs over plain strings you control, and a download helper that won't let a hostile path walk out of your upload folder.

```
fileField / fileFieldTag      ->  the input, named correctly
startFormTag(multipart=true)  ->  enctype="multipart/form-data" (NOT automatic!)
cffile action="upload"        ->  native CFML, no wrapper, makeUnique the name
copy result -> params -> model ->  fileSize + contentType as plain properties
validatesFormatOf + validate()->  rules over strings, not over the upload
persist the path, store bytes ->  /uploads/... on the model, file on disk
sendFile                      ->  traversal-safe serving back
```

Five steps. Two of them are Wheels at the edges, one of them is CFML in the middle, and the whole thing is honest about what it is. Get the `multipart=true` right and you'll never fight an upload again.
