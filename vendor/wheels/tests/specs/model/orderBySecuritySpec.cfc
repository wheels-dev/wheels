component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("ORDER BY clause security", () => {

			describe("normal property ordering", () => {

				it("allows ordering by a valid property name", () => {
					var result = g.model("author").$orderByClause(order="firstName", include="");
					expect(result).toInclude("ORDER BY");
					expect(result).toInclude("ASC");
				})

				it("allows ordering by property with ASC", () => {
					var result = g.model("author").$orderByClause(order="firstName ASC", include="");
					expect(result).toInclude("ORDER BY");
					expect(result).toInclude("ASC");
				})

				it("allows ordering by property with DESC", () => {
					var result = g.model("author").$orderByClause(order="lastName DESC", include="");
					expect(result).toInclude("ORDER BY");
					expect(result).toInclude("DESC");
				})

				it("allows ordering by multiple properties", () => {
					var result = g.model("author").$orderByClause(order="firstName ASC, lastName DESC", include="");
					expect(result).toInclude("ORDER BY");
					expect(result).toInclude("ASC");
					expect(result).toInclude("DESC");
				})

			})

			describe("random ordering", () => {

				it("allows random order keyword", () => {
					var result = g.model("author").$orderByClause(order="random", include="");
					expect(result).toInclude("ORDER BY");
				})

			})

			describe("calculated property ordering", () => {

				it("allows ordering by a calculated property name", () => {
					// User2 model has calculatedProperties: firstLetter, groupCount
					var result = g.model("user2").$orderByClause(order="groupCount", include="");
					expect(result).toInclude("ORDER BY");
					expect(result).toInclude("COUNT");
				})

			})

			describe("parentheses injection prevention", () => {

				it("rejects raw SQL with parentheses containing SELECT", () => {
					expect(function() {
						g.model("author").$orderByClause(order="(SELECT password FROM users LIMIT 1)", include="");
					}).toThrow("Wheels.InvalidOrderClause");
				})

				it("rejects raw SQL with parentheses containing DROP", () => {
					expect(function() {
						g.model("author").$orderByClause(order="(DROP TABLE users)", include="");
					}).toThrow("Wheels.InvalidOrderClause");
				})

				it("rejects raw SQL function calls not defined as calculated properties", () => {
					expect(function() {
						g.model("author").$orderByClause(order="COUNT(id)", include="");
					}).toThrow("Wheels.InvalidOrderClause");
				})

				it("rejects subquery injection with ASC suffix", () => {
					expect(function() {
						g.model("author").$orderByClause(order="(SELECT 1) ASC", include="");
					}).toThrow("Wheels.InvalidOrderClause");
				})

				it("rejects parentheses in multi-item order list", () => {
					expect(function() {
						g.model("author").$orderByClause(order="firstName ASC, (SELECT 1) DESC", include="");
					}).toThrow("Wheels.InvalidOrderClause");
				})

			})

			describe("dot-notation quoting (4374)", () => {

				it("quotes table.column exactly as it quotes the bare column", () => {
					var author = g.model("author");
					expect(author.$orderByClause(order="c_o_r_e_authors.lastName DESC", include=""))
						.toBe(author.$orderByClause(order="lastName DESC", include=""));
					expect(author.$orderByClause(order="c_o_r_e_authors.firstName ASC, c_o_r_e_authors.lastName", include=""))
						.toBe(author.$orderByClause(order="firstName ASC, lastName", include=""));
				})

				it("resolves the table and column case-insensitively to their real names", () => {
					var author = g.model("author");
					expect(author.$orderByClause(order="C_O_R_E_AUTHORS.LASTNAME desc", include=""))
						.toBe(author.$orderByClause(order="lastName DESC", include=""));
				})

				it("quotes a column of an included association's table", () => {
					var author = g.model("author");
					var posts = g.model("post");
					var expected = "ORDER BY " & posts.$quotedTableColumn(posts.tableName(), "title") & " ASC";
					expect(author.$orderByClause(order="#posts.tableName()#.title", include="posts")).toBe(expected);
				})

				it("leaves a qualifier it can't resolve (an alias) as written", () => {
					expect(g.model("author").$orderByClause(order="a.id DESC", include="")).toBe("ORDER BY a.id DESC");
				})

				it("runs on the database", () => {
					var rows = g.model("author").findAll(order="c_o_r_e_authors.lastName DESC", returnAs="query");
					var bare = g.model("author").findAll(order="lastName DESC", returnAs="query");
					expect(rows.recordCount).toBe(bare.recordCount);
					expect(ValueList(rows.id)).toBe(ValueList(bare.id));
				})

			})

			describe("dot-notation validation", () => {

				it("allows valid table.column dot notation", () => {
					var result = g.model("author").$orderByClause(order="c_o_r_e_authors.id ASC", include="");
					expect(result).toBe(g.model("author").$orderByClause(order="id ASC", include=""));
				})

				it("allows valid table.column without explicit direction", () => {
					var result = g.model("author").$orderByClause(order="c_o_r_e_authors.id", include="");
					expect(result).toBe(g.model("author").$orderByClause(order="id", include=""));
				})

				it("rejects SQL injection in dot-notation with semicolon", () => {
					expect(function() {
						g.model("author").$orderByClause(order="users.id; DROP TABLE users--", include="");
					}).toThrow("Wheels.InvalidOrderClause");
				})

				it("rejects SQL injection in dot-notation with subquery", () => {
					expect(function() {
						g.model("author").$orderByClause(order="(SELECT 1).foo", include="");
					}).toThrow("Wheels.InvalidOrderClause");
				})

				it("rejects dot-notation with special characters", () => {
					expect(function() {
						g.model("author").$orderByClause(order="ta'ble.col", include="");
					}).toThrow("Wheels.InvalidOrderClause");
				})

				it("rejects dot-notation with multiple dots", () => {
					expect(function() {
						g.model("author").$orderByClause(order="schema.table.column ASC", include="");
					}).toThrow("Wheels.InvalidOrderClause");
				})

			})

		})

	}

}
