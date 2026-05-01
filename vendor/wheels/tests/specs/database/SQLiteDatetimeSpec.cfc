component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("SQLite datetime storage", () => {

			// Guard: only run when connected to SQLite. Other adapters route
			// through PreparedStatement.setTimestamp directly and don't share
			// this bug surface.
			var migration = CreateObject("component", "wheels.migrator.Migration").init();
			if (migration.adapter.adapterName() != "SQLite") return;

			describe("$timestamp returns ISO-8601 strings without surrounding quotes", () => {

				it("does not wrap the value in single quotes", () => {
					// Pre-fix this returned "'2026-05-01 15:25:06'" (quotes baked
					// in), which then got stored verbatim in the TEXT column.
					var ts = application.wo.$timestamp("local");
					expect(ts).notToInclude("'");
					expect(ts).notToInclude("{ts");
					expect(IsDate(ts)).toBeTrue();
				});
			});

			describe("Stored TEXT values are clean ISO-8601 strings", () => {

				it("createdAt has no surrounding single quotes after a Wheels save", () => {
					transaction action="begin" {
						var author = g.model("author").create(
							firstName = "F6",
							lastName = "Quote",
							transaction = "none"
						);
						var post = g.model("post").create(
							authorId = author.id,
							title = "F6 createdAt quote check " & CreateUUID(),
							body = "test body",
							transaction = "none"
						);

						var raw = queryExecute(
							"SELECT createdat FROM c_o_r_e_posts WHERE id = :id",
							{ id = { value = post.id, cfsqltype = "cf_sql_integer" } },
							{ datasource = application.wheels.dataSourceName }
						);

						var stored = raw.createdat[1];
						expect(stored).notToInclude("'");
						expect(stored).notToInclude("{ts");
						expect(IsDate(stored)).toBeTrue();

						transaction action="rollback";
					}
				});

				it("deletedAt has no surrounding single quotes after a soft-delete", () => {
					transaction action="begin" {
						var author = g.model("author").create(
							firstName = "F6",
							lastName = "SoftDelete",
							transaction = "none"
						);
						var post = g.model("post").create(
							authorId = author.id,
							title = "F6 deletedAt quote check " & CreateUUID(),
							body = "test body",
							transaction = "none"
						);
						post.delete(transaction = "none");

						var raw = queryExecute(
							"SELECT deletedat FROM c_o_r_e_posts WHERE id = :id",
							{ id = { value = post.id, cfsqltype = "cf_sql_integer" } },
							{ datasource = application.wheels.dataSourceName }
						);

						var stored = raw.deletedat[1];
						expect(stored).notToInclude("'");
						expect(IsDate(stored)).toBeTrue();

						transaction action="rollback";
					}
				});

				it("DateFormat works on a read-back createdAt with no quote stripping", () => {
					transaction action="begin" {
						var author = g.model("author").create(
							firstName = "F6",
							lastName = "DateFormat",
							transaction = "none"
						);
						var post = g.model("post").create(
							authorId = author.id,
							title = "F6 DateFormat check " & CreateUUID(),
							body = "test body",
							transaction = "none"
						);

						var found = g.model("post").findByKey(post.id);
						// Tutorial chapter 8 calls DateFormat(comment.createdAt, "mmm d").
						// With the bug, the stored value is "'2026-...'" with quotes
						// and DateFormat throws "Can't cast String to value of type [datetime]".
						var formatted = DateFormat(found.createdat, "yyyy-mm-dd");
						expect(formatted).toMatch("^\d{4}-\d{2}-\d{2}$");

						transaction action="rollback";
					}
				});
			});
		});
	}
}
