component extends="wheels.migrator.Migration" hint="CreateLikesTable" {

	function up() {
		transaction {
			t = createTable(name="likes");
			t.integer(columnNames="userId", allowNull=false);
			t.integer(columnNames="tweetId", allowNull=false);
			t.timestamps();
			t.create();

			addIndex(table="likes", columnNames="userId,tweetId", unique=true);
			addIndex(table="likes", columnNames="tweetId");
			addForeignKey(
				table="likes",
				referenceTable="users",
				column="userId",
				referenceColumn="id",
				keyName="FK_likes_userId",
				onDelete="cascade"
			);
			addForeignKey(
				table="likes",
				referenceTable="tweets",
				column="tweetId",
				referenceColumn="id",
				keyName="FK_likes_tweetId",
				onDelete="cascade"
			);
		}
	}

	function down() {
		dropTable("likes");
	}
}