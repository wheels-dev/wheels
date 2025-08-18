# BoxLang Server Setup

CFWheels supports BoxLang 1.3.x, providing developers with a modern, high-performance CFML runtime. You can run BoxLang applications using either CommandBox or BoxLang Mini-Server.

## Prerequisites

- **Java 21 or higher** installed on your system
- **CFWheels application** (generated or existing)
- **BoxLang runtime** (see installation options below)

## Method 1: Using CommandBox (Recommended)

CommandBox provides the easiest and most feature-rich way to run BoxLang applications with CFWheels.

### Installation and Setup

```bash
# Install BoxLang engine in CommandBox
box install boxlang

# Start server with BoxLang
box server start cfengine=boxlang

# Or specify specific BoxLang version
box server start cfengine=boxlang@1.3.0
```

### BoxLang Module Dependencies

BoxLang requires specific modules for full CFWheels compatibility. These dependencies should be added to your `box.json` file:

```json
{
  "dependencies": {
    "bx-compat-cfml": "^1.27.0+35",
    "bx-csrf": "^1.2.0+3", 
    "bx-esapi": "^1.6.0+9",
    "bx-image": "^1.0.1",
    "bx-mssql": "^1.4.0+11",
    "bx-mysql": "^1.0.1+7"
  }
}
```

#### Installing Dependencies

```bash
# Install all dependencies from box.json
box install

# Or install specific BoxLang modules individually
box install bx-compat-cfml
box install bx-csrf
box install bx-esapi
box install bx-image
box install bx-mssql
box install bx-mysql
```

#### Module Descriptions

- **`bx-compat-cfml`** - CFML compatibility layer for BoxLang
- **`bx-csrf`** - Cross-Site Request Forgery protection
- **`bx-esapi`** - Enterprise Security API for input validation  
- **`bx-image`** - Image manipulation functionality
- **`bx-mssql`** - Microsoft SQL Server database driver
- **`bx-mysql`** - MySQL database driver

#### Finding Additional Modules

Browse available BoxLang modules on ForgeBox:
- Visit [forgebox.io](https://www.forgebox.io)
- Search for modules with `bx-` prefix
- Install specific modules: `box install module-name`

### Server Configuration

Create a `server.json` file in your application root to persist BoxLang settings:

```json
{
    "name":"wheels",
    "web":{
        "host":"localhost",
        "http":{
            "port":3000
        },
        "webroot":"public",
        "rewrites":{
            "enable":true,
            "config":"public/urlrewrite.xml"
        }
    },
    "app": {
        "cfengine": "boxlang@1.3.0"
    }
}
```

### Development Workflow

```bash
# Generate new Wheels app (if needed)
wheels g app myapp --engine=boxlang

# Navigate to app directory
cd myapp

# Install BoxLang dependencies
box install

# Start BoxLang development server  
server start cfengine=boxlang

# Access your application at http://localhost:8080
```

## Method 2: Using BoxLang Mini-Server

BoxLang Mini-Server provides a lightweight, standalone option perfect for minimal setups or specific deployment scenarios.

### Version Compatibility Warning

⚠️ **Important**: CFWheels currently supports BoxLang 1.3.x. The latest BoxLang Mini-Server downloads include version 1.4.x, which may not be fully compatible with CFWheels.

**Download the specific 1.3.0 version:**

```bash
# Download BoxLang Mini-Server 1.3.0 JAR file
curl -O https://downloads.ortussolutions.com/ortussolutions/boxlang-runtimes/boxlang-miniserver/1.3.0/boxlang-miniserver-1.3.0.jar
```

### Installation Steps

1. **Download BoxLang Mini-Server Package**

   ```bash
   # Download complete package (optional, for additional files)
   wget https://downloads.ortussolutions.com/ortussolutions/boxlang-runtimes/boxlang-miniserver/1.3.0/boxlang-miniserver-1.3.0.zip
   unzip boxlang-miniserver-1.3.0.zip
   ```

2. **Prepare Your Application Structure**

   ```
   your-wheels-app/
   ├── config/           # Configuration files
   ├── app/             # Controllers, models, views
   ├── public/          # Web-accessible files
   │   ├── index.bxm    # BoxLang entry point (required)
   │   ├── stylesheets/
   │   ├── javascripts/
   │   └── images/
   └── vendor/wheels/   # CFWheels framework files
   ```

3. **Setup BoxLang Entry Point**

   Create an `index.bxm` file in your `public/` folder with the following content:

   ```boxlang
   <bx:script>
   // BoxLang rewrite handler for CFWheels
   // This file handles URL rewriting for BoxLang compatibility

   // Get the requested URI
   requestURI = cgi.request_uri ?: "";

   // Remove query string for pattern matching  
   if (find("?", requestURI)) {
       requestURI = listFirst(requestURI, "?");
   }

   // Handle requests that come through /index.bxm/path - redirect to clean URL
   if (find("/index.bxm/", requestURI)) {
       cleanPath = replace(requestURI, "/index.bxm", "");
       queryString = cgi.query_string ?: "";
       redirectURL = cleanPath;
       if (len(queryString)) {
           redirectURL &= "?" & queryString;
       }
       bx:header name="Location" value=redirectURL;
       bx:header statusCode=301;
       bx:abort;
   }

   // Static paths that should not be rewritten (based on urlrewrite.xml)
   staticPaths = "cf_script,flex2gateway,jrunscripts,CFIDE,lucee,cfformgateway,cffileservlet,files,images,javascripts,miscellaneous,stylesheets,wheels/public/assets";
   specialFiles = "robots.txt,favicon.ico,sitemap.xml,index.cfm";

   // Check if this is a static path or special file
   isStatic = false;

   if (len(requestURI) && requestURI != "/") {
       cleanPath = right(requestURI, len(requestURI) - 1); // Remove leading slash
       
       // Check special files first
       fileName = listLast(requestURI, "/");
       if (listFindNoCase(specialFiles, fileName)) {
           isStatic = true;
       }
       
       // Check static paths
       if (!isStatic) {
           for (staticPath in listToArray(staticPaths)) {
               if (left(cleanPath, len(staticPath)) == staticPath) {
                   isStatic = true;
                   break;
               }
           }
       }
       
       // Check file extensions for static files
       if (!isStatic && listLen(cleanPath, ".") > 1) {
           extension = listLast(cleanPath, ".");
           staticExtensions = "js,css,png,jpg,jpeg,gif,ico,pdf,zip,txt,xml,json";
           if (listFindNoCase(staticExtensions, extension)) {
               isStatic = true;
           }
       }
   }

   // If it's a static file, let it pass through
   if (isStatic) {
       bx:header statusCode=404;
       writeOutput("File not found");
       bx:abort;
   }

   // Set up CGI variables for clean URL generation
   if (len(requestURI) && requestURI != "/") {
       cgi.path_info = requestURI;
   }

   // Override script name for clean URL generation
   cgi.script_name = "/index.cfm";

   // Clean up request URI
   if (find("/index.bxm", cgi.request_uri ?: "")) {
       cgi.request_uri = replace(cgi.request_uri, "/index.bxm", "");
   }

   // Update request scope for Wheels compatibility
   if (structKeyExists(request, "cgi")) {
       request.cgi.script_name = "/index.cfm";
       if (structKeyExists(request.cgi, "request_uri") && find("/index.bxm", request.cgi.request_uri)) {
           request.cgi.request_uri = replace(request.cgi.request_uri, "/index.bxm", "");
       }
   }
   </bx:script>

   <!--- Include the main CFWheels bootstrap file --->
   <bx:include template="index.cfm" />
   ```

   This file serves as the BoxLang-specific entry point that handles URL rewriting and bootstraps your CFWheels application.

### Starting BoxLang Mini-Server

#### Basic Command

```bash
java -jar /path/to/boxlang-miniserver-1.3.0.jar \
  --webroot /path/to/your/app/public \
  --rewrite
```

#### Full Configuration Example

```bash
java -jar /path/to/boxlang-miniserver-1.3.0.jar \
  --webroot /path/to/your/app/public \
  --host 127.0.0.1 \
  --port 8080 \
  --rewrite \
  --debug
```

#### For CFWheels Template Structure

If using the CFWheels base template structure:

```bash
java -jar /path/to/boxlang-miniserver-1.3.0.jar \
  --webroot /path/to/your/app/templates/base/src/public \
  --rewrite \
  --port 8080
```

### Mini-Server Command Options

| Option | Description | Default |
|--------|-------------|---------|
| `--webroot` | Document root directory (required) | None |
| `--host` | IP address to bind to | 0.0.0.0 |
| `--port` | Port number | 8080 |
| `--rewrite` | Enable URL rewriting (recommended for CFWheels) | false |
| `--debug` | Enable debug mode | false |
| `--config` | Path to configuration file | None |
| `--libs` | Additional library paths | None |

You can read the further details from the boxlang mini-server documentation

## Troubleshooting

### Common Issues

1. **Missing BoxLang Dependencies (CommandBox)**
   - **Problem**: Functions or features not working, missing module errors
   - **Solution**: Ensure all required BoxLang modules are installed: `box install`
   - **Check**: Verify `box.json` contains all required `bx-*` dependencies

2. **Missing index.bxm File (Mini-Server)**
   - **Problem**: Server returns 404 or directory listing
   - **Solution**: Create `index.bxm` in your `public/` folder using the complete file content provided above in the Setup steps

3. **URL Routing Not Working**
   - **Problem**: Routes return 404 errors
   - **Solution**: Always include the `--rewrite` flag when starting Mini-Server

4. **Version Compatibility Issues**
   - **Problem**: Unexpected errors or features not working
   - **Solution**: Verify you're using BoxLang 1.3.0, not 1.4.x

5. **Path Resolution Problems**
   - **Problem**: Files not found or incorrect paths
   - **Solution**: Use absolute paths to avoid directory resolution issues

### Testing Your Setup

```bash
# Verify server is responding
curl http://localhost:8080

# Test CFWheels is loading
curl http://localhost:8080/wheels

# Check specific routes
curl http://localhost:8080/say/hello
```

{% hint style="info" %}
#### Recommendation

For most developers, **CommandBox with BoxLang** provides the best experience with automatic updates, dependency management, and integrated tooling. Use BoxLang Mini-Server for specialized deployment scenarios or minimal footprint requirements.
{% endhint %}