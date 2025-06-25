/**
 * Performance optimization tools
 * 
 * {code:bash}
 * wheels optimize performance
 * wheels optimize performance --analysis
 * {code}
 */
component extends="base" {
    
    /**
     * Display help for optimization commands
     */
    function run() {
        print.greenBoldLine("⚡ Wheels Performance Optimization")
             .line()
             .line("Available commands:")
             .line()
             .yellowLine("  wheels optimize performance")
             .line("    Analyze and optimize application performance")
             .line("    Options:")
             .line("      --cache      Optimize caching configuration (default: true)")
             .line("      --assets     Optimize static assets (default: true)")
             .line("      --database   Optimize database queries (default: true)")
             .line("      --analysis   Generate detailed performance report")
             .line("      --apply      Apply recommended optimizations")
             .line()
             .line("Examples:")
             .line("  wheels optimize performance")
             .line("  wheels optimize performance --analysis")
             .line("  wheels optimize performance --cache --apply")
             .line()
             .line("Optimization areas:")
             .line("  • Cache Configuration")
             .line("    - Query caching")
             .line("    - Model/Controller caching")
             .line("    - View caching")
             .line()
             .line("  • Asset Optimization")
             .line("    - CSS/JS minification")
             .line("    - Image optimization")
             .line("    - Asset bundling")
             .line("    - CDN usage")
             .line()
             .line("  • Database Performance")
             .line("    - Query optimization")
             .line("    - Index recommendations")
             .line("    - N+1 query detection");
    }
}