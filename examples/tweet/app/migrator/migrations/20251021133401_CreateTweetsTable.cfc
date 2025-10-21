component extends="wheels.migrator.Migration" hint="CreateTweetsTable" {

	function up() {
		transaction {
			t = createTable(name="tweets");
			t.integer(columnNames="userId", allowNull=false);
			t.string(columnNames="content", limit=280, allowNull=false);
			t.integer(columnNames="likesCount", default=0, allowNull=false);
			t.integer(columnNames="repliesCount", default=0, allowNull=false);
			t.integer(columnNames="retweetsCount", default=0, allowNull=false);
			t.integer(columnNames="replyToTweetId");
			t.timestamps();
			t.create();

			addIndex(table="tweets", columnNames="userId");
			addIndex(table="tweets", columnNames="replyToTweetId");
			addForeignKey(
				table="tweets",
				referenceTable="users",
				column="userId",
				referenceColumn="id",
				keyName="FK_tweets_userId",
				onDelete="cascade"
			);
		}
	}

	function down() {
		dropTable("tweets");
	}
}