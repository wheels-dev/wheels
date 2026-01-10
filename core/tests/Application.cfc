component {
    this.name = "WheelsTestHarness";
    this.mappings["/wheels"] = expandPath("../src/wheels");
    this.datasource = "h2_test";
    this.db.connectionString = "jdbc:h2:mem:wheelstestdb;MODE=MySQL;DB_CLOSE_DELAY=-1";
}