# CLAUDE.md - Library (Custom Code & Utilities)

This file provides guidance to Claude Code (claude.ai/code) when working with custom libraries and utilities in a Wheels application.

## Overview

The `/app/lib/` folder is a conventional directory for organizing custom code that doesn't fit neatly into the standard MVC structure. This includes utility classes, third-party integrations, custom business logic components, and reusable code modules that extend your application's functionality.

**Why Use the lib/ Folder:**
- Organize custom classes and utilities outside the MVC pattern
- Store third-party integrations and wrappers
- Maintain reusable business logic components
- Keep application-specific extensions and helpers
- Provide a place for custom service objects and data processors

**Important:** While Wheels doesn't have strict conventions for the lib/ folder structure, following consistent patterns makes your code more maintainable and easier to understand.

## Relationship to Other Folders

### lib/ vs global/
- **global/**: Functions available everywhere automatically (similar to Application.cfc functions)
- **lib/**: Classes and components that need to be explicitly instantiated or included

### lib/ vs services/ (CLI Generated)
- **services/**: Business logic services generated via CLI (`wheels g service`)
- **lib/**: Custom utilities, integrations, and classes that may not follow service patterns

### lib/ vs helpers/ (CLI Generated)
- **helpers/**: View and controller helper functions (`wheels g helper`)
- **lib/**: More complex utility classes and integration components

## Common Library Patterns

### 1. Utility Classes
For complex operations that don't belong in models or controllers:

```cfm
// /app/lib/StringUtility.cfc
component {
    
    /**
     * Advanced string manipulation utilities
     */
    
    public string function generateSlug(required string text, numeric maxLength = 50) {
        local.slug = lcase(trim(arguments.text));
        
        // Remove accents and special characters
        local.slug = removeAccents(local.slug);
        
        // Replace spaces and special characters with hyphens
        local.slug = reReplace(local.slug, "[^a-z0-9\s]", "", "all");
        local.slug = reReplace(local.slug, "\s+", "-", "all");
        
        // Remove double hyphens
        local.slug = reReplace(local.slug, "-+", "-", "all");
        
        // Trim hyphens from ends
        local.slug = reReplace(local.slug, "^-|-$", "", "all");
        
        // Truncate to max length
        if (len(local.slug) > arguments.maxLength) {
            local.slug = left(local.slug, arguments.maxLength);
            // Avoid cutting in the middle of a word
            if (right(local.slug, 1) != "-") {
                local.lastHyphen = find("-", reverse(local.slug));
                if (local.lastHyphen > 0 && local.lastHyphen < 10) {
                    local.slug = left(local.slug, len(local.slug) - local.lastHyphen + 1);
                }
            }
        }
        
        return local.slug;
    }
    
    public string function extractExcerpt(required string text, numeric length = 150, string suffix = "...") {
        if (len(arguments.text) <= arguments.length) {
            return arguments.text;
        }
        
        // Strip HTML tags
        local.cleanText = reReplace(arguments.text, "<[^>]*>", "", "all");
        
        // Truncate to approximate length
        local.excerpt = left(local.cleanText, arguments.length - len(arguments.suffix));
        
        // Find last complete word
        local.lastSpace = find(" ", reverse(local.excerpt));
        if (local.lastSpace > 0 && local.lastSpace < 20) {
            local.excerpt = left(local.excerpt, len(local.excerpt) - local.lastSpace + 1);
        }
        
        return trim(local.excerpt) & arguments.suffix;
    }
    
    public string function sanitizeFilename(required string filename) {
        // Remove dangerous characters from filenames
        local.safe = reReplace(arguments.filename, "[^a-zA-Z0-9._-]", "_", "all");
        local.safe = reReplace(local.safe, "_{2,}", "_", "all");
        return local.safe;
    }
    
    private string function removeAccents(required string text) {
        local.result = arguments.text;
        local.accents = {
            "à,á,â,ã,ä,å": "a",
            "è,é,ê,ë": "e",
            "ì,í,î,ï": "i",
            "ò,ó,ô,õ,ö": "o",
            "ù,ú,û,ü": "u",
            "ç": "c",
            "ñ": "n"
        };
        
        for (local.accented in local.accents) {
            for (local.char in listToArray(local.accented)) {
                local.result = replace(local.result, local.char, local.accents[local.accented], "all");
            }
        }
        
        return local.result;
    }
}
```

### 2. Third-Party API Integrations
For external service integrations:

```cfm
// /app/lib/PaymentGateway.cfc
component {
    
    property name="apiKey";
    property name="apiUrl";
    property name="environment";
    
    public function init(required string apiKey, string environment = "sandbox") {
        variables.apiKey = arguments.apiKey;
        variables.environment = arguments.environment;
        
        variables.apiUrl = (arguments.environment == "production") ? 
            "https://api.paymentgateway.com/v1" : 
            "https://sandbox-api.paymentgateway.com/v1";
            
        return this;
    }
    
    public struct function processPayment(required struct paymentData) {
        try {
            // Validate payment data
            validatePaymentData(arguments.paymentData);
            
            // Prepare API request
            local.requestData = {
                "amount": arguments.paymentData.amount,
                "currency": arguments.paymentData.currency ?: "USD",
                "payment_method": {
                    "type": "card",
                    "card": arguments.paymentData.card
                },
                "metadata": arguments.paymentData.metadata ?: {}
            };
            
            // Make API call
            local.response = makeApiRequest(
                endpoint = "/charges",
                method = "POST", 
                data = local.requestData
            );
            
            return {
                "success": true,
                "transactionId": local.response.id,
                "status": local.response.status,
                "amount": local.response.amount,
                "response": local.response
            };
            
        } catch (any e) {
            return {
                "success": false,
                "error": e.message,
                "detail": e.detail,
                "type": e.type
            };
        }
    }
    
    public struct function refundPayment(required string transactionId, numeric amount = 0) {
        try {
            local.requestData = {"amount": arguments.amount};
            
            local.response = makeApiRequest(
                endpoint = "/charges/#arguments.transactionId#/refunds",
                method = "POST",
                data = local.requestData
            );
            
            return {
                "success": true,
                "refundId": local.response.id,
                "amount": local.response.amount,
                "status": local.response.status
            };
            
        } catch (any e) {
            return {
                "success": false,
                "error": e.message,
                "detail": e.detail
            };
        }
    }
    
    private void function validatePaymentData(required struct data) {
        local.required = ["amount", "card"];
        
        for (local.field in local.required) {
            if (!structKeyExists(arguments.data, local.field)) {
                throw(type="ValidationException", message="Missing required field: #local.field#");
            }
        }
        
        if (!isNumeric(arguments.data.amount) || arguments.data.amount <= 0) {
            throw(type="ValidationException", message="Amount must be a positive number");
        }
        
        if (!structKeyExists(arguments.data.card, "number") || 
            !structKeyExists(arguments.data.card, "exp_month") ||
            !structKeyExists(arguments.data.card, "exp_year") ||
            !structKeyExists(arguments.data.card, "cvc")) {
            throw(type="ValidationException", message="Invalid card data");
        }
    }
    
    private struct function makeApiRequest(required string endpoint, required string method, struct data = {}) {
        local.httpService = new http();
        local.httpService.setMethod(arguments.method);
        local.httpService.setUrl(variables.apiUrl & arguments.endpoint);
        local.httpService.addParam(type="header", name="Authorization", value="Bearer #variables.apiKey#");
        local.httpService.addParam(type="header", name="Content-Type", value="application/json");
        
        if (structCount(arguments.data)) {
            local.httpService.addParam(type="body", value=serializeJSON(arguments.data));
        }
        
        local.result = local.httpService.send().getPrefix();
        
        if (local.result.statusCode != "200 OK") {
            local.error = deserializeJSON(local.result.fileContent);
            throw(
                type="ApiException",
                message="Payment gateway error: #local.error.message#",
                detail="Status: #local.result.statusCode#"
            );
        }
        
        return deserializeJSON(local.result.fileContent);
    }
}
```

### 3. Data Processing Classes
For complex data transformations:

```cfm
// /app/lib/CsvProcessor.cfc
component {
    
    public struct function parseCsvFile(required string filePath, boolean hasHeaders = true) {
        if (!fileExists(arguments.filePath)) {
            throw(type="FileNotFoundException", message="CSV file not found: #arguments.filePath#");
        }
        
        local.result = {
            "success": false,
            "headers": [],
            "rows": [],
            "errors": [],
            "totalRows": 0,
            "validRows": 0
        };
        
        try {
            local.fileContent = fileRead(arguments.filePath);
            local.lines = listToArray(local.fileContent, chr(10));
            local.startRow = arguments.hasHeaders ? 2 : 1;
            
            // Process headers
            if (arguments.hasHeaders && arrayLen(local.lines) > 0) {
                local.result.headers = parseCsvRow(local.lines[1]);
            }
            
            // Process data rows
            for (local.i = local.startRow; local.i <= arrayLen(local.lines); local.i++) {
                try {
                    if (len(trim(local.lines[local.i]))) {
                        local.row = parseCsvRow(local.lines[local.i]);
                        arrayAppend(local.result.rows, local.row);
                        local.result.validRows++;
                    }
                } catch (any e) {
                    arrayAppend(local.result.errors, {
                        "line": local.i,
                        "error": e.message,
                        "content": local.lines[local.i]
                    });
                }
            }
            
            local.result.totalRows = arrayLen(local.lines) - (arguments.hasHeaders ? 1 : 0);
            local.result.success = true;
            
        } catch (any e) {
            local.result.errors = [{
                "line": 0,
                "error": "File processing error: #e.message#",
                "content": ""
            }];
        }
        
        return local.result;
    }
    
    public void function exportToCsv(required array data, required string filePath, array headers = []) {
        local.csvContent = "";
        
        // Add headers if provided
        if (arrayLen(arguments.headers)) {
            local.csvContent = generateCsvRow(arguments.headers) & chr(10);
        }
        
        // Add data rows
        for (local.row in arguments.data) {
            if (isStruct(local.row)) {
                // Convert struct to array maintaining header order
                local.rowArray = [];
                if (arrayLen(arguments.headers)) {
                    for (local.header in arguments.headers) {
                        arrayAppend(local.rowArray, local.row[local.header] ?: "");
                    }
                } else {
                    for (local.key in structKeyArray(local.row)) {
                        arrayAppend(local.rowArray, local.row[local.key]);
                    }
                }
                local.csvContent &= generateCsvRow(local.rowArray) & chr(10);
            } else if (isArray(local.row)) {
                local.csvContent &= generateCsvRow(local.row) & chr(10);
            }
        }
        
        // Write to file
        fileWrite(arguments.filePath, local.csvContent);
    }
    
    private array function parseCsvRow(required string csvRow) {
        local.result = [];
        local.inQuotes = false;
        local.currentField = "";
        local.chars = listToArray(arguments.csvRow, "");
        
        for (local.i = 1; local.i <= arrayLen(local.chars); local.i++) {
            local.char = local.chars[local.i];
            
            if (local.char == '"') {
                // Handle escaped quotes
                if (local.inQuotes && local.i < arrayLen(local.chars) && local.chars[local.i + 1] == '"') {
                    local.currentField &= '"';
                    local.i++; // Skip next quote
                } else {
                    local.inQuotes = !local.inQuotes;
                }
            } else if (local.char == ',' && !local.inQuotes) {
                // Field delimiter
                arrayAppend(local.result, trim(local.currentField));
                local.currentField = "";
            } else {
                local.currentField &= local.char;
            }
        }
        
        // Add the last field
        arrayAppend(local.result, trim(local.currentField));
        
        return local.result;
    }
    
    private string function generateCsvRow(required array rowData) {
        local.result = [];
        
        for (local.field in arguments.rowData) {
            local.fieldValue = toString(local.field);
            
            // Escape quotes and wrap in quotes if necessary
            if (find(',', local.fieldValue) || find('"', local.fieldValue) || find(chr(10), local.fieldValue)) {
                local.fieldValue = replace(local.fieldValue, '"', '""', 'all');
                local.fieldValue = '"#local.fieldValue#"';
            }
            
            arrayAppend(local.result, local.fieldValue);
        }
        
        return arrayToList(local.result);
    }
}
```

### 4. Email Template Manager
For advanced email functionality:

```cfm
// /app/lib/EmailTemplateManager.cfc
component {
    
    property name="templatePath";
    property name="defaultLayout";
    
    public function init(string templatePath = "/app/views/emails/", string defaultLayout = "layout") {
        variables.templatePath = arguments.templatePath;
        variables.defaultLayout = arguments.defaultLayout;
        return this;
    }
    
    public struct function renderTemplate(required string template, struct data = {}, string layout = "") {
        try {
            local.layout = len(arguments.layout) ? arguments.layout : variables.defaultLayout;
            local.templateFile = variables.templatePath & arguments.template & ".cfm";
            local.layoutFile = variables.templatePath & "layouts/" & local.layout & ".cfm";
            
            // Check if template exists
            if (!fileExists(expandPath(local.templateFile))) {
                throw(type="TemplateNotFoundException", message="Email template not found: #local.templateFile#");
            }
            
            // Render template content
            savecontent variable="local.content" {
                include local.templateFile;
            }
            
            // Apply layout if it exists
            if (fileExists(expandPath(local.layoutFile))) {
                // Make content available to layout
                variables.emailContent = local.content;
                
                savecontent variable="local.finalContent" {
                    include local.layoutFile;
                }
                
                local.content = local.finalContent;
            }
            
            return {
                "success": true,
                "content": local.content,
                "template": arguments.template,
                "layout": local.layout
            };
            
        } catch (any e) {
            return {
                "success": false,
                "error": e.message,
                "detail": e.detail,
                "template": arguments.template
            };
        }
    }
    
    public boolean function sendTemplatedEmail(
        required string to,
        required string subject,
        required string template,
        struct data = {},
        string from = "",
        string layout = "",
        string replyTo = ""
    ) {
        try {
            // Render the email template
            local.rendered = renderTemplate(
                template = arguments.template,
                data = arguments.data,
                layout = arguments.layout
            );
            
            if (!local.rendered.success) {
                throw(type="TemplateRenderException", message=local.rendered.error);
            }
            
            // Send the email
            mail(
                to = arguments.to,
                from = len(arguments.from) ? arguments.from : get("emailSettings.defaultFrom"),
                subject = arguments.subject,
                body = local.rendered.content,
                type = "html",
                replyTo = arguments.replyTo
            );
            
            return true;
            
        } catch (any e) {
            // Log error
            writeLog(
                text = "Email template send failed: #e.message# (Template: #arguments.template#)",
                type = "error",
                file = "email"
            );
            
            return false;
        }
    }
    
    public array function getAvailableTemplates() {
        local.templates = [];
        
        try {
            local.templateDir = expandPath(variables.templatePath);
            
            if (directoryExists(local.templateDir)) {
                local.files = directoryList(
                    path = local.templateDir,
                    filter = "*.cfm",
                    listInfo = "name",
                    recurse = false
                );
                
                for (local.file in local.files) {
                    local.templateName = replaceNoCase(local.file, ".cfm", "");
                    if (local.templateName != "layout") {
                        arrayAppend(local.templates, local.templateName);
                    }
                }
            }
        } catch (any e) {
            // Return empty array on error
        }
        
        arraySort(local.templates, "textnocase");
        return local.templates;
    }
}
```

### 5. Caching Utilities
For advanced caching scenarios:

```cfm
// /app/lib/CacheManager.cfc
component {
    
    property name="defaultTimeout";
    property name="cacheRegion";
    
    public function init(numeric defaultTimeout = 3600, string cacheRegion = "application") {
        variables.defaultTimeout = arguments.defaultTimeout;
        variables.cacheRegion = arguments.cacheRegion;
        return this;
    }
    
    public any function get(required string key, any defaultValue = "", string region = "") {
        local.region = len(arguments.region) ? arguments.region : variables.cacheRegion;
        
        try {
            if (cacheKeyExists(arguments.key, local.region)) {
                return cacheGet(arguments.key, local.region);
            }
        } catch (any e) {
            // Cache error - return default
        }
        
        return arguments.defaultValue;
    }
    
    public void function set(
        required string key,
        required any value,
        numeric timeout = 0,
        string region = ""
    ) {
        local.timeout = arguments.timeout > 0 ? arguments.timeout : variables.defaultTimeout;
        local.region = len(arguments.region) ? arguments.region : variables.cacheRegion;
        
        try {
            cachePut(
                id = arguments.key,
                value = arguments.value,
                timespan = createTimeSpan(0, 0, 0, local.timeout),
                region = local.region
            );
        } catch (any e) {
            // Log cache error but don't throw
            writeLog(
                text = "Cache set failed for key '#arguments.key#': #e.message#",
                type = "warning",
                file = "cache"
            );
        }
    }
    
    public any function remember(
        required string key,
        required any callback,
        numeric timeout = 0,
        string region = ""
    ) {
        // Check if value exists in cache
        local.cached = get(arguments.key, "CACHE_MISS", arguments.region);
        
        if (local.cached != "CACHE_MISS") {
            return local.cached;
        }
        
        // Value not in cache - execute callback
        try {
            if (isClosure(arguments.callback)) {
                local.value = arguments.callback();
            } else if (isCustomFunction(arguments.callback)) {
                local.value = arguments.callback();
            } else {
                local.value = arguments.callback;
            }
            
            // Store in cache
            set(arguments.key, local.value, arguments.timeout, arguments.region);
            
            return local.value;
            
        } catch (any e) {
            // Log error and return null/empty
            writeLog(
                text = "Cache callback failed for key '#arguments.key#': #e.message#",
                type = "error",
                file = "cache"
            );
            
            return "";
        }
    }
    
    public boolean function exists(required string key, string region = "") {
        local.region = len(arguments.region) ? arguments.region : variables.cacheRegion;
        
        try {
            return cacheKeyExists(arguments.key, local.region);
        } catch (any e) {
            return false;
        }
    }
    
    public void function delete(required string key, string region = "") {
        local.region = len(arguments.region) ? arguments.region : variables.cacheRegion;
        
        try {
            cacheRemove(arguments.key, local.region);
        } catch (any e) {
            // Ignore cache delete errors
        }
    }
    
    public void function deletePattern(required string pattern, string region = "") {
        local.region = len(arguments.region) ? arguments.region : variables.cacheRegion;
        
        try {
            local.keys = cacheGetAllIds(local.region);
            
            for (local.key in local.keys) {
                if (reFindNoCase(arguments.pattern, local.key)) {
                    cacheRemove(local.key, local.region);
                }
            }
        } catch (any e) {
            // Log error but continue
            writeLog(
                text = "Cache pattern delete failed for pattern '#arguments.pattern#': #e.message#",
                type = "warning", 
                file = "cache"
            );
        }
    }
    
    public struct function getStats(string region = "") {
        local.region = len(arguments.region) ? arguments.region : variables.cacheRegion;
        
        try {
            local.keys = cacheGetAllIds(local.region);
            local.stats = {
                "region": local.region,
                "keyCount": arrayLen(local.keys),
                "keys": local.keys
            };
            
            return local.stats;
            
        } catch (any e) {
            return {
                "region": local.region,
                "keyCount": 0,
                "keys": [],
                "error": e.message
            };
        }
    }
}
```

### 6. File Upload Handler
For advanced file upload processing:

```cfm
// /app/lib/FileUploadHandler.cfc
component {
    
    property name="uploadPath";
    property name="allowedExtensions";
    property name="maxFileSize";
    
    public function init(
        string uploadPath = "/uploads/",
        string allowedExtensions = "jpg,jpeg,png,gif,pdf,doc,docx",
        numeric maxFileSize = 10485760  // 10MB
    ) {
        variables.uploadPath = arguments.uploadPath;
        variables.allowedExtensions = lcase(arguments.allowedExtensions);
        variables.maxFileSize = arguments.maxFileSize;
        return this;
    }
    
    public struct function handleUpload(required string fieldName, string subDirectory = "") {
        local.result = {
            "success": false,
            "filename": "",
            "originalFilename": "",
            "filePath": "",
            "fileSize": 0,
            "fileType": "",
            "errors": []
        };
        
        try {
            // Check if file was uploaded
            if (!structKeyExists(form, arguments.fieldName) || !len(form[arguments.fieldName])) {
                arrayAppend(local.result.errors, "No file uploaded");
                return local.result;
            }
            
            // Get file info
            local.fileInfo = getFileInfo(arguments.fieldName);
            
            // Validate file
            local.validation = validateUpload(local.fileInfo);
            if (!local.validation.valid) {
                local.result.errors = local.validation.errors;
                return local.result;
            }
            
            // Create upload directory
            local.targetDir = expandPath(variables.uploadPath);
            if (len(arguments.subDirectory)) {
                local.targetDir &= arguments.subDirectory & "/";
            }
            
            if (!directoryExists(local.targetDir)) {
                directoryCreate(local.targetDir);
            }
            
            // Generate unique filename
            local.fileExtension = listLast(local.fileInfo.clientFile, ".");
            local.safeName = generateSafeFilename(local.fileInfo.clientFile);
            local.uniqueName = local.safeName & "_" & dateFormat(now(), "yyyymmdd") & 
                              timeFormat(now(), "hhmmss") & "." & local.fileExtension;
            
            local.targetPath = local.targetDir & local.uniqueName;
            
            // Move uploaded file
            fileMove(local.fileInfo.serverDirectory & "/" & local.fileInfo.serverFile, local.targetPath);
            
            // Process image if it's an image file
            if (isImageFile(local.fileExtension)) {
                processImageFile(local.targetPath);
            }
            
            // Update result
            local.result.success = true;
            local.result.filename = local.uniqueName;
            local.result.originalFilename = local.fileInfo.clientFile;
            local.result.filePath = variables.uploadPath & (len(arguments.subDirectory) ? arguments.subDirectory & "/" : "") & local.uniqueName;
            local.result.fileSize = local.fileInfo.fileSize;
            local.result.fileType = local.fileExtension;
            
        } catch (any e) {
            arrayAppend(local.result.errors, "Upload failed: #e.message#");
        }
        
        return local.result;
    }
    
    public boolean function deleteFile(required string filePath) {
        try {
            local.fullPath = expandPath(arguments.filePath);
            
            if (fileExists(local.fullPath)) {
                fileDelete(local.fullPath);
                
                // Delete thumbnails if they exist
                deleteThumbnails(local.fullPath);
                
                return true;
            }
            
        } catch (any e) {
            writeLog(
                text = "File deletion failed: #e.message# (File: #arguments.filePath#)",
                type = "error",
                file = "fileupload"
            );
        }
        
        return false;
    }
    
    private struct function getFileInfo(required string fieldName) {
        local.tempDir = getTempDirectory();
        local.uploadResult = fileUpload(local.tempDir, arguments.fieldName, "*", "makeUnique");
        
        return {
            "clientFile": uploadResult.clientFile,
            "serverFile": uploadResult.serverFile,
            "serverDirectory": uploadResult.serverDirectory,
            "fileSize": uploadResult.fileSize,
            "contentType": uploadResult.contentType,
            "contentSubType": uploadResult.contentSubType
        };
    }
    
    private struct function validateUpload(required struct fileInfo) {
        local.result = {"valid": true, "errors": []};
        
        // Check file size
        if (arguments.fileInfo.fileSize > variables.maxFileSize) {
            arrayAppend(local.result.errors, "File too large. Maximum size: #formatFileSize(variables.maxFileSize)#");
            local.result.valid = false;
        }
        
        // Check file extension
        local.fileExtension = lcase(listLast(arguments.fileInfo.clientFile, "."));
        if (!listFindNoCase(variables.allowedExtensions, local.fileExtension)) {
            arrayAppend(local.result.errors, "File type not allowed. Allowed types: #variables.allowedExtensions#");
            local.result.valid = false;
        }
        
        // Check for dangerous filenames
        if (reFindNoCase("\.php|\.jsp|\.asp|\.cfm", arguments.fileInfo.clientFile)) {
            arrayAppend(local.result.errors, "Potentially dangerous file type");
            local.result.valid = false;
        }
        
        return local.result;
    }
    
    private string function generateSafeFilename(required string filename) {
        local.name = replaceNoCase(arguments.filename, "." & listLast(arguments.filename, "."), "");
        local.safe = reReplace(local.name, "[^a-zA-Z0-9._-]", "_", "all");
        local.safe = reReplace(local.safe, "_{2,}", "_", "all");
        local.safe = reReplace(local.safe, "^_|_$", "", "all");
        
        if (!len(local.safe)) {
            local.safe = "file";
        }
        
        return local.safe;
    }
    
    private boolean function isImageFile(required string extension) {
        return listFindNoCase("jpg,jpeg,png,gif,bmp,webp", arguments.extension);
    }
    
    private void function processImageFile(required string imagePath) {
        try {
            // Create thumbnails
            createThumbnail(arguments.imagePath, 150, 150, "_thumb");
            createThumbnail(arguments.imagePath, 300, 300, "_medium");
            
            // Optimize original if it's too large
            optimizeImage(arguments.imagePath);
            
        } catch (any e) {
            // Log but don't fail the upload
            writeLog(
                text = "Image processing failed: #e.message# (Image: #arguments.imagePath#)",
                type = "warning",
                file = "imageprocessing"
            );
        }
    }
    
    private void function createThumbnail(
        required string imagePath,
        required numeric width,
        required numeric height,
        required string suffix
    ) {
        local.image = imageRead(arguments.imagePath);
        
        // Resize maintaining aspect ratio
        imageScaleToFit(local.image, arguments.width, arguments.height);
        
        // Generate thumbnail path
        local.dir = getDirectoryFromPath(arguments.imagePath);
        local.filename = getFileFromPath(arguments.imagePath);
        local.name = listFirst(local.filename, ".");
        local.ext = listLast(local.filename, ".");
        local.thumbPath = local.dir & local.name & arguments.suffix & "." & local.ext;
        
        // Save thumbnail
        imageWrite(local.image, local.thumbPath, 0.8);
    }
}
```

## Usage Examples

### In Controllers
```cfm
component extends="Controller" {

    function uploadDocument() {
        // Use custom file upload handler
        local.uploader = createObject("component", "lib.FileUploadHandler").init(
            uploadPath = "/uploads/documents/",
            allowedExtensions = "pdf,doc,docx,txt",
            maxFileSize = 52428800  // 50MB
        );
        
        local.result = local.uploader.handleUpload("document", params.userId);
        
        if (local.result.success) {
            // Save file info to database
            local.document = model("Document").create(
                userId = params.userId,
                filename = local.result.filename,
                originalName = local.result.originalFilename,
                filePath = local.result.filePath,
                fileSize = local.result.fileSize,
                fileType = local.result.fileType
            );
            
            renderJSON({success: true, documentId: local.document.id});
        } else {
            renderJSON({success: false, errors: local.result.errors});
        }
    }
    
    function processPayment() {
        // Use payment gateway integration
        local.gateway = createObject("component", "lib.PaymentGateway").init(
            apiKey = get("paymentGateway.apiKey"),
            environment = get("paymentGateway.environment")
        );
        
        local.result = local.gateway.processPayment({
            amount = params.amount,
            currency = params.currency,
            card = {
                number = params.cardNumber,
                exp_month = params.expMonth,
                exp_year = params.expYear,
                cvc = params.cvc
            }
        });
        
        if (local.result.success) {
            // Update order with payment info
            local.order = model("Order").findByKey(params.orderId);
            local.order.update(
                status = "paid",
                transactionId = local.result.transactionId,
                paidAt = now()
            );
        }
        
        renderJSON(local.result);
    }
}
```

### In Models
```cfm
component extends="Model" {

    function config() {
        property(name="slug", type="string");
        
        beforeSave("generateSlug");
    }
    
    private void function generateSlug() {
        if (hasChanged("title")) {
            local.stringUtil = createObject("component", "lib.StringUtility");
            this.slug = local.stringUtil.generateSlug(this.title);
            
            // Ensure uniqueness
            local.counter = 1;
            local.originalSlug = this.slug;
            
            while (model("Article").findOne(where = "slug = '#this.slug#' AND id != #this.id ?: 0#")) {
                this.slug = local.originalSlug & "-" & local.counter;
                local.counter++;
            }
        }
    }
    
    function getExcerpt(numeric length = 150) {
        local.stringUtil = createObject("component", "lib.StringUtility");
        return local.stringUtil.extractExcerpt(this.content, arguments.length);
    }
}
```

### In Views
```cfm
<cfscript>
// Use caching for expensive operations
local.cacheManager = createObject("component", "lib.CacheManager");
local.stats = local.cacheManager.remember("dashboard_stats_#session.userId#", function() {
    return model("User").getDashboardStats(session.userId);
}, 300); // Cache for 5 minutes
</cfscript>

<cfoutput>
    <div class="dashboard-stats">
        <div class="stat">
            <span class="value">#local.stats.totalOrders#</span>
            <span class="label">Total Orders</span>
        </div>
        <div class="stat">
            <span class="value">#dollarFormat(local.stats.totalRevenue)#</span>
            <span class="label">Total Revenue</span>
        </div>
    </div>
</cfoutput>
```

### In Background Jobs
```cfm
// /app/jobs/SendNewsletterJob.cfc
component extends="wheels.Job" {

    public void function perform(struct data = {}) {
        // Use email template manager
        local.emailManager = createObject("component", "lib.EmailTemplateManager");
        
        // Use CSV processor for subscriber list
        local.csvProcessor = createObject("component", "lib.CsvProcessor");
        local.subscribers = local.csvProcessor.parseCsvFile("/uploads/subscribers.csv");
        
        for (local.subscriber in local.subscribers.rows) {
            try {
                local.emailManager.sendTemplatedEmail(
                    to = local.subscriber[2], // Email column
                    subject = "Monthly Newsletter",
                    template = "newsletter",
                    data = {
                        name = local.subscriber[1], // Name column
                        month = dateFormat(now(), "mmmm yyyy")
                    }
                );
                
            } catch (any e) {
                logError("Failed to send newsletter to #local.subscriber[2]#: #e.message#");
            }
        }
    }
}
```

## Testing Library Components

```cfm
// /tests/lib/StringUtilityTest.cfc
component extends="wheels.Test" {

    function setup() {
        variables.stringUtil = createObject("component", "lib.StringUtility");
    }

    function test_generateSlug_basic() {
        local.result = variables.stringUtil.generateSlug("Hello World Test");
        assert(local.result == "hello-world-test", "Should generate basic slug");
    }
    
    function test_generateSlug_with_special_chars() {
        local.result = variables.stringUtil.generateSlug("Hello, World! This & That");
        assert(local.result == "hello-world-this-that", "Should remove special characters");
    }
    
    function test_generateSlug_max_length() {
        local.longText = "This is a very long title that should be truncated to fit within the maximum length specified";
        local.result = variables.stringUtil.generateSlug(local.longText, 30);
        assert(len(local.result) <= 30, "Should respect max length");
        assert(right(local.result, 1) != "-", "Should not end with hyphen");
    }
    
    function test_extractExcerpt() {
        local.html = "<p>This is a <strong>test</strong> paragraph with HTML.</p><p>Second paragraph.</p>";
        local.result = variables.stringUtil.extractExcerpt(local.html, 30);
        
        assert(!find("<", local.result), "Should strip HTML tags");
        assert(find("...", local.result), "Should add suffix");
    }
    
    function test_sanitizeFilename() {
        local.result = variables.stringUtil.sanitizeFilename("test file!@#.pdf");
        assert(local.result == "test_file___.pdf", "Should sanitize filename");
    }
}
```

## Best Practices

### 1. Organize by Purpose
```
/app/lib/
├── integrations/           # Third-party API integrations
│   ├── PaymentGateway.cfc
│   ├── EmailProvider.cfc
│   └── SocialMedia.cfc
├── utilities/             # General utility classes
│   ├── StringUtility.cfc
│   ├── DateUtility.cfc
│   └── FileUtility.cfc
├── processors/           # Data processing classes
│   ├── CsvProcessor.cfc
│   ├── ImageProcessor.cfc
│   └── PdfGenerator.cfc
├── managers/            # Complex business logic managers
│   ├── EmailTemplateManager.cfc
│   ├── CacheManager.cfc
│   └── WorkflowManager.cfc
└── validators/          # Custom validation classes
    ├── CreditCardValidator.cfc
    └── AddressValidator.cfc
```

### 2. Consistent Naming Conventions
- Use descriptive names that indicate purpose
- End utility classes with "Utility" or "Utils"
- End integration classes with "Gateway", "Client", or "Integration"
- End managers with "Manager"
- End processors with "Processor"

### 3. Constructor Patterns
```cfm
component {
    // Always provide init() method for configuration
    public function init(required string apiKey, string environment = "production") {
        variables.apiKey = arguments.apiKey;
        variables.environment = arguments.environment;
        
        // Initialize other properties
        setupConfiguration();
        
        return this;
    }
    
    private void function setupConfiguration() {
        // Configuration logic
    }
}
```

### 4. Error Handling
```cfm
public struct function processData(required any data) {
    try {
        // Processing logic
        local.result = performProcessing(arguments.data);
        
        return {
            "success": true,
            "data": local.result
        };
        
    } catch (any e) {
        // Log error
        logError(e);
        
        return {
            "success": false,
            "error": e.message,
            "detail": e.detail
        };
    }
}
```

### 5. Environment-Aware Configuration
```cfm
public function init() {
    // Load configuration based on environment
    if (get("environment") == "production") {
        variables.apiUrl = "https://api.production.com";
        variables.debug = false;
    } else {
        variables.apiUrl = "https://api.sandbox.com";
        variables.debug = true;
    }
    
    return this;
}
```

## Important Notes

- **No Auto-loading**: Unlike global functions, lib components must be explicitly instantiated
- **Stateless Design**: Design components to be stateless when possible for better testability
- **Dependency Injection**: Consider using dependency injection for complex dependencies
- **Testing**: Always include comprehensive unit tests for lib components
- **Documentation**: Include detailed JavaDoc-style comments for all public methods
- **Error Handling**: Always include proper error handling and logging
- **Performance**: Consider caching expensive operations
- **Security**: Validate all inputs and sanitize outputs appropriately

The lib/ folder provides a flexible space for organizing custom code that extends your Wheels application beyond the standard MVC pattern, enabling clean separation of concerns and reusable components.