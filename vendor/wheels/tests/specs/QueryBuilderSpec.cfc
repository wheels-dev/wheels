component extends="wheels.WheelsTest" {

	function run() {

		describe("QueryBuilder Property Name Validation", function() {

			beforeEach(function() {
				// Create a QueryBuilder with a real model reference so $quoteValue works
				modelRef = model("post");
				qb = new wheels.model.query.QueryBuilder(modelReference = modelRef);
			});

			describe("valid property names", function() {

				it("accepts simple property names", function() {
					expect(function() {
						qb.whereNull("status");
					}).notToThrow();
				});

				it("accepts property names with underscores", function() {
					expect(function() {
						qb.whereNotNull("first_name");
					}).notToThrow();
				});

				it("accepts property names starting with underscore", function() {
					expect(function() {
						qb.whereNull("_internal");
					}).notToThrow();
				});

				it("accepts dot notation for table.column", function() {
					expect(function() {
						qb.whereNull("users.id");
					}).notToThrow();
				});

				it("accepts dot notation with underscores", function() {
					expect(function() {
						qb.whereNull("user_accounts.first_name");
					}).notToThrow();
				});

				it("accepts property names with numbers", function() {
					expect(function() {
						qb.whereNull("address2");
					}).notToThrow();
				});

			});

			describe("invalid property names are rejected", function() {

				it("rejects SQL injection with semicolon and DROP", function() {
					expect(function() {
						qb.whereNull("id; DROP TABLE users");
					}).toThrow("Wheels.InvalidPropertyName");
				});

				it("rejects property names with parentheses", function() {
					expect(function() {
						qb.whereNull("COUNT(id)");
					}).toThrow("Wheels.InvalidPropertyName");
				});

				it("rejects property names with single quotes", function() {
					expect(function() {
						qb.whereNull("name' OR '1'='1");
					}).toThrow("Wheels.InvalidPropertyName");
				});

				it("rejects property names with double quotes", function() {
					expect(function() {
						qb.whereNull('name" OR "1"="1');
					}).toThrow("Wheels.InvalidPropertyName");
				});

				it("rejects empty strings", function() {
					expect(function() {
						qb.whereNull("");
					}).toThrow("Wheels.InvalidPropertyName");
				});

				it("rejects property names with spaces", function() {
					expect(function() {
						qb.whereNull("first name");
					}).toThrow("Wheels.InvalidPropertyName");
				});

				it("rejects property names with hyphens", function() {
					expect(function() {
						qb.whereNull("first-name");
					}).toThrow("Wheels.InvalidPropertyName");
				});

				it("rejects property names starting with a number", function() {
					expect(function() {
						qb.whereNull("1column");
					}).toThrow("Wheels.InvalidPropertyName");
				});

				it("rejects multiple dots", function() {
					expect(function() {
						qb.whereNull("schema.table.column");
					}).toThrow("Wheels.InvalidPropertyName");
				});

				it("rejects trailing dot", function() {
					expect(function() {
						qb.whereNull("table.");
					}).toThrow("Wheels.InvalidPropertyName");
				});

				it("rejects leading dot", function() {
					expect(function() {
						qb.whereNull(".column");
					}).toThrow("Wheels.InvalidPropertyName");
				});

				it("rejects SQL comment injection", function() {
					expect(function() {
						qb.whereNull("id--");
					}).toThrow("Wheels.InvalidPropertyName");
				});

			});

			describe("validation applies to all affected methods", function() {

				it("validates whereNotNull property", function() {
					expect(function() {
						qb.whereNotNull("id; DROP TABLE users");
					}).toThrow("Wheels.InvalidPropertyName");
				});

				it("validates whereBetween property", function() {
					expect(function() {
						qb.whereBetween(property="id; DROP TABLE users", low=1, high=10);
					}).toThrow("Wheels.InvalidPropertyName");
				});

				it("validates whereIn property", function() {
					expect(function() {
						qb.whereIn(property="id; DROP TABLE users", values="1,2,3");
					}).toThrow("Wheels.InvalidPropertyName");
				});

				it("validates whereNotIn property", function() {
					expect(function() {
						qb.whereNotIn(property="id; DROP TABLE users", values="1,2,3");
					}).toThrow("Wheels.InvalidPropertyName");
				});

				it("validates orderBy property", function() {
					expect(function() {
						qb.orderBy("id; DROP TABLE users");
					}).toThrow("Wheels.InvalidPropertyName");
				});

				it("validates where() two-argument form property", function() {
					expect(function() {
						qb.where("id; DROP TABLE users", "active");
					}).toThrow("Wheels.InvalidPropertyName");
				});

				it("validates where() three-argument form property", function() {
					expect(function() {
						qb.where("id; DROP TABLE users", "=", "active");
					}).toThrow("Wheels.InvalidPropertyName");
				});

				it("validates orWhere() two-argument form property", function() {
					expect(function() {
						qb.orWhere("id; DROP TABLE users", "active");
					}).toThrow("Wheels.InvalidPropertyName");
				});

				it("validates orWhere() three-argument form property", function() {
					expect(function() {
						qb.orWhere("id; DROP TABLE users", "=", "active");
					}).toThrow("Wheels.InvalidPropertyName");
				});

			});

			describe("orderBy direction validation", function() {

				it("accepts ASC", function() {
					expect(function() {
						qb.orderBy(property="name", direction="ASC");
					}).notToThrow();
				});

				it("accepts DESC", function() {
					expect(function() {
						qb.orderBy(property="name", direction="DESC");
					}).notToThrow();
				});

				it("accepts lowercase asc", function() {
					expect(function() {
						qb.orderBy(property="name", direction="asc");
					}).notToThrow();
				});

				it("rejects SQL injection in direction", function() {
					expect(function() {
						qb.orderBy(property="name", direction="ASC; DROP TABLE users");
					}).toThrow("Wheels.InvalidSortDirection");
				});

			});

			describe("operator validation", function() {

				it("accepts standard comparison operators", function() {
					var operators = ["=", "!=", "<>", "<", ">", "<=", ">="];
					for (var op in operators) {
						expect(function() {
							qb.where("status", op, "active");
						}).notToThrow();
					}
				});

				it("accepts LIKE operator", function() {
					expect(function() {
						qb.where("name", "LIKE", "%test%");
					}).notToThrow();
				});

				it("accepts NOT LIKE operator", function() {
					expect(function() {
						qb.where("name", "NOT LIKE", "%test%");
					}).notToThrow();
				});

				it("rejects SQL injection in operator", function() {
					expect(function() {
						qb.where("status", "= 1; DROP TABLE users --", "active");
					}).toThrow("Wheels.InvalidOperator");
				});

				it("rejects arbitrary strings as operators", function() {
					expect(function() {
						qb.where("status", "UNION SELECT", "active");
					}).toThrow("Wheels.InvalidOperator");
				});

			});

			describe("raw where passthrough is not affected", function() {

				it("allows single-argument raw SQL in where()", function() {
					expect(function() {
						qb.where("status = 'active' OR role = 'admin'");
					}).notToThrow();
				});

				it("allows single-argument raw SQL in orWhere()", function() {
					expect(function() {
						qb.orWhere("status = 'active' OR role = 'admin'");
					}).notToThrow();
				});

			});

		});

	}

}
