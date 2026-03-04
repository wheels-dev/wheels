# [Feature] File Storage Abstraction Layer

**Priority:** #2 — Table-stakes gap
**Labels:** `enhancement`, `feature-request`, `priority-high`

## Summary

Add a unified file storage abstraction that provides a consistent API for local filesystem, Amazon S3, Google Cloud Storage, and Azure Blob Storage — allowing developers to swap storage backends without changing application code.

## Justification

### Table-stakes feature that every modern framework provides

| Framework | Storage Solution | Details |
|-----------|-----------------|---------|
| **Laravel** | Flysystem integration | Local, S3, GCS, Azure, FTP, SFTP — unified `Storage` facade |
| **Rails** | Active Storage | Direct uploads, variants (image processing), mirrors, S3/GCS/Azure |
| **Django** | `django.core.files.storage` | Pluggable backends, `FileField`/`ImageField` model integration |
| **AdonisJS 6** | Drive | Local, S3, GCS — fluent API with streaming support |
| **Phoenix** | (Community packages) | Waffle, Arc — not built-in but standard community solutions |
| **Wheels** | **Nothing** | Raw `<cffile>` calls with no abstraction |

### Every modern web app handles file uploads

User avatars, document attachments, product images, CSV imports, PDF reports — file storage is a universal requirement. Without a framework-level abstraction, every Wheels developer must:

1. Write raw `<cffile>` upload handling
2. Manually manage storage paths and naming
3. Build their own S3 integration from scratch
4. Handle file deletion cleanup manually
5. Rewrite everything when moving from local to cloud storage

### Cloud storage is the default in 2025

Modern deployment targets (Docker, Kubernetes, serverless) have ephemeral filesystems. Files stored locally are lost on redeployment. A storage abstraction that supports cloud backends isn't a nice-to-have — it's required for modern deployment.

## Specification

### Core API

```cfm
// Store a file
storage().put(path="avatars/user-123.jpg", contents=fileContent);
storage().putFile(path="documents/", file=params.file);  // auto-generates name

// Retrieve
contents = storage().get(path="avatars/user-123.jpg");
url = storage().url(path="avatars/user-123.jpg");
temporaryUrl = storage().temporaryUrl(path="reports/q4.pdf", expiration=30);

// Check existence
exists = storage().exists(path="avatars/user-123.jpg");

// Delete
storage().delete(path="avatars/user-123.jpg");
storage().deleteDirectory(path="temp/uploads/");

// List
files = storage().files(directory="avatars/");
dirs = storage().directories(directory="uploads/");

// Switch disks at runtime
storage(disk="s3").put(path="backups/db.sql", contents=sqlDump);
storage(disk="local").put(path="cache/temp.txt", contents=data);
```

### Configuration

```cfm
// config/storage.cfm
set(storageDefaultDisk="local");

set(storageDisks={
    local: {
        driver: "local",
        root: ExpandPath("/storage/app/"),
        url: "/storage"
    },
    s3: {
        driver: "s3",
        bucket: GetEnvironmentValue("AWS_BUCKET"),
        region: GetEnvironmentValue("AWS_REGION", "us-east-1"),
        accessKeyId: GetEnvironmentValue("AWS_ACCESS_KEY_ID"),
        secretAccessKey: GetEnvironmentValue("AWS_SECRET_ACCESS_KEY"),
        url: GetEnvironmentValue("AWS_URL", "")
    },
    publicFiles: {
        driver: "s3",
        bucket: GetEnvironmentValue("AWS_PUBLIC_BUCKET"),
        visibility: "public"
    }
});
```

### Model Integration

```cfm
// app/models/User.cfc
component extends="Model" {
    function config() {
        hasAttachment(name="avatar", disk="s3", directory="avatars/");
        hasAttachment(name="resume", disk="s3", directory="resumes/", acceptedTypes="pdf,doc,docx");
    }
}

// Controller usage
user = model("User").findByKey(params.key);
user.attachAvatar(params.avatar);  // handles upload + storage
avatarUrl = user.avatarUrl();      // returns public URL
user.deleteAvatar();               // removes from storage
```

### View Helpers

```cfm
// File upload field (works with existing form helpers)
#fileField(objectName="user", property="avatar")#
#fileFieldTag(name="document", accept=".pdf,.doc")#

// Display stored file URL
<img src="#storage().url('avatars/user-123.jpg')#" alt="Avatar">
```

### Drivers to Implement

| Driver | Priority | Backend |
|--------|----------|---------|
| **Local** | P0 — Ship with v1 | Local filesystem with public/private visibility |
| **S3** | P0 — Ship with v1 | Amazon S3 (also works with MinIO, DigitalOcean Spaces, Backblaze B2) |
| **GCS** | P1 — Fast follow | Google Cloud Storage |
| **Azure** | P1 — Fast follow | Azure Blob Storage |

### Files Generated / Modified

| Component | File | Purpose |
|-----------|------|---------|
| **Core** | `wheels/Storage.cfc` | Storage manager with disk resolution |
| **Driver** | `wheels/storage/LocalDriver.cfc` | Local filesystem driver |
| **Driver** | `wheels/storage/S3Driver.cfc` | S3-compatible driver (via Java AWS SDK) |
| **Config** | `config/storage.cfm` | Default storage configuration |
| **Model mixin** | `wheels/model/Attachments.cfc` | `hasAttachment()` integration |
| **Migration** | Template for attachments table | Polymorphic attachment storage |
| **Tests** | `tests/wheels/StorageTest.cfc` | Driver tests with local filesystem |

## Impact Assessment

- **Developer productivity:** Eliminates boilerplate for the most common web task after authentication
- **Cloud-readiness:** Makes Wheels apps deployable to modern containerized environments
- **Competitive positioning:** Closes a major table-stakes gap — no modern framework lacks this

## References

- Laravel Filesystem: https://laravel.com/docs/filesystem
- Rails Active Storage: https://guides.rubyonrails.org/active_storage_overview.html
- Django File Storage: https://docs.djangoproject.com/en/5.0/ref/files/storage/
- AdonisJS Drive: https://docs.adonisjs.com/guides/drive
