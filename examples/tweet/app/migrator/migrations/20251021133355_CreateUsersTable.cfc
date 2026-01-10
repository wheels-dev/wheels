component extends="wheels.migrator.Migration" hint="CreateUsersTable" {

	function up() {
		transaction {
			t = createTable(name="users");
			t.string(columnNames="username", limit=50, allowNull=false);
			t.string(columnNames="email", limit=100, allowNull=false);
			t.string(columnNames="passwordHash", limit=255, allowNull=false);
			t.string(columnNames="bio", limit=500);
			t.string(columnNames="location", limit=100);
			t.string(columnNames="website", limit=255);
			t.string(columnNames="avatar", limit=255);
			t.integer(columnNames="followersCount", default=0, allowNull=false);
			t.integer(columnNames="followingCount", default=0, allowNull=false);
			t.integer(columnNames="tweetsCount", default=0, allowNull=false);
			t.timestamps();
			t.create();

			addIndex(table="users", columnNames="username", unique=true);
			addIndex(table="users", columnNames="email", unique=true);
		}
	}

	function down() {
		dropTable("users");
	}
}