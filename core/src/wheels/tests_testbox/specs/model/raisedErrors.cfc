component extends="testbox.system.BaseSpec" {

	function run() {

		g = application.wo

		describe("Tests that raisedErrors", () => {

			it("throws table not found error", () => {
				expect(function() {
					g.model("table_not_found")
				}).toThrow("Wheels.TableNotFound")
			})

			it("throws no primary key error", () => {
				expect(function() {
					g.model("noPrimaryKey")
				}).toThrow("Wheels.NoPrimaryKey")
			})

			it("throws bykey methods with key argument key error", () => {
				post = g.model("post")

				expect(function() {
					post.deleteByKey(key="1,2")
				}).toThrow("Wheels.InvalidArgumentValue")

				expect(function() {
					post.findByKey(key="1,2")
				}).toThrow("Wheels.InvalidArgumentValue")

				expect(function() {
					post.updateByKey(key="1,2", title="testing")
				}).toThrow("Wheels.InvalidArgumentValue")
			})

			it("throws error when value cannot be determined in where clause", () => {
				expect(function() {
					g.model("user").count(where="username = tony")
				}).toThrow("Wheels.QueryParamValue")
			})

			it("throws error for invalid select column", () => {
				expect(function() {
					g.model("user").findAll(select="id,email,firstname,lastname,createdat,foo")
				}).toThrow("Wheels.ColumnNotFound")
			})
		})
	}
}