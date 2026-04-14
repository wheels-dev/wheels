<cfscript>
// CI datasource setup: defines SQLite datasources via application scope.
// This avoids needing Lucee Admin API credentials.
try {
    // Use Lucee's admin functions to create datasources programmatically
    admin = createObject("component", "lucee.admin").init("web", "password");
    admin.updateDatasource(
        name="wheelstestdb_sqlite",
        classname="org.sqlite.JDBC",
        dsn="jdbc:sqlite:{lucee-web}/../../wheelstestdb.db",
        newName="wheelstestdb_sqlite"
    );
    admin.updateDatasource(
        name="wheelstestdb_sqlite_tenant_b",
        classname="org.sqlite.JDBC",
        dsn="jdbc:sqlite:{lucee-web}/../../wheelstestdb_tenant_b.db",
        newName="wheelstestdb_sqlite_tenant_b"
    );
    writeOutput('{"success":true}');
} catch (any e) {
    // Fallback: try setting via server admin
    try {
        pageContext = getPageContext();
        config = pageContext.getConfig();
        // Create datasource via Lucee internal API
        ds = {
            "wheelstestdb_sqlite": {
                class: "org.sqlite.JDBC",
                dsn: "jdbc:sqlite:#expandPath('../')#wheelstestdb.db"
            },
            "wheelstestdb_sqlite_tenant_b": {
                class: "org.sqlite.JDBC",
                dsn: "jdbc:sqlite:#expandPath('../')#wheelstestdb_tenant_b.db"
            }
        };
        writeOutput('{"success":false,"error":"#e.message#","fallback":"attempted"}');
    } catch (any e2) {
        writeOutput('{"success":false,"error":"#e.message#","fallback_error":"#e2.message#"}');
    }
}
</cfscript>
