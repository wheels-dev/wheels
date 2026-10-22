/**
 * Byte-identical SQL for the SQL-builder op reduction (approved performance slice, part B).
 *
 * The golden strings were captured on the change's base (origin/develop 0d1fef801) by running the
 * same builder calls on the SQLite adapter and pasting the output verbatim, so the production
 * change cannot alter one byte of generated SQL. Identifier quoting is dialect-dependent, so the
 * literals are pinned per dialect (SQLite and H2, the two the suite runs this spec on); other
 * dialects are covered by the exact-SQL specs and the full matrix.
 *
 * The only order-insensitive assertion is the `table.*` expansion, whose order comes from
 * iterating the model class's property struct - engine-defined in CFML. Its item set is pinned.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("SQL builder equivalence (performance slice B)", () => {

			describe("$registerAddedProperty", () => {

				it("counts exactly like the reference ListValueCountNoCase list scan", () => {
					var model = g.model("author");
					var items = ["id", "id", "ID", "author.id", "author.id AS x", "concat(a,b)", "concat(a,b)", "", "a,a", "a,,b"];
					var counts = {};
					var referenceList = "";
					for (var item in items) {
						var expected = ListValueCountNoCase(referenceList, item);
						var actual = model.$registerAddedProperty(counts = counts, item = item);
						expect(actual).toBe(expected, "item [#item#] diverged from the reference list scan");
						referenceList = ListAppend(referenceList, item);
					}
				});

			});

			describe("golden SQL is byte-identical on the recorded base", () => {

				it("keeps every select-clause byte", () => {
					var dialect = g.model("author").$dialectName();
					if (dialect != "SQLite" && dialect != "H2") {
						skip("golden literals are pinned for SQLite and H2; other dialects are covered by the full matrix");
					}
					var golden = dialect == "H2" ? $goldenSqlH2() : $goldenSqlSqlite();
					var author = g.model("author");
					var post = g.model("post");
					var user2 = g.model("user2");
					expect(author.$selectClause(select = "id,id", include = "", returnAs = "query")).toBeWithCase(golden["author.selectIdId"]);
					expect(author.$selectClause(select = "", include = "", returnAs = "query")).toBeWithCase(golden["author.defaultSelect"]);
					// `table.*` expansion: iterate the property struct, so compare the item set.
					var starItems = ListToArray(Replace(author.$selectClause(select = "c_o_r_e_authors.*", include = "", returnAs = "query"), "SELECT ", ""));
					var goldenStarItems = ListToArray(Replace(golden["author.selectStar"], "SELECT ", ""));
					ArraySort(starItems, "textnocase");
					ArraySort(goldenStarItems, "textnocase");
					expect(ArrayToList(starItems)).toBeWithCase(ArrayToList(goldenStarItems));
					expect(post.$selectClause(select = "", include = "author", returnAs = "query")).toBeWithCase(golden["post.includeAuthorDefaultQuery"]);
					expect(post.$selectClause(select = "", include = "author", returnAs = "objects")).toBeWithCase(golden["post.includeAuthorDefaultObjects"]);
					expect(post.$selectClause(select = "id", include = "author", returnAs = "query")).toBeWithCase(golden["post.includeAuthorSelectIdQuery"]);
					expect(post.$selectClause(select = "id", include = "author", returnAs = "objects")).toBeWithCase(golden["post.includeAuthorSelectIdObjects"]);
					expect(user2.$selectClause(select = "firstLetter", include = "", returnAs = "query")).toBeWithCase(golden["user2.selectCalculatedComma"]);
					expect(user2.$selectClause(select = "", include = "", returnAs = "query")).toBeWithCase(golden["user2.defaultSelectCalculatedComma"]);
				});

				it("keeps every order- and group-clause byte", () => {
					var dialect = g.model("author").$dialectName();
					if (dialect != "SQLite" && dialect != "H2") {
						skip("golden literals are pinned for SQLite and H2; other dialects are covered by the full matrix");
					}
					var golden = dialect == "H2" ? $goldenSqlH2() : $goldenSqlSqlite();
					var author = g.model("author");
					var post = g.model("post");
					expect(author.$orderByClause(order = "id", include = "")).toBeWithCase(golden["author.orderId"]);
					expect(author.$orderByClause(order = "id desc", include = "")).toBeWithCase(golden["author.orderIdDesc"]);
					expect(author.$orderByClause(order = "ID DESC", include = "")).toBeWithCase(golden["author.orderIdDescUpper"]);
					expect(author.$orderByClause(order = "id   desc", include = "")).toBeWithCase(golden["author.orderIdSpaces"]);
					expect(post.$orderByClause(order = "author.id desc", include = "author")).toBeWithCase(golden["post.orderAuthorIdDesc"]);
					expect(post.$orderByClause(order = "createdAt ASC", include = "")).toBeWithCase(golden["post.orderCreatedAtAsc"]);
					expect(post.$groupByClause(select = "authorid AS authoridAlias", include = "", group = "authorid", distinct = false, returnAs = "query")).toBeWithCase(golden["post.groupWithAlias"]);
					expect(post.$groupByClause(select = "", include = "author", group = "id", distinct = false, returnAs = "query")).toBeWithCase(golden["post.groupIncludeAuthor"]);
					expect(post.$groupByClause(select = "id, author.id", include = "author", group = "", distinct = true, returnAs = "query")).toBeWithCase(golden["post.groupDistinct"]);
				});

			});

			describe("$performQuery forwarding", () => {

				it("forwards query attributes but not the builder arguments", () => {
					var spy = CreateObject("component", "wheels.tests._assets.adapters.PerformQuerySpy");
					spy.$init(dataSource = g.get("dataSourceName"), username = "", password = "");
					spy.$performQuery(
						sql = ["SELECT 1"],
						parameterize = false,
						timeout = 7,
						cachedwithin = CreateTimeSpan(0, 0, 1, 0)
					);
					expect(ArrayLen(spy.capturedQueryAttributes)).toBe(1);
					var captured = spy.capturedQueryAttributes[1];
					expect(captured.timeout).toBe(7);
					expect(captured.cachedwithin).toBe(CreateTimeSpan(0, 0, 1, 0));
					var excluded = ["sql", "parameterize", "limit", "offset", "$primaryKey", "$captureResult", "$debugName"];
					for (var key in excluded) {
						expect(StructKeyExists(captured, key)).toBeFalse("builder argument [#key#] was forwarded to the query attributes");
					}
				});

			});

		});

	}

	/**
	 * Golden clauses captured from the base SHA on the SQLite adapter (also used by the Adobe/BoxLang sqlite legs).
	 */
	private struct function $goldenSqlSqlite() {
		return {
			"post.groupIncludeAuthor" = "GROUP BY ""c_o_r_e_posts"".""id""",
			"author.orderIdDesc" = "ORDER BY ""c_o_r_e_authors"".""id"" DESC",
			"post.includeAuthorDefaultObjects" = "SELECT ""c_o_r_e_posts"".""id"",""c_o_r_e_posts"".""authorid"",""c_o_r_e_posts"".""title"",""c_o_r_e_posts"".""body"",""c_o_r_e_posts"".""createdat"",""c_o_r_e_posts"".""updatedat"",""c_o_r_e_posts"".""deletedat"",""c_o_r_e_posts"".""views"",""c_o_r_e_posts"".""averagerating"",""c_o_r_e_posts"".""status"",""c_o_r_e_authors"".""firstname"" AS authorfirstname,""c_o_r_e_authors"".""lastname"" AS authorlastname",
			"author.orderIdDescUpper" = "ORDER BY ""c_o_r_e_authors"".""id"" DESC",
			"post.includeAuthorSelectIdQuery" = "SELECT ""c_o_r_e_posts"".""id""",
			"user2.selectCalculatedComma" = "SELECT (SUBSTRING(c_o_r_e_tblusers.username[[comma]] 1[[comma]] 1)) AS firstLetter",
			"post.orderAuthorIdDesc" = "ORDER BY author.id DESC",
			"author.selectIdId" = "SELECT ""c_o_r_e_authors"".""id""",
			"post.groupDistinct" = "GROUP BY ""c_o_r_e_posts"".""id"",author.id",
			"post.groupWithAlias" = "GROUP BY ""c_o_r_e_posts"".""authorid""",
			"author.defaultSelect" = "SELECT ""c_o_r_e_authors"".""id"",""c_o_r_e_authors"".""firstname"",""c_o_r_e_authors"".""lastname""",
			"post.includeAuthorSelectIdObjects" = "SELECT ""c_o_r_e_posts"".""id""",
			"post.includeAuthorDefaultQuery" = "SELECT ""c_o_r_e_posts"".""id"",""c_o_r_e_posts"".""authorid"",""c_o_r_e_posts"".""title"",""c_o_r_e_posts"".""body"",""c_o_r_e_posts"".""createdat"",""c_o_r_e_posts"".""updatedat"",""c_o_r_e_posts"".""deletedat"",""c_o_r_e_posts"".""views"",""c_o_r_e_posts"".""averagerating"",""c_o_r_e_posts"".""status"",""c_o_r_e_authors"".""firstname"",""c_o_r_e_authors"".""lastname""",
			"author.selectStar" = "SELECT c_o_r_e_authors.lastname,c_o_r_e_authors.firstname,c_o_r_e_authors.id",
			"author.orderIdSpaces" = "ORDER BY ""c_o_r_e_authors"".""id"" DESC",
			"user2.defaultSelectCalculatedComma" = "SELECT ""c_o_r_e_tblusers"".""id"",""c_o_r_e_tblusers"".""username"",""c_o_r_e_tblusers"".""password"",""c_o_r_e_tblusers"".""firstname"",""c_o_r_e_tblusers"".""lastname"",""c_o_r_e_tblusers"".""address"",""c_o_r_e_tblusers"".""city"",""c_o_r_e_tblusers"".""state"",""c_o_r_e_tblusers"".""zipcode"",""c_o_r_e_tblusers"".""phone"",""c_o_r_e_tblusers"".""fax"",""c_o_r_e_tblusers"".""birthday"",""c_o_r_e_tblusers"".""birthdaymonth"",""c_o_r_e_tblusers"".""birthdayyear"",""c_o_r_e_tblusers"".""birthtime"",""c_o_r_e_tblusers"".""isactive"",""c_o_r_e_tblusers"".""blank"",(SUBSTRING(c_o_r_e_tblusers.username[[comma]] 1[[comma]] 1)) AS firstLetter,(COUNT(c_o_r_e_tblusers.id)) AS groupCount",
			"post.orderCreatedAtAsc" = "ORDER BY ""c_o_r_e_posts"".""createdat"" ASC",
			"author.orderId" = "ORDER BY ""c_o_r_e_authors"".""id"" ASC"
		};
	}

	/**
	 * Golden clauses captured from the base SHA on the H2 adapter (quoted upper since #4628).
	 */
	private struct function $goldenSqlH2() {
		return {
			"post.groupIncludeAuthor" = "GROUP BY ""C_O_R_E_POSTS"".""ID""",
			"author.orderIdDesc" = "ORDER BY ""C_O_R_E_AUTHORS"".""ID"" DESC",
			"post.includeAuthorDefaultObjects" = "SELECT ""C_O_R_E_POSTS"".""ID"",""C_O_R_E_POSTS"".""AUTHORID"",""C_O_R_E_POSTS"".""TITLE"",""C_O_R_E_POSTS"".""BODY"",""C_O_R_E_POSTS"".""CREATEDAT"",""C_O_R_E_POSTS"".""UPDATEDAT"",""C_O_R_E_POSTS"".""DELETEDAT"",""C_O_R_E_POSTS"".""VIEWS"",""C_O_R_E_POSTS"".""AVERAGERATING"",""C_O_R_E_POSTS"".""STATUS"",""C_O_R_E_AUTHORS"".""FIRSTNAME"" AS authorFIRSTNAME,""C_O_R_E_AUTHORS"".""LASTNAME"" AS authorLASTNAME",
			"author.orderIdDescUpper" = "ORDER BY ""C_O_R_E_AUTHORS"".""ID"" DESC",
			"post.includeAuthorSelectIdQuery" = "SELECT ""C_O_R_E_POSTS"".""ID""",
			"user2.selectCalculatedComma" = "SELECT (SUBSTRING(c_o_r_e_tblusers.username[[comma]] 1[[comma]] 1)) AS firstLetter",
			"post.orderAuthorIdDesc" = "ORDER BY author.id DESC",
			"author.selectIdId" = "SELECT ""C_O_R_E_AUTHORS"".""ID""",
			"post.groupDistinct" = "GROUP BY ""C_O_R_E_POSTS"".""ID"",author.id",
			"post.groupWithAlias" = "GROUP BY ""C_O_R_E_POSTS"".""AUTHORID""",
			"author.defaultSelect" = "SELECT ""C_O_R_E_AUTHORS"".""ID"",""C_O_R_E_AUTHORS"".""FIRSTNAME"",""C_O_R_E_AUTHORS"".""LASTNAME""",
			"post.includeAuthorSelectIdObjects" = "SELECT ""C_O_R_E_POSTS"".""ID""",
			"post.includeAuthorDefaultQuery" = "SELECT ""C_O_R_E_POSTS"".""ID"",""C_O_R_E_POSTS"".""AUTHORID"",""C_O_R_E_POSTS"".""TITLE"",""C_O_R_E_POSTS"".""BODY"",""C_O_R_E_POSTS"".""CREATEDAT"",""C_O_R_E_POSTS"".""UPDATEDAT"",""C_O_R_E_POSTS"".""DELETEDAT"",""C_O_R_E_POSTS"".""VIEWS"",""C_O_R_E_POSTS"".""AVERAGERATING"",""C_O_R_E_POSTS"".""STATUS"",""C_O_R_E_AUTHORS"".""FIRSTNAME"",""C_O_R_E_AUTHORS"".""LASTNAME""",
			"author.selectStar" = "SELECT c_o_r_e_authors.lastname,c_o_r_e_authors.firstname,c_o_r_e_authors.id",
			"author.orderIdSpaces" = "ORDER BY ""C_O_R_E_AUTHORS"".""ID"" DESC",
			"user2.defaultSelectCalculatedComma" = "SELECT ""C_O_R_E_TBLUSERS"".""ID"",""C_O_R_E_TBLUSERS"".""USERNAME"",""C_O_R_E_TBLUSERS"".""PASSWORD"",""C_O_R_E_TBLUSERS"".""FIRSTNAME"",""C_O_R_E_TBLUSERS"".""LASTNAME"",""C_O_R_E_TBLUSERS"".""ADDRESS"",""C_O_R_E_TBLUSERS"".""CITY"",""C_O_R_E_TBLUSERS"".""STATE"",""C_O_R_E_TBLUSERS"".""ZIPCODE"",""C_O_R_E_TBLUSERS"".""PHONE"",""C_O_R_E_TBLUSERS"".""FAX"",""C_O_R_E_TBLUSERS"".""BIRTHDAY"",""C_O_R_E_TBLUSERS"".""BIRTHDAYMONTH"",""C_O_R_E_TBLUSERS"".""BIRTHDAYYEAR"",""C_O_R_E_TBLUSERS"".""BIRTHTIME"",""C_O_R_E_TBLUSERS"".""ISACTIVE"",""C_O_R_E_TBLUSERS"".""BLANK"",(SUBSTRING(c_o_r_e_tblusers.username[[comma]] 1[[comma]] 1)) AS firstLetter,(COUNT(c_o_r_e_tblusers.id)) AS groupCount",
			"post.orderCreatedAtAsc" = "ORDER BY ""C_O_R_E_POSTS"".""CREATEDAT"" ASC",
			"author.orderId" = "ORDER BY ""C_O_R_E_AUTHORS"".""ID"" ASC"
		};
	}

}
