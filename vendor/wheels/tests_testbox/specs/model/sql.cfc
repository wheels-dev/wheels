component extends="testbox.system.BaseSpec" {

	function run() {

		g = application.wo

		describe("Tests that whereclause", () => {

			it("works with numeric operators", () => {
				operators = ListToArray("=,<>,!=,<,<=,!<,>,>=,!>")

				for (i in operators) {
					result = g.model("author").$whereClause(where = "id#i#0")

					expect(result[2]).toHaveLength(20+len(i))
					expect(result).toHaveLength(3)
					expect(result[3].type).toBe("cf_sql_integer")
					expect(Right(result[2], Len(i))).toBe(i)

					result = g.model("author").$whereClause(where = "id#i# 11")

					expect(result[2]).toHaveLength(20+len(i))
					expect(result).toHaveLength(3)
					expect(result[3].type).toBe("cf_sql_integer")
					expect(Right(result[2], Len(i))).toBe(i)
					
					result = g.model("author").$whereClause(where = "id #i#999")

					expect(result[2]).toHaveLength(20+len(i))
					expect(result).toHaveLength(3)
					expect(result[3].type).toBe("cf_sql_integer")
					expect(Right(result[2], Len(i))).toBe(i)
				}
			})

			it("works with in and like operators", () => {
				result = g.model("author").$whereClause(where = "id IN (1,2,3)")

				expect(Right(result[2], 2)).toBe("IN")

				result = g.model("author").$whereClause(where = "id NOT IN (1,2,3)")

				expect(Right(result[2], 6)).toBe("NOT IN")

				result = g.model("author").$whereClause(where = "lastName LIKE 'Djurner'")
				
				expect(Right(result[2], 4)).toBe("LIKE")

				result = g.model("author").$whereClause(where = "lastName NOT LIKE 'Djurner'")

				expect(Right(result[2], 8)).toBe("NOT LIKE")
			})

			it("works with floats", () => {
				result = g.model("post").$whereClause(where = "averagerating IN(3.6,3.2)")
				datatypes = {"float": true, "float8": true, "double": true, "number": true}

				expect(arraylen(result)).toBeGTE(4)
				expect(result[4]).toBeStruct()
				expect(datatypes).toHaveKey(result[4].datatype)

				result = g.model("post").$whereClause(where = "averagerating NOT IN(3.6,3.2)")
				
				expect(arraylen(result)).toBeGTE(4)
				expect(result[4]).toBeStruct()
				expect(datatypes).toHaveKey(result[4].datatype)

				result = g.model("post").$whereClause(where = "averagerating = 3.6")
				
				expect(arraylen(result)).toBeGTE(4)
				expect(result[4]).toBeStruct()
				expect(datatypes).toHaveKey(result[4].datatype)
			})

			it("works with is null", () => {
				result = g.model("post").$whereClause(where = "averagerating IS NULL")
				datatypes = {"float": true, "float8": true, "double": true, "number": true}

				expect(arraylen(result)).toBeGTE(4)
				expect(result[4]).toBeStruct()

				result = g.model("post").$whereClause(where = "averagerating IS NOT NULL")

				expect(arraylen(result)).toBeGTE(4)
				expect(result[4]).toBeStruct()
				expect(datatypes).toHaveKey(result[4].datatype)
			})

			it("respects calculated property datatype", () => {
				actual = g.model("post").$whereClause(where = "createdAtAlias > '#CreateDate(2000, 1, 1)#'")

				expect(actual[4].datatype).toBe("datetime")
			})

			it("protects against SQL Injection with Parameterize", () => {
				badparams = {username = "tonyp", password = "tonyp123' OR password!='tonyp123"}

				expect(function() {
					g.model("user").findall(where="username = '#badparams.username#' AND password = '#badparams.password#'", parameterize=2)
				}).toThrow("Wheels.ParameterMismatch")
			})
			
			it("protects against SQL Injection with Parameterize and Pagination", () => {
				badparams = {username = "tonyp", password = "tonyp123' OR password!='tonyp123"}

				expect(function() {
					g.model("user").findall(where="username = '#badparams.username#' AND password = '#badparams.password#'", parameterize=2, perPage=2, page=1)
				}).toThrow("Wheels.ParameterMismatch")
			})

			it("RESQLWhere regex handles whitespaces between single quotes and parenthesis", () => {
				actual = g.model("post").findAll(where = "(title LIKE '%test%' )")

				expect(actual.recordcount).toBeGT(0)
			})

			it( "CONCAT works with table alias", function(){
				actual = g.model("user").findAll(where = "username='tonyp'", select = "CONCAT(c_o_r_e_users.firstname,' ',c_o_r_e_users.lastname) as fullname")

				expect(	actual.fullname ).toBe("Tony Petruzzi")
			});

			it( "CONCAT fails without table alias", function(){

				expect(	function(){
					g.model("user").findAll(where = "username='tonyp'", select = "CONCAT(firstname,' ',lastname) as fullname")
				}).toThrow("Wheels.ColumnNotFound");

			});
		})
	}
}