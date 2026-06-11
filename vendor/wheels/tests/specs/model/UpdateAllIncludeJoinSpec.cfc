component extends="wheels.WheelsTest" {

	function run() {
		g = application.wo;

		describe("updateAll(include=) JOIN ON-condition handling", () => {

			it("exposes joinOnConditions on expanded association entries", () => {
				var classes = g.model("post").$expandedAssociations(include = "c_o_r_e_comments");
				expect(StructKeyExists(classes[1], "joinOnConditions")).toBeTrue();
			});

			it("joinOnConditions is the exact tail of the join string after the ON keyword", () => {
				var adapter = g.model("post").getClass().adapter;
				var classes = g.model("post").$expandedAssociations(include = "c_o_r_e_comments");
				var e = classes[1];
				var onPos = Find(" ON ", e.join);

				expect(onPos).toBeGT(0);
				expect(e.joinOnConditions).toBe(Mid(e.join, onPos + 4, Len(e.join)));
				expect(e.joinOnConditions).toInclude(adapter.$quoteIdentifier("c_o_r_e_comments"));
				// the conditions must not include the JOIN keyword or the joined table reference
				expect(e.joinOnConditions).notToInclude(" JOIN ");
			});

			it("builds untruncated join conditions in UPDATE where clauses", () => {
				var m = g.model("post");
				var dialect = m.$dialectName();
				var adapter = m.getClass().adapter;
				var rv = m.$whereClause(
					where = "c_o_r_e_comments.postid = 1",
					include = "c_o_r_e_comments",
					sql = ["UPDATE x SET"],
					includeSoftDeletes = true
				);
				var state = {sql = ""};
				for (var el in rv) {
					if (IsSimpleValue(el)) {
						state.sql &= el & " ";
					}
				}
				var leftSide = adapter.$quoteIdentifier("c_o_r_e_posts") & "." & adapter.$quoteIdentifier("id");
				var rightSide = adapter.$quoteIdentifier("c_o_r_e_comments") & "." & adapter.$quoteIdentifier("postid");

				if (ListFind("PostgreSQL,CockroachDB,H2,Oracle,SQLite", dialect)) {
					// both sides of the join equality survive (no ON-split truncation)
					expect(state.sql).toInclude(leftSide);
					expect(state.sql).toInclude(rightSide);
				} else if (dialect == "MicrosoftSQLServer") {
					// MSSQL keeps the full JOIN string
					expect(state.sql).toInclude(" JOIN ");
					expect(state.sql).toInclude(rightSide);
				}
				// MySQL handles include in the UPDATE clause itself; no WHERE branch fires
			});

			it("updateAll with multiple includes updates matching rows", () => {
				if (g.model("post").$dialectName() == "CockroachDB") return;
				transaction action="begin" {
					loc.n = g.model("Post").updateAll(
						averagerating = "3.3",
						where = "c_o_r_e_comments.postid = 1 AND c_o_r_e_authors.id > 0",
						include = "author,c_o_r_e_comments"
					);
					loc.q = g.model("Post").findAll(where = "averagerating = '3.3'");
					transaction action="rollback";
				}
				expect(loc.q.recordcount).toBe(1);
			});

		});
	}

}
