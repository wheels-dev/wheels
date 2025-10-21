# File Downloads

## Description
Serve files for download using Wheels' `sendFile()` method with support for secure file serving, custom headers, and content type detection.

## Key Points
- Use `sendFile()` to serve files for download
- Automatic content type detection
- Custom filename and headers support
- Secure file access with authentication
- Streaming for large files
- Error handling for missing files

## Code Sample
```cfm
component extends="Controller" {
    function config() {
        // Require authentication for file downloads
        filters(through="authenticate", except="publicDownload");

        // Find file for secure downloads
        filters(through="findFile", only="download,preview");
    }

    // Basic file download
    function download() {
        local.filePath = expandPath("./public/downloads/#params.filename#");

        if (FileExists(local.filePath)) {
            sendFile(
                file=local.filePath,
                name=params.filename,
                type="application/octet-stream",
                disposition="attachment"
            );
        } else {
            flashInsert(error="File not found");
            redirectTo(action="index");
        }
    }

    // Secure file download with access control
    function secureDownload() {
        fileRecord = model("FileUpload").findByKey(params.key);
        user = currentUser();

        // Check if user has permission to download
        if (!fileRecord.canBeAccessedBy(user)) {
            flashInsert(error="Access denied");
            redirectTo(controller="home", action="index");
            return;
        }

        local.filePath = expandPath("./secure/#fileRecord.storedFilename#");

        if (FileExists(local.filePath)) {
            sendFile(
                file=local.filePath,
                name=fileRecord.originalFilename,
                type=fileRecord.mimeType,
                disposition="attachment"
            );

            // Log download
            fileRecord.update(downloadCount=fileRecord.downloadCount + 1);
            model("DownloadLog").create({
                fileId=fileRecord.id,
                userId=user.id,
                downloadedAt=Now()
            });
        } else {
            flashInsert(error="File no longer available");
            redirectTo(route="file", key=fileRecord.id);
        }
    }

    // File preview (inline display)
    function preview() {
        document = model("Document").findByKey(params.key);

        if (IsObject(document) && document.isPreviewable()) {
            local.filePath = expandPath("./documents/#document.filename#");

            sendFile(
                file=local.filePath,
                name=document.filename,
                type=document.mimeType,
                disposition="inline"  // Display in browser instead of download
            );
        } else {
            flashInsert(error="Preview not available");
            redirectTo(action="index");
        }
    }

    // Report generation and download
    function generateReport() {
        // Generate report data
        reportData = getReportData(params.startDate, params.endDate);

        // Create temporary file
        local.tempPath = getTempDirectory() & "report_" & CreateUUID() & ".csv";
        local.csvContent = generateCSV(reportData);

        FileWrite(local.tempPath, local.csvContent);

        // Send file and clean up
        try {
            sendFile(
                file=local.tempPath,
                name="sales_report_#DateFormat(Now(), 'yyyy-mm-dd')#.csv",
                type="text/csv",
                disposition="attachment"
            );
        } finally {
            // Clean up temporary file
            if (FileExists(local.tempPath)) {
                FileDelete(local.tempPath);
            }
        }
    }

    // Image resizing and download
    function resizeImage() {
        originalImage = model("Image").findByKey(params.key);
        width = params.width ?: 800;
        height = params.height ?: 600;

        local.originalPath = expandPath("./images/#originalImage.filename#");
        local.resizedPath = getTempDirectory() & "resized_" & CreateUUID() & ".jpg";

        // Resize image (pseudo-code - use ImageNew, ImageResize, etc.)
        local.image = ImageRead(local.originalPath);
        ImageResize(local.image, width, height);
        ImageWrite(local.image, local.resizedPath, "jpg");

        try {
            sendFile(
                file=local.resizedPath,
                name="resized_#originalImage.filename#",
                type="image/jpeg",
                disposition="attachment"
            );
        } finally {
            if (FileExists(local.resizedPath)) {
                FileDelete(local.resizedPath);
            }
        }
    }

    // Batch file download as ZIP
    function downloadBatch() {
        selectedFiles = model("File").findAll(where="id IN (#params.fileIds#)");

        local.zipPath = getTempDirectory() & "batch_download_" & CreateUUID() & ".zip";
        local.zip = new ZipTool();

        // Add files to ZIP
        for (file in selectedFiles) {
            local.filePath = expandPath("./files/#file.storedName#");
            if (FileExists(local.filePath)) {
                zip.addFile(local.filePath, file.originalName);
            }
        }

        zip.save(local.zipPath);

        try {
            sendFile(
                file=local.zipPath,
                name="files_#DateFormat(Now(), 'yyyy-mm-dd')#.zip",
                type="application/zip",
                disposition="attachment"
            );
        } finally {
            if (FileExists(local.zipPath)) {
                FileDelete(local.zipPath);
            }
        }
    }

    // Public file download (no authentication)
    function publicDownload() {
        // Public files in /public/downloads/
        local.filePath = expandPath("./public/downloads/#params.filename#");
        local.allowedExtensions = "pdf,doc,docx,txt,jpg,png,gif";

        // Validate file extension for security
        local.fileExtension = ListLast(params.filename, ".");
        if (!ListFindNoCase(local.allowedExtensions, local.fileExtension)) {
            flashInsert(error="File type not allowed");
            redirectTo(action="index");
            return;
        }

        if (FileExists(local.filePath)) {
            sendFile(
                file=local.filePath,
                name=params.filename
                // Type and disposition auto-detected
            );
        } else {
            flashInsert(error="File not found");
            redirectTo(action="index");
        }
    }

    // Helper methods
    private function authenticate() {
        if (!StructKeyExists(session, "userId")) {
            flashInsert(error="Please login to download files");
            redirectTo(controller="sessions", action="new");
        }
    }

    private function findFile() {
        if (!StructKeyExists(variables, "fileRecord")) {
            variables.fileRecord = model("File").findByKey(params.key);
            if (!IsObject(variables.fileRecord)) {
                flashInsert(error="File not found");
                redirectTo(action="index");
            }
        }
    }

    private function currentUser() {
        if (!StructKeyExists(variables, "currentUser")) {
            variables.currentUser = model("User").findByKey(session.userId);
        }
        return variables.currentUser;
    }
}

// File upload handling (complement to downloads)
function upload() {
    if (StructKeyExists(form, "file") && Len(form.file)) {
        local.uploadDir = expandPath("./uploads/");
        local.allowedTypes = "jpg,jpeg,png,gif,pdf,doc,docx,txt";

        try {
            local.uploadResult = FileUpload(
                local.uploadDir,
                "file",
                local.allowedTypes,
                "MakeUnique"
            );

            // Save file record to database
            fileRecord = model("FileUpload").create({
                originalFilename = local.uploadResult.clientFile,
                storedFilename = local.uploadResult.serverFile,
                fileSize = local.uploadResult.fileSize,
                mimeType = local.uploadResult.contentType,
                uploadedBy = session.userId,
                uploadedAt = Now()
            });

            if (fileRecord.valid()) {
                flashInsert(success="File uploaded successfully");
                redirectTo(route="file", key=fileRecord.id);
            }
        } catch (any e) {
            flashInsert(error="Upload failed: #e.message#");
            renderView(action="new");
        }
    }
}
```

## Usage
1. Call `sendFile()` with file path and optional parameters
2. Handle authentication and authorization before serving files
3. Validate file paths and extensions for security
4. Clean up temporary files after sending
5. Log downloads for audit purposes

## Parameters
- `file` (required) - Absolute path to the file
- `name` (optional) - Custom filename for download
- `type` (optional) - MIME type (auto-detected if not provided)
- `disposition` (optional) - "attachment" (download) or "inline" (display)

## Related
- [File Uploads](./uploads.md)
- [Security](../security/https-detection.md)
- [Controller Filters](../controllers/filters/authentication.md)

## Important Notes
- Always validate file paths to prevent directory traversal attacks
- Use absolute paths with `expandPath()` for file locations
- Check file existence before attempting to serve
- Implement proper access control for sensitive files
- Clean up temporary files to prevent disk space issues
- Consider streaming for very large files

## Security Best Practices
```cfm
// Validate file path to prevent directory traversal
private function isValidFilePath(required string filename) {
    // Remove any path separators and parent directory references
    local.cleanName = Replace(arguments.filename, "..", "", "ALL");
    local.cleanName = Replace(local.cleanName, "/", "", "ALL");
    local.cleanName = Replace(local.cleanName, "\", "", "ALL");

    return local.cleanName == arguments.filename;
}

// Check file extension whitelist
private function isAllowedFileType(required string filename) {
    local.allowedExtensions = "pdf,doc,docx,txt,jpg,png,gif,zip";
    local.extension = LCase(ListLast(arguments.filename, "."));

    return ListFindNoCase(local.allowedExtensions, local.extension);
}

// Rate limiting for downloads
private function checkDownloadLimit() {
    local.userDownloads = model("DownloadLog").count(
        where="userId = #session.userId# AND downloadedAt > #DateAdd('h', -1, Now())#"
    );

    if (local.userDownloads > 10) {
        flashInsert(error="Download limit exceeded. Please try again later.");
        redirectTo(action="index");
    }
}
```

## Performance Considerations
- Use `cfcontent` with `cfheader` for more control over large files
- Implement resume support for large downloads
- Consider CDN integration for frequently downloaded files
- Cache file metadata to avoid repeated database queries
- Use appropriate buffer sizes for file streaming