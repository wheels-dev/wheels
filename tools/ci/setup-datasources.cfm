<cfscript>
// CI datasource setup: registers SQLite datasources in Lucee via admin API.
// Called once after server starts, before running tests.
admin = new Administrator("web", "password");

admin.updateDatasource(
    name: "wheelstestdb_sqlite",
    type: "Other",
    classname: "org.sqlite.JDBC",
    dsn: "jdbc:sqlite:#expandPath('/')#../wheelstestdb.db",
    newName: "wheelstestdb_sqlite",
    allowed_select: true,
    allowed_insert: true,
    allowed_update: true,
    allowed_delete: true,
    allowed_alter: true,
    allowed_drop: true,
    allowed_create: true
);

admin.updateDatasource(
    name: "wheelstestdb_sqlite_tenant_b",
    type: "Other",
    classname: "org.sqlite.JDBC",
    dsn: "jdbc:sqlite:#expandPath('/')#../wheelstestdb_tenant_b.db",
    newName: "wheelstestdb_sqlite_tenant_b",
    allowed_select: true,
    allowed_insert: true,
    allowed_update: true,
    allowed_delete: true,
    allowed_alter: true,
    allowed_drop: true,
    allowed_create: true
);

writeOutput('{"success":true,"datasources":["wheelstestdb_sqlite","wheelstestdb_sqlite_tenant_b"]}');
</cfscript>
