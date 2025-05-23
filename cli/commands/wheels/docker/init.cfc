/**
 * Initialize Docker configuration for development
 * 
 * {code:bash}
 * wheels docker:init
 * wheels docker:init --db=mysql
 * wheels docker:init --db=postgres --dbVersion=13
 * {code}
 */
component extends="../base" {

    /**
     * @db Database to use (h2, mysql, postgres, mssql)
     * @dbVersion Database version to use
     * @cfengine ColdFusion engine to use (lucee, adobe)
     * @cfVersion ColdFusion engine version
     */
    function run(
        string db="mysql",
        string dbVersion="",
        string cfengine="lucee",
        string cfVersion="5.3"
    ) {
        // Welcome message
        print.line();
        print.boldMagentaLine("Wheels Docker Configuration");
        print.line();
        
        print.line();
        print.boldGreenLine("This feature is currently under development");
        print.line();
    }
}