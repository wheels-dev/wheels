component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("GROUP BY clause security", () => {

			describe("valid GROUP BY usage", () => {

				it("allows grouping by a valid property name", () => {
					var result = g.model("author").$groupByClause(
						select="lastName",
						include="",
						group="lastName",
						distinct=false,
						returnAs="query"
					);
					expect(result).toInclude("GROUP BY");
				})

				it("allows grouping by valid dot-notation", () => {
					var result = g.model("author").$groupByClause(
						select="lastName",
						include="",
						group="c_o_r_e_authors.lastName",
						distinct=false,
						returnAs="query"
					);
					expect(result).toInclude("GROUP BY");
					expect(result).toInclude("c_o_r_e_authors.lastName");
				})

				it("allows grouping by multiple properties", () => {
					var result = g.model("author").$groupByClause(
						select="firstName,lastName",
						include="",
						group="firstName,lastName",
						distinct=false,
						returnAs="query"
					);
					expect(result).toInclude("GROUP BY");
				})

			})

			describe("SQL injection prevention", () => {

				it("rejects semicolon injection in group clause", () => {
					expect(function() {
						g.model("author").$groupByClause(
							select="lastName",
							include="",
							group="lastName; DROP TABLE users",
							distinct=false,
							returnAs="query"
						);
					}).toThrow("Wheels.InvalidGroupByClause");
				})

				it("rejects SQL comment injection with double dash", () => {
					expect(function() {
						g.model("author").$groupByClause(
							select="lastName",
							include="",
							group="lastName -- comment",
							distinct=false,
							returnAs="query"
						);
					}).toThrow("Wheels.InvalidGroupByClause");
				})

				it("rejects SQL comment injection with block comment", () => {
					expect(function() {
						g.model("author").$groupByClause(
							select="lastName",
							include="",
							group="lastName /* comment */",
							distinct=false,
							returnAs="query"
						);
					}).toThrow("Wheels.InvalidGroupByClause");
				})

				it("rejects parenthesized expressions", () => {
					expect(function() {
						g.model("author").$groupByClause(
							select="lastName",
							include="",
							group="(SELECT 1)",
							distinct=false,
							returnAs="query"
						);
					}).toThrow("Wheels.InvalidGroupByClause");
				})

				it("rejects raw SQL function calls", () => {
					expect(function() {
						g.model("author").$groupByClause(
							select="lastName",
							include="",
							group="COUNT(id)",
							distinct=false,
							returnAs="query"
						);
					}).toThrow("Wheels.InvalidGroupByClause");
				})

			})

			describe("dot-notation injection prevention", () => {

				it("rejects SQL injection via dot-notation with semicolon", () => {
					expect(function() {
						g.model("author").$groupByClause(
							select="lastName",
							include="",
							group="users.id; DROP TABLE users--",
							distinct=false,
							returnAs="query"
						);
					}).toThrow("Wheels.InvalidGroupByClause");
				})

				it("rejects dot-notation with special characters", () => {
					expect(function() {
						g.model("author").$groupByClause(
							select="lastName",
							include="",
							group="ta'ble.col",
							distinct=false,
							returnAs="query"
						);
					}).toThrow("Wheels.InvalidGroupByClause");
				})

				it("rejects dot-notation with multiple dots", () => {
					expect(function() {
						g.model("author").$groupByClause(
							select="lastName",
							include="",
							group="schema.table.column",
							distinct=false,
							returnAs="query"
						);
					}).toThrow("Wheels.InvalidGroupByClause");
				})

				it("rejects aliases in GROUP BY via dot-notation path", () => {
					expect(function() {
						g.model("author").$groupByClause(
							select="lastName",
							include="",
							group="lastName AS ln",
							distinct=false,
							returnAs="query"
						);
					}).toThrow("Wheels.InvalidGroupByClause");
				})

			})

		})

	}

}
