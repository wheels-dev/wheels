component extends="wheels.migrator.Migration" hint="CreateFollowsTable" {

	function up() {
		transaction {
			t = createTable(name="follows");
			t.integer(columnNames="followerId", allowNull=false);
			t.integer(columnNames="followingId", allowNull=false);
			t.timestamps();
			t.create();

			addIndex(table="follows", columnNames="followerId,followingId", unique=true);
			addIndex(table="follows", columnNames="followingId");
		}
	}

	function down() {
		dropTable("follows");
	}
}