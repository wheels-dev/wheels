# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with the public directory in a Wheels application.

## Overview

The `/public` directory serves as the document root for your Wheels application, containing static assets (CSS, JavaScript, images), system files, and the framework bootstrap. It's the only directory directly accessible by web browsers, providing security by keeping application code outside the web root. This directory contains both user assets and essential framework files that enable Wheels to function properly.

## Directory Structure

### Standard Public Directory Layout
```
public/
├── index.cfm                 (Framework bootstrap - DO NOT MODIFY)
├── Application.cfc           (Framework bootstrap - DO NOT MODIFY)
├── urlrewrite.xml           (URL rewriting configuration)
├── favicon.ico              (Site favicon)
├── robots.txt               (Search engine directives)  
├── sitemap.xml              (Search engine sitemap)
├── files/                   (User file uploads/downloads)
├── images/                  (Image assets)
├── javascripts/             (JavaScript files)
├── stylesheets/             (CSS files)
└── miscellaneous/           (Non-framework code)
    └── Application.cfc      (Empty Application.cfc)
```

### Asset Directories

**`stylesheets/`** - CSS files and stylesheets
- Conventional location for CSS assets
- Accessed via `styleSheetLinkTag()` helper
- Supports nested directories for organization

**`javascripts/`** - JavaScript files and libraries  
- Conventional location for JavaScript assets
- Accessed via `javaScriptIncludeTag()` helper
- Can contain libraries, frameworks, and custom code

**`images/`** - Image assets and graphics
- Conventional location for images
- Accessed via `imageTag()` helper
- Wheels automatically detects image dimensions and caches metadata

**`files/`** - File storage and downloads
- General file storage accessible via web
- Used with `sendFile()` function for file delivery
- Suitable for user uploads and downloadable content

**`miscellaneous/`** - Non-framework CFML code
- Contains empty `Application.cfc` to bypass Wheels
- Used for standalone CFML code that must run outside framework
- Ideal for Flash AMF bindings, AJAX proxies, or legacy integrations

## Framework Bootstrap Files

### Core System Files (DO NOT MODIFY)

**`index.cfm`** - Application entry point:
```cfm
<cfsilent>
<!---
    Uses the Dispatch object, which has been created on app start, to render content.
--->
</cfsilent>
<cfoutput>#application.wheels.dispatch.$request()#</cfoutput>
```

**`Application.cfc`** - Framework initialization:
- Sets up application mappings and paths
- Loads Wheels framework and dependencies  
- Handles environment variables and configuration
- Manages Java library loading for plugins
- Provides application lifecycle event handling

**Key Application.cfc Features:**
- **Path Mapping**: Maps `/app`, `/vendor`, `/wheels`, `/config`, `/plugins`
- **Environment Loading**: Loads `.env` files with variable interpolation
- **Plugin Integration**: Automatically maps Java libraries from plugins
- **Session Management**: Enables sessions by default for Flash scope
- **Request Lifecycle**: Handles all ColdFusion application events
- **Reload Mechanism**: Supports application reloading via URL parameters

### URL Rewriting Configuration

**`urlrewrite.xml`** - Tuckey URL Rewrite configuration:
```xml
<urlrewrite>
  <rule enabled="true">
    <name>CFWheels pretty URLs</name>
    <condition type="request-uri" operator="notequal">^/(cf_script|flex2gateway|jrunscripts|CFIDE/administrator|lucee/admin|cfformgateway|cffileservlet|lucee|files|images|javascripts|miscellaneous|stylesheets|wheels/public/assets|robots.txt|favicon.ico|sitemap.xml|index.cfm)</condition>
    <from>^/(.*)$</from>
    <to type="passthrough">/index.cfm/$1</to>
  </rule>
  
  <!-- Convert dot notation to format parameter -->
  <rule enabled="true">
    <name>Convert dot to format parameter</name>
    <from>^/(.*)\\.(\\w+)$</from>
    <to>/$1?format=$2</to>
  </rule>
</urlrewrite>
```

**Configuration Notes:**
- Used with Tomcat/CommandBox for URL rewriting
- Excludes static asset directories from rewriting
- Converts `/users/123.json` to `/users/123?format=json`
- Can be safely deleted if not using Tuckey/CommandBox

## Asset Management

### CSS Stylesheets

**Conventional Structure:**
```
stylesheets/
├── application.css          (Main application styles)
├── admin.css               (Admin section styles)
├── print.css               (Print styles)
├── mobile.css              (Mobile styles)
├── vendor/                 (Third-party CSS)
│   ├── bootstrap.min.css
│   ├── fontawesome.min.css
│   └── daterangepicker.css
└── components/             (Component-specific styles)
    ├── forms.css
    ├── navigation.css
    └── tables.css
```

**Usage in Views:**
```cfm
<!--- Single stylesheet --->
#styleSheetLinkTag("application")#

<!--- Multiple stylesheets --->
#styleSheetLinkTag("application,admin,print")#

<!--- With media type --->
#styleSheetLinkTag(source="print", media="print")#

<!--- From CDN --->
#styleSheetLinkTag("https://cdn.example.com/styles.css")#

<!--- Nested directory --->
#styleSheetLinkTag("vendor/bootstrap.min")#
```

### JavaScript Files

**Conventional Structure:**
```
javascripts/
├── application.js          (Main application JavaScript)
├── admin.js               (Admin functionality)
├── vendor/                (Third-party libraries)
│   ├── jquery.min.js
│   ├── bootstrap.min.js
│   ├── moment.min.js
│   └── daterangepicker.js
├── components/            (Component-specific JS)
│   ├── forms.js
│   ├── navigation.js
│   └── datatables.js
└── pages/                 (Page-specific JS)
    ├── users.js
    └── products.js
```

**Usage in Views:**
```cfm
<!--- Single JavaScript file --->
#javaScriptIncludeTag("application")#

<!--- Multiple files in order --->
#javaScriptIncludeTag("vendor/jquery.min,vendor/bootstrap.min,application")#

<!--- From CDN --->
#javaScriptIncludeTag("https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js")#

<!--- Nested directory --->
#javaScriptIncludeTag("vendor/moment.min")#
```

### Images

**Conventional Structure:**
```
images/
├── logo.png               (Site logo)
├── favicon.ico            (Browser icon)
├── backgrounds/           (Background images)
│   ├── hero.jpg
│   └── pattern.png
├── icons/                 (Icon images)
│   ├── user.png
│   ├── admin.png
│   └── settings.png
├── products/              (Product images)
│   ├── product-001.jpg
│   └── product-002.jpg
└── uploads/               (User uploaded images)
    └── avatars/
```

**Usage in Views:**
```cfm
<!--- Simple image --->
#imageTag("logo.png")#

<!--- With custom alt text --->
#imageTag(source="logo.png", alt="Company Logo")#

<!--- With dimensions and CSS class --->
#imageTag(source="hero.jpg", width="800", height="400", class="img-responsive")#

<!--- Nested directory --->
#imageTag("backgrounds/hero.jpg")#
```

**Image Helper Features:**
- Automatically detects image dimensions
- Caches image metadata for performance
- Generates proper `alt` attributes from filename
- Supports nested directory structures

## File Management

### File Storage and Downloads

**Files Directory Structure:**
```
files/
├── downloads/             (Public downloadable files)
│   ├── user-manual.pdf
│   ├── price-list.xlsx
│   └── software/
│       └── installer.zip
├── uploads/               (User uploaded files)
│   ├── documents/
│   ├── images/
│   └── temp/
└── exports/               (Generated exports)
    ├── reports/
    └── data/
```

**File Delivery with sendFile():**
```cfm
<!--- In controller action --->
function downloadManual() {
    sendFile(file="files/downloads/user-manual.pdf", name="User Manual.pdf");
}

function downloadReport() {
    // Generate file path
    filePath = "files/exports/reports/monthly-report-" & DateFormat(Now(), "yyyy-mm") & ".pdf";
    
    // Send file with custom name
    sendFile(file=filePath, name="Monthly Report.pdf", type="application/pdf");
}
```

**File Upload Handling:**
```cfm
<!--- File upload form --->
<cfoutput>
#startFormTag(action="uploadFile", enctype="multipart/form-data")#
    #fileField(objectName="document", property="file", label="Select File:")#
    #submitTag("Upload File")#
#endFormTag()#
</cfoutput>

<!--- Controller action --->
function uploadFile() {
    if (StructKeyExists(params.document, "file") && IsStruct(params.document.file)) {
        // Define upload directory
        uploadDir = ExpandPath("files/uploads/documents/");
        
        // Ensure directory exists
        if (!DirectoryExists(uploadDir)) {
            DirectoryCreate(uploadDir);
        }
        
        // Upload file
        fileUpload(destination=uploadDir, nameConflict="makeUnique");
        
        flashInsert(success="File uploaded successfully!");
    } else {
        flashInsert(error="Please select a file to upload.");
    }
    
    redirectTo(action="index");
}
```

## Asset Optimization and CDN

### Asset Configuration

**Global Asset Settings** (in `/config/settings.cfm`):
```cfm
<cfscript>
// Enable asset query strings for cache busting
set(assetQueryString = true);

// CDN configuration
set(assetPaths = {
    http: "assets1.example.com,assets2.example.com",
    https: "secure-assets.example.com"
});
</cfscript>
```

**Environment-Specific Settings:**
```cfm
<!--- Development: Local assets, no query string --->
set(assetQueryString = false);

<!--- Production: CDN with cache busting --->
set(assetQueryString = true);
set(assetPaths = {
    http: "cdn.myapp.com",
    https: "cdn.myapp.com"
});
```

### Asset Helper Features

**Cache Busting:**
```cfm
<!--- Without assetQueryString --->
<link rel="stylesheet" href="/stylesheets/application.css">

<!--- With assetQueryString=true --->
<link rel="stylesheet" href="/stylesheets/application.css?v=1234567890">
```

**CDN Integration:**
```cfm
<!--- Local development --->
<script src="/javascripts/application.js"></script>

<!--- With CDN configured --->
<script src="https://cdn.myapp.com/javascripts/application.js"></script>
```

**Asset Bundling:**
```cfm
<!--- Multiple CSS files bundled --->
#styleSheetLinkTag("reset,typography,layout,application")#

<!--- Results in single request (when bundling enabled) --->
<link rel="stylesheet" href="/stylesheets/bundle-abc123.css">
```

## Special Directories

### Miscellaneous Directory

The `/public/miscellaneous/` directory is unique - it contains code that runs completely outside the Wheels framework.

**Structure:**
```
miscellaneous/
├── Application.cfc        (Empty - bypasses Wheels)
├── flash-gateway.cfm     (Flash AMF gateway)
├── ajax-proxy.cfc        (AJAX proxy component)
├── legacy-api/           (Legacy API endpoints)
└── webhooks/             (External webhook handlers)
```

**Use Cases:**
- Flash AMF bindings that conflict with Wheels
- `<cfajaxproxy>` CFC connections
- Legacy code integration
- External API endpoints that need direct access
- Webhook handlers that must bypass framework routing

**Example Miscellaneous File:**
```cfm
<!--- /public/miscellaneous/webhook.cfm --->
<!--- Handles external webhook outside Wheels framework --->
<cfheader name="Content-Type" value="application/json">

<cfscript>
// Process webhook payload
payload = GetHttpRequestData();

// Handle webhook logic without Wheels
response = {
    "status": "success",
    "message": "Webhook processed"
};

WriteOutput(SerializeJSON(response));
</cfscript>
```

## Security Considerations

### File Access Control

**Secure File Storage:**
```
app/                       (NOT web accessible)
├── secure-files/          (Private files)
├── user-data/            (User data storage)
└── temp/                 (Temporary files)

public/                    (Web accessible)
├── files/                (Public files only)
└── images/               (Public images only)
```

**Controlled File Access:**
```cfm
<!--- Controller action for secure file access --->
function downloadSecureFile() {
    // Check user permissions
    if (!current.user.hasPermission("download_files")) {
        renderText("Access denied");
        return;
    }
    
    // File stored outside web root
    secureFilePath = "/app/secure-files/document-" & params.id & ".pdf";
    
    if (FileExists(ExpandPath(secureFilePath))) {
        sendFile(file=secureFilePath, name="Document.pdf");
    } else {
        renderText("File not found");
    }
}
```

### Upload Security

**File Upload Validation:**
```cfm
function uploadFile() {
    if (StructKeyExists(params, "uploadedFile")) {
        upload = params.uploadedFile;
        
        // Validate file type
        allowedTypes = "jpg,jpeg,png,gif,pdf,doc,docx";
        fileExtension = ListLast(upload.serverFile, ".");
        
        if (!ListFindNoCase(allowedTypes, fileExtension)) {
            flashInsert(error="File type not allowed");
            redirectTo(action="uploadForm");
            return;
        }
        
        // Validate file size (5MB limit)
        if (upload.fileSize > 5242880) {
            flashInsert(error="File too large");
            redirectTo(action="uploadForm");
            return;
        }
        
        // Store in secure location with sanitized name
        safeName = REReplace(upload.clientFile, "[^a-zA-Z0-9\.\-_]", "", "all");
        finalPath = "files/uploads/" & DateFormat(Now(), "yyyy/mm/dd") & "/" & safeName;
        
        // Move uploaded file
        FileMove(upload.serverDirectory & "/" & upload.serverFile, ExpandPath(finalPath));
        
        flashInsert(success="File uploaded successfully");
    }
    
    redirectTo(action="index");
}
```

## Performance Optimization

### Asset Minification

**Development Assets:**
```
stylesheets/
├── src/                   (Source files)
│   ├── base.css
│   ├── components.css
│   └── layout.css
└── application.css        (Combined for development)
```

**Production Assets:**
```
stylesheets/
├── application.min.css    (Minified and compressed)
└── vendor.min.css         (Third-party libraries)
```

**Build Process Integration:**
```json
// package.json
{
  "scripts": {
    "build-css": "cat stylesheets/src/*.css > stylesheets/application.css",
    "minify-css": "cleancss -o stylesheets/application.min.css stylesheets/application.css",
    "build-js": "cat javascripts/src/*.js > javascripts/application.js",
    "minify-js": "uglifyjs javascripts/application.js -o javascripts/application.min.js"
  }
}
```

### Image Optimization

**Image Processing:**
```cfm
<!--- Resize and optimize images on upload --->
function processImageUpload() {
    if (StructKeyExists(params, "imageFile")) {
        // Create optimized versions
        originalPath = "images/uploads/original/" & params.imageFile.serverFile;
        thumbPath = "images/uploads/thumbs/" & params.imageFile.serverFile;
        mediumPath = "images/uploads/medium/" & params.imageFile.serverFile;
        
        // Resize for different uses
        imageResize(source=originalPath, destination=thumbPath, width=150, height=150);
        imageResize(source=originalPath, destination=mediumPath, width=400, height=300);
        
        // Compress original
        imageWrite(imageRead(originalPath), originalPath, 0.8);
    }
}
```

### Caching Strategies

**Static Asset Caching:**
```cfm
<!--- Set far-future expires headers for static assets --->
<cfheader name="Cache-Control" value="public, max-age=31536000">
<cfheader name="Expires" value="#DateAdd('yyyy', 1, Now())#">
```

**Asset Versioning:**
```cfm
<!--- Version assets based on file modification time --->
function assetVersion(required string asset) {
    filePath = ExpandPath("/" & arguments.asset);
    if (FileExists(filePath)) {
        fileInfo = GetFileInfo(filePath);
        return "?v=" & Hash(fileInfo.lastModified);
    }
    return "";
}

// Usage in views
#styleSheetLinkTag("application" & assetVersion("stylesheets/application.css"))#
```

## Development Workflow

### Local Development Setup

**Asset Organization:**
```
public/
├── stylesheets/
│   ├── src/              (Source SCSS/LESS files)
│   ├── compiled/         (Compiled CSS)
│   └── vendor/           (Third-party CSS)
├── javascripts/
│   ├── src/              (Source JS/TypeScript)
│   ├── compiled/         (Compiled JS)
│   └── vendor/           (Third-party JS)
└── images/
    ├── src/              (Original high-res images)
    └── optimized/        (Web-optimized images)
```

**Build Tools Integration:**
```bash
# Watch for changes during development
npm run watch

# Build for production
npm run build

# Optimize images
npm run optimize-images

# Deploy assets to CDN
npm run deploy-assets
```

### Asset Deployment

**Deployment Strategy:**
1. Build and minify assets locally or in CI/CD
2. Upload to CDN or static file server
3. Update asset configuration with new CDN URLs
4. Deploy application with new asset references

**CDN Deployment Script:**
```bash
#!/bin/bash
# Build assets
npm run build

# Upload to CDN
aws s3 sync public/stylesheets/ s3://myapp-assets/stylesheets/ --exclude "*.scss" --exclude "src/*"
aws s3 sync public/javascripts/ s3://myapp-assets/javascripts/ --exclude "*.ts" --exclude "src/*"  
aws s3 sync public/images/ s3://myapp-assets/images/

# Invalidate CDN cache
aws cloudfront create-invalidation --distribution-id E123456789 --paths "/*"
```

## Testing Assets

### Asset Testing

**Test Asset Loading:**
```cfm
<!--- Test helper functions --->
component extends="BaseSpec" {
    function run() {
        describe("Asset Helpers", function() {
            it("should generate correct CSS link", function() {
                result = styleSheetLinkTag("application");
                expect(result).toInclude('href="/stylesheets/application.css"');
                expect(result).toInclude('rel="stylesheet"');
            });
            
            it("should generate correct JS script", function() {
                result = javaScriptIncludeTag("application");
                expect(result).toInclude('src="/javascripts/application.js"');
            });
            
            it("should generate correct image tag", function() {
                // Assuming test image exists
                result = imageTag("test.png");
                expect(result).toInclude('src="/images/test.png"');
                expect(result).toInclude('alt="Test"');
            });
        });
    }
}
```

**Asset Existence Testing:**
```cfm
<!--- Verify critical assets exist --->
function testCriticalAssets() {
    criticalAssets = [
        "stylesheets/application.css",
        "javascripts/application.js", 
        "images/logo.png",
        "files/downloads/user-manual.pdf"
    ];
    
    for (asset in criticalAssets) {
        filePath = ExpandPath("/" & asset);
        if (!FileExists(filePath)) {
            throw(message="Critical asset missing: " & asset);
        }
    }
}
```

## Common Patterns

### Asset Organization Patterns

**Component-Based Organization:**
```
stylesheets/
├── base/                 (Base styles)
│   ├── reset.css
│   ├── typography.css
│   └── grid.css
├── components/           (Reusable components)  
│   ├── buttons.css
│   ├── forms.css
│   ├── navigation.css
│   └── tables.css
├── pages/               (Page-specific styles)
│   ├── home.css
│   ├── about.css
│   └── contact.css
└── vendor/              (Third-party)
    ├── bootstrap.min.css
    └── fontawesome.css
```

**Feature-Based Organization:**
```
javascripts/
├── core/                (Core functionality)
│   ├── app.js
│   ├── ajax.js
│   └── utils.js
├── features/            (Feature modules)
│   ├── user-management.js
│   ├── product-catalog.js
│   └── shopping-cart.js
├── pages/               (Page controllers)
│   ├── users.js
│   └── products.js
└── vendor/              (Libraries)
    ├── jquery.min.js
    └── bootstrap.min.js
```

### Asset Loading Patterns

**Progressive Loading:**
```cfm
<!--- Critical CSS inline --->
<style>
    /* Critical above-the-fold CSS */
    body { font-family: Arial, sans-serif; }
    .header { background: #333; color: white; }
</style>

<!--- Non-critical CSS deferred --->
<script>
    // Load non-critical CSS asynchronously
    var link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = '/stylesheets/non-critical.css';
    document.head.appendChild(link);
</script>
```

**Conditional Loading:**
```cfm
<!--- Load assets based on conditions --->
<cfif get("environment") == "development">
    <!--- Development: Individual files for debugging --->
    #styleSheetLinkTag("base,components,layout,theme")#
    #javaScriptIncludeTag("vendor/jquery,vendor/bootstrap,app")#
<cfelse>
    <!--- Production: Minified bundles --->
    #styleSheetLinkTag("application.min")#
    #javaScriptIncludeTag("application.min")#
</cfif>

<!--- Feature-specific assets --->
<cfif params.controller == "admin">
    #styleSheetLinkTag("admin")#
    #javaScriptIncludeTag("admin")#
</cfif>
```

The `/public` directory is the foundation of your Wheels application's web presence, providing secure asset management, framework bootstrap functionality, and flexible file organization patterns that scale from development through production deployment.