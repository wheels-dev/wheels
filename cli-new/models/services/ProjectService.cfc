/**
 * Project Service for Wheels CLI
 * Handles project detection, validation, and information
 * 
 * @singleton
 * @author CFWheels Team
 * @version 3.0.0
 */
component accessors="true" singleton {
    
    // DI Properties
    property name="fileSystem" inject="FileSystem";
    property name="log" inject="logbox:logger:{this}";
    property name="configService" inject="ConfigService@wheelscli";
    
    // Cache for project information
    property name="projectCache" type="struct";
    
    /**
     * Constructor
     */
    function init() {
        variables.projectCache = {};
        return this;
    }
    
    /**
     * Detect if current directory is a Wheels project
     */
    function detectProject(string path = "") {
        var projectPath = len(arguments.path) ? arguments.path : shell.pwd();
        
        // Check cache first
        if (structKeyExists(variables.projectCache, projectPath)) {
            return variables.projectCache[projectPath];
        }
        
        var projectInfo = {
            path = projectPath,
            isWheelsProject = false,
            isLegacyProject = false,
            version = "",
            hasVendorWheels = false,
            hasAppDirectory = false,
            hasConfigDirectory = false,
            hasBoxJson = false,
            projectName = "",
            datasource = "",
            environment = "development",
            errors = []
        };
        
        // Check for Wheels 3.0+ structure (vendor/wheels)
        if (directoryExists(projectPath & "/vendor/wheels")) {
            projectInfo.isWheelsProject = true;
            projectInfo.hasVendorWheels = true;
            projectInfo.version = detectWheelsVersion(projectPath & "/vendor/wheels");
        }
        
        // Check for legacy Wheels structure (wheels directory in root)
        else if (directoryExists(projectPath & "/wheels")) {
            projectInfo.isLegacyProject = true;
            projectInfo.version = detectWheelsVersion(projectPath & "/wheels");
            arrayAppend(projectInfo.errors, "Legacy Wheels structure detected. Please upgrade to Wheels 3.0+");
        }
        
        // Check for app directory
        if (directoryExists(projectPath & "/app")) {
            projectInfo.hasAppDirectory = true;
        }
        
        // Check for config directory
        if (directoryExists(projectPath & "/config")) {
            projectInfo.hasConfigDirectory = true;
        } else if (directoryExists(projectPath & "/app/config")) {
            // Legacy config location
            arrayAppend(projectInfo.errors, "Config directory found in legacy location /app/config. Should be moved to /config");
        }
        
        // Check for box.json
        if (fileExists(projectPath & "/box.json")) {
            projectInfo.hasBoxJson = true;
            try {
                var boxJson = deserializeJSON(fileRead(projectPath & "/box.json"));
                if (structKeyExists(boxJson, "name")) {
                    projectInfo.projectName = boxJson.name;
                }
            } catch (any e) {
                arrayAppend(projectInfo.errors, "Failed to parse box.json: #e.message#");
            }
        }
        
        // Check for Application.cfc
        if (fileExists(projectPath & "/Application.cfc")) {
            projectInfo.datasource = detectDatasource(projectPath & "/Application.cfc");
        }
        
        // Detect environment
        projectInfo.environment = getConfigService().getEnvironment();
        
        // Validate project structure
        if (projectInfo.isWheelsProject) {
            validateProjectStructure(projectInfo);
        }
        
        // Cache the result
        variables.projectCache[projectPath] = projectInfo;
        
        return projectInfo;
    }
    
    /**
     * Clear project cache
     */
    function clearCache(string path = "") {
        if (len(arguments.path)) {
            structDelete(variables.projectCache, arguments.path);
        } else {
            variables.projectCache = {};
        }
        return this;
    }
    
    /**
     * Get Wheels version from the framework
     */
    private function detectWheelsVersion(required string wheelsPath) {
        var versionFile = arguments.wheelsPath & "/version.json";
        
        if (fileExists(versionFile)) {
            try {
                var versionData = deserializeJSON(fileRead(versionFile));
                return versionData.version ?: "Unknown";
            } catch (any e) {
                log.debug("Failed to read version.json: #e.message#");
            }
        }
        
        // Try to read from wheels.cfc or other known locations
        var wheelsFile = arguments.wheelsPath & "/wheels.cfc";
        if (fileExists(wheelsFile)) {
            try {
                var content = fileRead(wheelsFile);
                var versionMatch = reFind('version\s*=\s*"([^"]+)"', content, 1, true);
                if (versionMatch.pos[1]) {
                    return mid(content, versionMatch.pos[2], versionMatch.len[2]);
                }
            } catch (any e) {
                log.debug("Failed to extract version from wheels.cfc: #e.message#");
            }
        }
        
        return "Unknown";
    }
    
    /**
     * Detect datasource from Application.cfc
     */
    private function detectDatasource(required string appPath) {
        try {
            var content = fileRead(arguments.appPath);
            
            // Look for this.datasource = "..."
            var dsMatch = reFind('this\.datasource\s*=\s*"([^"]+)"', content, 1, true);
            if (dsMatch.pos[1]) {
                return mid(content, dsMatch.pos[2], dsMatch.len[2]);
            }
            
            // Look for this.datasource = '...'
            dsMatch = reFind("this\.datasource\s*=\s*'([^']+)'", content, 1, true);
            if (dsMatch.pos[1]) {
                return mid(content, dsMatch.pos[2], dsMatch.len[2]);
            }
        } catch (any e) {
            log.debug("Failed to detect datasource: #e.message#");
        }
        
        return "";
    }
    
    /**
     * Validate project structure
     */
    private function validateProjectStructure(required struct projectInfo) {
        var requiredDirs = [
            "/app",
            "/app/controllers",
            "/app/models",
            "/app/views",
            "/config",
            "/public",
            "/vendor"
        ];
        
        var recommendedDirs = [
            "/db",
            "/db/migrate",
            "/tests"
        ];
        
        // Check required directories
        for (var dir in requiredDirs) {
            if (!directoryExists(projectInfo.path & dir)) {
                arrayAppend(projectInfo.errors, "Missing required directory: #dir#");
            }
        }
        
        // Check recommended directories
        for (var dir in recommendedDirs) {
            if (!directoryExists(projectInfo.path & dir)) {
                log.debug("Missing recommended directory: #dir#");
            }
        }
        
        // Check for required files
        var requiredFiles = [
            "/Application.cfc",
            "/index.cfm"
        ];
        
        for (var file in requiredFiles) {
            if (!fileExists(projectInfo.path & file)) {
                arrayAppend(projectInfo.errors, "Missing required file: #file#");
            }
        }
    }
    
    /**
     * Get project name
     */
    function getProjectName(string path = "") {
        var projectPath = len(arguments.path) ? arguments.path : shell.pwd();
        var projectInfo = detectProject(projectPath);
        
        // Priority: config > box.json > directory name
        var name = getConfigService().get("name", "");
        
        if (!len(name) && len(projectInfo.projectName)) {
            name = projectInfo.projectName;
        }
        
        if (!len(name)) {
            name = listLast(projectPath, "/\");
        }
        
        return name;
    }
    
    /**
     * Get project root path
     */
    function getProjectRoot(string startPath = "") {
        var currentPath = len(arguments.startPath) ? arguments.startPath : shell.pwd();
        
        // Walk up the directory tree looking for project markers
        while (len(currentPath) && currentPath != "/" && !findNoCase(":", currentPath)) {
            // Check for Wheels project markers
            if (directoryExists(currentPath & "/vendor/wheels") && 
                directoryExists(currentPath & "/app") &&
                fileExists(currentPath & "/Application.cfc")) {
                return currentPath;
            }
            
            // Move up one directory
            currentPath = getDirectoryFromPath(currentPath);
            currentPath = left(currentPath, len(currentPath) - 1); // Remove trailing slash
        }
        
        return "";
    }
    
    /**
     * Check if path is inside a Wheels project
     */
    function isInsideProject(string path = "") {
        var checkPath = len(arguments.path) ? arguments.path : shell.pwd();
        var projectRoot = getProjectRoot(checkPath);
        return len(projectRoot) > 0;
    }
    
    /**
     * Get relative path from project root
     */
    function getRelativePath(required string path, string projectRoot = "") {
        var root = len(arguments.projectRoot) ? arguments.projectRoot : getProjectRoot();
        
        if (!len(root)) {
            return arguments.path;
        }
        
        // Normalize paths
        var normalizedPath = replace(arguments.path, "\", "/", "all");
        var normalizedRoot = replace(root, "\", "/", "all");
        
        // Ensure root ends with /
        if (right(normalizedRoot, 1) != "/") {
            normalizedRoot &= "/";
        }
        
        // Remove root from path
        if (findNoCase(normalizedRoot, normalizedPath) == 1) {
            return mid(normalizedPath, len(normalizedRoot) + 1, len(normalizedPath));
        }
        
        return arguments.path;
    }
    
    /**
     * Initialize new project structure
     */
    function initializeProject(required string path, struct options = {}) {
        var directories = [
            "/app/controllers",
            "/app/models",
            "/app/views/layout",
            "/config/settings",
            "/db/migrate",
            "/db/seeds",
            "/db/sql",
            "/public/dist",
            "/public/images",
            "/public/javascripts",
            "/public/stylesheets",
            "/tests/specs/controllers",
            "/tests/specs/models",
            "/tests/specs/integration",
            "/vendor"
        ];
        
        // Create directories
        for (var dir in directories) {
            directoryCreate(arguments.path & dir, true);
            
            // Add .gitkeep to preserve empty directories
            if (!findNoCase("/vendor", dir)) {
                fileWrite(arguments.path & dir & "/.gitkeep", "");
            }
        }
        
        // Create .gitignore
        createGitIgnore(arguments.path);
        
        // Clear cache for this path
        clearCache(arguments.path);
        
        return true;
    }
    
    /**
     * Create .gitignore file
     */
    private function createGitIgnore(required string path) {
        var gitignoreContent = "# Wheels files
/vendor/
/db/*.db
/db/sqlite/*.db
/.env
/.env.*
!/.env.example

# IDE files
.idea/
.vscode/
*.sublime-*

# OS files
.DS_Store
Thumbs.db

# Test files
/tests/results/
/tests/reports/

# Logs
/logs/
*.log

# Cache
/cache/
/.cache/

# Build files
/dist/
/build/

# Dependencies
/node_modules/
/bower_components/

# CommandBox
.engine/
server.json.bak";
        
        fileWrite(arguments.path & "/.gitignore", gitignoreContent);
    }
}