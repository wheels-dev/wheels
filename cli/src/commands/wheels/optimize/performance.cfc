/**
 * Optimize application performance
 * Examples:
 * wheels optimize performance
 * wheels optimize performance --cache --assets
 * wheels optimize performance --analysis
 */
component extends="../base" {
    
    property name="optimizationService" inject="OptimizationService@wheels-cli";
    
    /**
     * @cache.hint Optimize caching configuration
     * @assets.hint Optimize static assets
     * @database.hint Optimize database queries
     * @analysis.hint Generate performance analysis report
     * @apply.hint Apply recommended optimizations automatically
     */
    function run(
        boolean cache = true,
        boolean assets = true,
        boolean database = true,
        boolean analysis = false,
        boolean apply = false
    ) {
        print.yellowLine("⚡ Optimizing application performance...")
             .line();
        
        var results = {};
        var hasOptimizations = false;
        
        // Cache optimization
        if (arguments.cache) {
            print.line("🗄️  Analyzing cache configuration...");
            results.cache = optimizationService.optimizeCache();
            
            if (arrayLen(results.cache.optimized) > 0) {
                print.greenLine("✅ Cache optimization complete");
                for (var item in results.cache.optimized) {
                    print.greenLine("   • #item#");
                }
                hasOptimizations = true;
            }
            
            if (arrayLen(results.cache.recommendations) > 0) {
                print.yellowLine("📋 Cache recommendations:");
                for (var rec in results.cache.recommendations) {
                    print.line("   • #rec.message#");
                    if (arguments.apply) {
                        print.line("     Applied: #rec.code#");
                    }
                }
            }
            print.line();
        }
        
        // Asset optimization
        if (arguments.assets) {
            print.line("📦 Analyzing static assets...");
            results.assets = optimizationService.optimizeAssets();
            
            if (arrayLen(results.assets.optimized) > 0) {
                print.greenLine("✅ Asset optimization complete");
                hasOptimizations = true;
            }
            
            if (results.assets.keyExists("stats")) {
                var stats = results.assets.stats;
                print.line("   Files analyzed:");
                print.line("   • CSS: #stats.cssFiles# files");
                print.line("   • JavaScript: #stats.jsFiles# files");
                print.line("   • Images: #stats.imageFiles# files");
            }
            
            if (arrayLen(results.assets.recommendations) > 0) {
                print.yellowLine("📋 Asset recommendations:");
                var recCount = 0;
                for (var rec in results.assets.recommendations) {
                    recCount++;
                    if (recCount <= 10) {
                        print.line("   • [#rec.type#] #rec.message#");
                        if (rec.keyExists("file")) {
                            print.line("     File: #getFileFromPath(rec.file)#");
                        }
                    }
                }
                if (recCount > 10) {
                    print.line("   ... and #recCount - 10# more recommendations");
                }
            }
            print.line();
        }
        
        // Database optimization
        if (arguments.database) {
            print.line("🗃️  Analyzing database queries...");
            results.database = optimizationService.optimizeDatabase();
            
            if (arrayLen(results.database.optimized) > 0) {
                print.greenLine("✅ Database optimization complete");
                hasOptimizations = true;
            }
            
            if (arrayLen(results.database.recommendations) > 0) {
                print.yellowLine("📋 Database recommendations:");
                var dbRecCount = 0;
                for (var rec in results.database.recommendations) {
                    dbRecCount++;
                    if (dbRecCount <= 10) {
                        print.line("   • [#rec.type#] #rec.message#");
                        if (rec.keyExists("file")) {
                            print.line("     File: #getFileFromPath(rec.file)##rec.keyExists('line') ? ':' & rec.line : ''#");
                        }
                        if (rec.keyExists("suggestion")) {
                            print.line("     Suggestion: #rec.suggestion#");
                        }
                    }
                }
                if (dbRecCount > 10) {
                    print.line("   ... and #dbRecCount - 10# more recommendations");
                }
            }
            print.line();
        }
        
        // Generate analysis report
        if (arguments.analysis) {
            print.line()
                 .yellowLine("📊 Generating performance analysis report...")
                 .line();
            
            var report = optimizationService.generateReport(results);
            print.line(report);
        }
        
        // Summary
        if (!hasOptimizations && !hasRecommendations(results)) {
            print.greenBoldLine("✅ Your application is already well optimized!");
        } else if (hasRecommendations(results)) {
            var totalRecs = countRecommendations(results);
            print.yellowBoldLine("💡 Found #totalRecs# optimization opportunities");
            
            if (!arguments.apply) {
                print.line("   Run with --apply to implement recommended optimizations");
            }
        }
    }
    
    /**
     * Check if there are any recommendations
     */
    private function hasRecommendations(required struct results) {
        for (var key in arguments.results) {
            if (arguments.results[key].keyExists("recommendations") && 
                arrayLen(arguments.results[key].recommendations) > 0) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * Count total recommendations
     */
    private function countRecommendations(required struct results) {
        var count = 0;
        for (var key in arguments.results) {
            if (arguments.results[key].keyExists("recommendations")) {
                count += arrayLen(arguments.results[key].recommendations);
            }
        }
        return count;
    }
}