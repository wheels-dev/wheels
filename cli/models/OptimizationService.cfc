component {
    
    property name="fileSystemUtil" inject="FileSystem@commandbox-core";
    property name="serverService" inject="ServerService@commandbox-core";
    
    /**
     * Optimize cache configuration
     */
    function optimizeCache() {
        var results = {
            optimized: [],
            recommendations: []
        };
        
        // Check for Wheels cache settings
        var settingsPath = resolvePath("app/config/settings.cfm");
        if (fileExists(settingsPath)) {
            var content = fileRead(settingsPath);
            
            // Check if caching is enabled
            if (!reFindNoCase("set\(cacheQueries\s*=\s*true", content)) {
                arrayAppend(results.recommendations, {
                    type: "QUERY_CACHING",
                    message: "Enable query caching for better performance",
                    code: "set(cacheQueries=true);"
                });
            }
            
            // Check cache timeouts
            if (!reFindNoCase("set\(cacheDatabaseSchema\s*=\s*true", content)) {
                arrayAppend(results.recommendations, {
                    type: "SCHEMA_CACHING",
                    message: "Enable database schema caching",
                    code: "set(cacheDatabaseSchema=true);"
                });
            }
            
            // Check for model caching
            if (!reFindNoCase("set\(cacheModelInitialization\s*=\s*true", content)) {
                arrayAppend(results.recommendations, {
                    type: "MODEL_CACHING",
                    message: "Enable model initialization caching",
                    code: "set(cacheModelInitialization=true);"
                });
            }
            
            // Check for controller caching
            if (!reFindNoCase("set\(cacheControllerInitialization\s*=\s*true", content)) {
                arrayAppend(results.recommendations, {
                    type: "CONTROLLER_CACHING",
                    message: "Enable controller initialization caching",
                    code: "set(cacheControllerInitialization=true);"
                });
            }
            
            // Check for view caching
            if (!reFindNoCase("set\(cacheFileChecking\s*=\s*false", content)) {
                arrayAppend(results.recommendations, {
                    type: "FILE_CHECKING",
                    message: "Disable file checking in production for better performance",
                    code: "set(cacheFileChecking=false); // For production only"
                });
            }
        }
        
        // Check for cache directory
        var cacheDir = resolvePath("app/cache");
        if (!directoryExists(cacheDir)) {
            directoryCreate(cacheDir);
            arrayAppend(results.optimized, "Created cache directory");
        }
        
        // Implement recommended optimizations
        if (arrayLen(results.recommendations) && fileExists(settingsPath)) {
            var newSettings = [];
            arrayAppend(newSettings, "");
            arrayAppend(newSettings, "// Performance Optimizations");
            
            for (var rec in results.recommendations) {
                arrayAppend(newSettings, rec.code);
                arrayAppend(results.optimized, rec.type);
            }
            
            // Append to settings file
            var currentContent = fileRead(settingsPath);
            fileWrite(settingsPath, currentContent & chr(10) & arrayToList(newSettings, chr(10)));
        }
        
        return results;
    }
    
    /**
     * Optimize static assets
     */
    function optimizeAssets() {
        var results = {
            optimized: [],
            recommendations: [],
            stats: {
                cssFiles: 0,
                jsFiles: 0,
                imageFiles: 0,
                totalSizeBefore: 0,
                totalSizeAfter: 0
            }
        };
        
        // Find asset directories
        var assetDirs = ["stylesheets", "javascripts", "images", "assets"];
        
        for (var dir in assetDirs) {
            var path = resolvePath(dir);
            if (directoryExists(path)) {
                processAssetDirectory(path, results);
            }
        }
        
        // Check for asset pipeline configuration
        checkAssetPipeline(results);
        
        // Check for CDN usage
        checkCDNUsage(results);
        
        return results;
    }
    
    /**
     * Process asset directory for optimization
     */
    private function processAssetDirectory(required string path, required struct results) {
        var files = directoryList(arguments.path, true, "query");
        
        for (var file in files) {
            if (file.type == "file") {
                var ext = listLast(file.name, ".");
                var filePath = file.directory & "/" & file.name;
                
                switch (lCase(ext)) {
                    case "css":
                        arguments.results.stats.cssFiles++;
                        checkCSSOptimization(filePath, arguments.results);
                        break;
                    case "js":
                        arguments.results.stats.jsFiles++;
                        checkJSOptimization(filePath, arguments.results);
                        break;
                    case "jpg":
                    case "jpeg":
                    case "png":
                    case "gif":
                        arguments.results.stats.imageFiles++;
                        checkImageOptimization(filePath, arguments.results);
                        break;
                }
                
                arguments.results.stats.totalSizeBefore += file.size;
            }
        }
    }
    
    /**
     * Check CSS optimization
     */
    private function checkCSSOptimization(required string filePath, required struct results) {
        var content = fileRead(arguments.filePath);
        var originalSize = len(content);
        
        // Check if minified
        if (len(content) > 1000 && !findNoCase(".min.", arguments.filePath)) {
            // Simple check for minification - look for newlines and spaces
            var lineCount = listLen(content, chr(10));
            var avgLineLength = originalSize / lineCount;
            
            if (avgLineLength < 80) {
                arrayAppend(arguments.results.recommendations, {
                    type: "CSS_MINIFICATION",
                    file: arguments.filePath,
                    message: "CSS file should be minified",
                    potentialSaving: round(originalSize * 0.3) // Estimate 30% reduction
                });
            }
        }
        
        // Check for unused CSS (simple heuristic)
        if (reFindNoCase("(unused|deprecated|old-)", content)) {
            arrayAppend(arguments.results.recommendations, {
                type: "UNUSED_CSS",
                file: arguments.filePath,
                message: "Potentially unused CSS classes detected"
            });
        }
    }
    
    /**
     * Check JS optimization
     */
    private function checkJSOptimization(required string filePath, required struct results) {
        var content = fileRead(arguments.filePath);
        var originalSize = len(content);
        
        // Check if minified
        if (len(content) > 1000 && !findNoCase(".min.", arguments.filePath)) {
            var lineCount = listLen(content, chr(10));
            var avgLineLength = originalSize / lineCount;
            
            if (avgLineLength < 80) {
                arrayAppend(arguments.results.recommendations, {
                    type: "JS_MINIFICATION",
                    file: arguments.filePath,
                    message: "JavaScript file should be minified",
                    potentialSaving: round(originalSize * 0.4) // Estimate 40% reduction
                });
            }
        }
        
        // Check for console.log statements
        if (reFindNoCase("console\.(log|debug|info|warn)", content)) {
            arrayAppend(arguments.results.recommendations, {
                type: "CONSOLE_STATEMENTS",
                file: arguments.filePath,
                message: "Remove console statements in production"
            });
        }
    }
    
    /**
     * Check image optimization
     */
    private function checkImageOptimization(required string filePath, required struct results) {
        var fileInfo = getFileInfo(arguments.filePath);
        var fileSize = fileInfo.size;
        
        // Check for large images
        if (fileSize > 100000) { // 100KB
            arrayAppend(arguments.results.recommendations, {
                type: "LARGE_IMAGE",
                file: arguments.filePath,
                message: "Large image file (#round(fileSize/1024)#KB) - consider optimization",
                size: fileSize
            });
        }
        
        // Check for appropriate format
        var ext = listLast(arguments.filePath, ".");
        if (ext == "png" && fileSize > 50000) {
            arrayAppend(arguments.results.recommendations, {
                type: "IMAGE_FORMAT",
                file: arguments.filePath,
                message: "Consider using JPEG for photographic images or WebP for better compression"
            });
        }
    }
    
    /**
     * Check asset pipeline configuration
     */
    private function checkAssetPipeline(required struct results) {
        // Check for asset bundling configuration
        var configFiles = ["webpack.config.js", "gulpfile.js", "Gruntfile.js", "rollup.config.js"];
        var hasAssetPipeline = false;
        
        for (var configFile in configFiles) {
            if (fileExists(resolvePath(configFile))) {
                hasAssetPipeline = true;
                break;
            }
        }
        
        if (!hasAssetPipeline) {
            arrayAppend(arguments.results.recommendations, {
                type: "ASSET_PIPELINE",
                message: "Consider implementing an asset pipeline for bundling and optimization",
                suggestion: "Use webpack, gulp, or similar tools for asset optimization"
            });
        }
    }
    
    /**
     * Check CDN usage
     */
    private function checkCDNUsage(required struct results) {
        // Check layout files for CDN usage
        var layoutDir = resolvePath("app/views/layout");
        if (directoryExists(layoutDir)) {
            var layoutFiles = directoryList(layoutDir, false, "path", "*.cfm");
            
            for (var file in layoutFiles) {
                var content = fileRead(file);
                
                // Check for local jQuery, Bootstrap, etc.
                if (reFindNoCase("(jquery|bootstrap|font-awesome)[^""']*(js|css)", content) &&
                    !reFindNoCase("(cdn|cdnjs|googleapis|unpkg)", content)) {
                    
                    arrayAppend(arguments.results.recommendations, {
                        type: "CDN_USAGE",
                        file: file,
                        message: "Consider using CDN for common libraries (jQuery, Bootstrap, etc.)"
                    });
                    break;
                }
            }
        }
    }
    
    /**
     * Optimize database queries
     */
    function optimizeDatabase() {
        var results = {
            optimized: [],
            recommendations: [],
            queries: []
        };
        
        // Analyze model files for query optimization opportunities
        var modelDir = resolvePath("app/models");
        if (directoryExists(modelDir)) {
            var modelFiles = directoryList(modelDir, true, "path", "*.cfc");
            
            for (var file in modelFiles) {
                analyzeModelQueries(file, results);
            }
        }
        
        // Check for missing indexes
        checkMissingIndexes(results);
        
        // Check for N+1 query problems
        checkNPlusOneQueries(results);
        
        return results;
    }
    
    /**
     * Analyze model queries
     */
    private function analyzeModelQueries(required string filePath, required struct results) {
        var content = fileRead(arguments.filePath);
        var lines = listToArray(content, chr(10));
        var lineNumber = 0;
        
        for (var line in lines) {
            lineNumber++;
            
            // Check for SELECT * queries
            if (reFindNoCase("select\s+\*\s+from", line)) {
                arrayAppend(arguments.results.recommendations, {
                    type: "SELECT_STAR",
                    file: arguments.filePath,
                    line: lineNumber,
                    message: "Avoid SELECT * - specify only needed columns",
                    code: trim(line)
                });
            }
            
            // Check for missing WHERE clauses
            if (reFindNoCase("(delete|update)\s+.*\s+from\s+\w+\s*(;|$)", line) &&
                !reFindNoCase("\s+where\s+", line)) {
                
                arrayAppend(arguments.results.recommendations, {
                    type: "MISSING_WHERE",
                    file: arguments.filePath,
                    line: lineNumber,
                    message: "UPDATE/DELETE without WHERE clause affects all rows",
                    code: trim(line),
                    severity: "high"
                });
            }
            
            // Check for LIKE with leading wildcard
            if (reFindNoCase("like\s+['""]%", line)) {
                arrayAppend(arguments.results.recommendations, {
                    type: "LEADING_WILDCARD",
                    file: arguments.filePath,
                    line: lineNumber,
                    message: "Leading wildcard in LIKE prevents index usage",
                    code: trim(line)
                });
            }
            
            // Check for multiple OR conditions
            var orCount = listLen(line, " OR ") - 1;
            if (orCount > 3) {
                arrayAppend(arguments.results.recommendations, {
                    type: "MULTIPLE_OR",
                    file: arguments.filePath,
                    line: lineNumber,
                    message: "Multiple OR conditions can be slow - consider using IN clause",
                    code: trim(line)
                });
            }
        }
    }
    
    /**
     * Check for missing database indexes
     */
    private function checkMissingIndexes(required struct results) {
        // Look for common patterns that need indexes
        var modelDir = resolvePath("app/models");
        if (directoryExists(modelDir)) {
            var modelFiles = directoryList(modelDir, false, "path", "*.cfc");
            
            for (var file in modelFiles) {
                var content = fileRead(file);
                
                // Check for findBy* methods
                var findByMatches = reMatchNoCase("function\s+findBy(\w+)", content);
                for (var match in findByMatches) {
                    var column = lCase(mid(match, 11, len(match)));
                    arrayAppend(arguments.results.recommendations, {
                        type: "MISSING_INDEX",
                        model: getFileFromPath(file),
                        column: column,
                        message: "Consider adding index on '#column#' column for findBy#column#() queries"
                    });
                }
            }
        }
    }
    
    /**
     * Check for N+1 query problems
     */
    private function checkNPlusOneQueries(required struct results) {
        var controllerDir = resolvePath("app/controllers");
        if (directoryExists(controllerDir)) {
            var controllerFiles = directoryList(controllerDir, true, "path", "*.cfc");
            
            for (var file in controllerFiles) {
                var content = fileRead(file);
                
                // Look for loops with queries
                if (findNoCase("cfloop", content) && findNoCase("query", content) || 
                    findNoCase("findAll", content)) {
                    
                    // Check if there's another query inside the loop
                    if (findNoCase("findByKey", content) || findNoCase("findOne", content) || findNoCase("findAll", content)) {
                        arrayAppend(arguments.results.recommendations, {
                            type: "N_PLUS_ONE",
                            file: file,
                            message: "Potential N+1 query problem - consider using includes",
                            suggestion: "Use include parameter in findAll() to eager load associations"
                        });
                    }
                }
            }
        }
    }
    
    /**
     * Generate optimization report
     */
    function generateReport(required struct results) {
        var report = {
            summary: {
                cacheOptimizations: arrayLen(results.cache.optimized),
                cacheRecommendations: arrayLen(results.cache.recommendations),
                assetOptimizations: arrayLen(results.assets.optimized),
                assetRecommendations: arrayLen(results.assets.recommendations),
                databaseOptimizations: arrayLen(results.database.optimized),
                databaseRecommendations: arrayLen(results.database.recommendations)
            },
            details: arguments.results
        };
        
        // Calculate potential performance improvements
        var improvements = [];
        
        if (report.summary.cacheRecommendations > 0) {
            arrayAppend(improvements, "Enable caching: ~20-50% performance improvement");
        }
        
        if (results.assets.keyExists("stats")) {
            var minificationSavings = 0;
            for (var rec in results.assets.recommendations) {
                if (rec.keyExists("potentialSaving")) {
                    minificationSavings += rec.potentialSaving;
                }
            }
            if (minificationSavings > 0) {
                arrayAppend(improvements, "Asset optimization: ~#round(minificationSavings/1024)#KB reduction");
            }
        }
        
        if (report.summary.databaseRecommendations > 0) {
            arrayAppend(improvements, "Database optimization: ~10-30% query performance improvement");
        }
        
        report.potentialImprovements = improvements;
        
        return generateReportOutput(report);
    }
    
    /**
     * Generate report output
     */
    private function generateReportOutput(required struct report) {
        var output = [];
        
        arrayAppend(output, "Performance Optimization Report");
        arrayAppend(output, "==============================");
        arrayAppend(output, "");
        arrayAppend(output, "Summary:");
        arrayAppend(output, "  Cache Optimizations: #report.summary.cacheOptimizations# applied, #report.summary.cacheRecommendations# recommended");
        arrayAppend(output, "  Asset Optimizations: #report.summary.assetOptimizations# applied, #report.summary.assetRecommendations# recommended");
        arrayAppend(output, "  Database Optimizations: #report.summary.databaseOptimizations# applied, #report.summary.databaseRecommendations# recommended");
        
        if (arrayLen(report.potentialImprovements)) {
            arrayAppend(output, "");
            arrayAppend(output, "Potential Performance Improvements:");
            for (var improvement in report.potentialImprovements) {
                arrayAppend(output, "  • #improvement#");
            }
        }
        
        // Cache recommendations
        if (arrayLen(report.details.cache.recommendations)) {
            arrayAppend(output, "");
            arrayAppend(output, "Cache Recommendations:");
            for (var rec in report.details.cache.recommendations) {
                arrayAppend(output, "  • #rec.message#");
                arrayAppend(output, "    #rec.code#");
            }
        }
        
        // Asset recommendations
        if (arrayLen(report.details.assets.recommendations)) {
            arrayAppend(output, "");
            arrayAppend(output, "Asset Recommendations:");
            for (var rec in report.details.assets.recommendations) {
                arrayAppend(output, "  • [#rec.type#] #rec.message#");
                if (rec.keyExists("file")) {
                    arrayAppend(output, "    File: #rec.file#");
                }
            }
        }
        
        // Database recommendations
        if (arrayLen(report.details.database.recommendations)) {
            arrayAppend(output, "");
            arrayAppend(output, "Database Recommendations:");
            for (var rec in report.details.database.recommendations) {
                arrayAppend(output, "  • [#rec.type#] #rec.message#");
                if (rec.keyExists("file")) {
                    arrayAppend(output, "    File: #rec.file##rec.keyExists('line') ? ':' & rec.line : ''#");
                }
            }
        }
        
        return arrayToList(output, chr(10));
    }
    
    /**
     * Resolve a file path
     */
    private function resolvePath(path) {
        return fileSystemUtil.resolvePath(arguments.path);
    }
}