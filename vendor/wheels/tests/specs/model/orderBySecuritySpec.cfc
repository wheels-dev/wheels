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

			describe("dot-notation validation", () => {

				it("allows valid table.column dot notation", () => {
					var result = g.model("author").$orderByClause(order="c_o_r_e_authors.id ASC", include="");
					expect(result).toInclude("ORDER BY");
					expect(result).toInclude("c_o_r_e_authors.id");
				})

				it("allows valid table.column without explicit direction", () => {
					var result = g.model("author").$orderByClause(order="c_o_r_e_authors.id", include="");
					expect(result).toInclude("ORDER BY");
					expect(result).toInclude("c_o_r_e_authors.id");
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
