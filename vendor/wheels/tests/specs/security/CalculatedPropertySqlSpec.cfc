component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Calculated property SQL injection prevention", () => {

			beforeEach(() => {
				g.$clearModelInitializationCache()
			})

			afterEach(() => {
				g.$clearModelInitializationCache()
			})

			describe("$validateCalculatedPropertySql", () => {

				it("rejects SQL with semicolons followed by whitespace", () => {
					expect(function() {
						var m = g.model("post")
						m.$validateCalculatedPropertySql(sql="firstName; DROP TABLE users", propertyName="test")
					}).toThrow("Wheels.InvalidCalculatedProperty")
				})

				it("rejects SQL with bare trailing semicolons", () => {
					expect(function() {
						var m = g.model("post")
						m.$validateCalculatedPropertySql(sql="COUNT(*);", propertyName="test")
					}).toThrow("Wheels.InvalidCalculatedProperty")
				})

				it("rejects SQL with EXECUTE keyword", () => {
					expect(function() {
						var m = g.model("post")
						m.$validateCalculatedPropertySql(sql="EXECUTE('SELECT 1')", propertyName="test")
					}).toThrow("Wheels.InvalidCalculatedProperty")
				})

				it("rejects SQL with UNION SELECT", () => {
					expect(function() {
						var m = g.model("post")
						m.$validateCalculatedPropertySql(sql="firstName UNION SELECT password FROM admins", propertyName="test")
					}).toThrow("Wheels.InvalidCalculatedProperty")
				})

				it("rejects SQL with EXEC", () => {
					expect(function() {
						var m = g.model("post")
						m.$validateCalculatedPropertySql(sql="EXEC sp_executesql N'SELECT 1'", propertyName="test")
					}).toThrow("Wheels.InvalidCalculatedProperty")
				})

				it("rejects SQL with xp_ extended stored procedures", () => {
					expect(function() {
						var m = g.model("post")
						m.$validateCalculatedPropertySql(sql="xp_cmdshell('dir')", propertyName="test")
					}).toThrow("Wheels.InvalidCalculatedProperty")
				})

				it("rejects SQL with SLEEP function", () => {
					expect(function() {
						var m = g.model("post")
						m.$validateCalculatedPropertySql(sql="SLEEP(5)", propertyName="test")
					}).toThrow("Wheels.InvalidCalculatedProperty")
				})

				it("rejects SQL with BENCHMARK", () => {
					expect(function() {
						var m = g.model("post")
						m.$validateCalculatedPropertySql(sql="BENCHMARK(1000000, SHA1('test'))", propertyName="test")
					}).toThrow("Wheels.InvalidCalculatedProperty")
				})

				it("rejects SQL with LOAD_FILE", () => {
					expect(function() {
						var m = g.model("post")
						m.$validateCalculatedPropertySql(sql="LOAD_FILE('/etc/passwd')", propertyName="test")
					}).toThrow("Wheels.InvalidCalculatedProperty")
				})

				it("rejects SQL with INTO OUTFILE", () => {
					expect(function() {
						var m = g.model("post")
						m.$validateCalculatedPropertySql(sql="SELECT 1 INTO OUTFILE '/tmp/data.txt'", propertyName="test")
					}).toThrow("Wheels.InvalidCalculatedProperty")
				})

				it("rejects SQL with INTO DUMPFILE", () => {
					expect(function() {
						var m = g.model("post")
						m.$validateCalculatedPropertySql(sql="SELECT 1 INTO DUMPFILE '/tmp/data.bin'", propertyName="test")
					}).toThrow("Wheels.InvalidCalculatedProperty")
				})

				it("allows legitimate CONCAT expression", () => {
					var m = g.model("post")
					var result = m.$validateCalculatedPropertySql(sql="CONCAT(firstName, ' ', lastName)", propertyName="fullName")
					expect(result).toBe("CONCAT(firstName, ' ', lastName)")
				})

				it("allows legitimate CASE expression", () => {
					var m = g.model("post")
					var result = m.$validateCalculatedPropertySql(sql="CASE WHEN status = 1 THEN 'active' ELSE 'inactive' END", propertyName="statusLabel")
					expect(result).toBe("CASE WHEN status = 1 THEN 'active' ELSE 'inactive' END")
				})

				it("allows aggregate functions", () => {
					var m = g.model("post")
					var result = m.$validateCalculatedPropertySql(sql="COUNT(comments.id)", propertyName="commentCount")
					expect(result).toBe("COUNT(comments.id)")
				})

				it("allows subselect without dangerous patterns", () => {
					var m = g.model("post")
					var result = m.$validateCalculatedPropertySql(sql="(SELECT COUNT(*) FROM comments WHERE comments.postId = posts.id)", propertyName="commentCount")
					expect(result).toBe("(SELECT COUNT(*) FROM comments WHERE comments.postId = posts.id)")
				})

				it("allows COALESCE expression", () => {
					var m = g.model("post")
					var result = m.$validateCalculatedPropertySql(sql="COALESCE(nickname, firstName)", propertyName="displayName")
					expect(result).toBe("COALESCE(nickname, firstName)")
				})

			})

			describe("property() integration", () => {

				it("throws when defining a calculated property with dangerous SQL", () => {
					expect(function() {
						var m = g.model("post")
						m.property(name="evil", sql="firstName; DROP TABLE users")
					}).toThrow("Wheels.InvalidCalculatedProperty")
				})

				it("allows defining a calculated property with safe SQL", () => {
					var m = g.model("post")
					m.property(name="fullName", sql="CONCAT(firstName, ' ', lastName)")
					// should not throw
					expect(true).toBeTrue()
				})

			})

		})

	}

}
