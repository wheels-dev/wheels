component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo
		// SQLite stores `c_o_r_e_photos.filedata` as TEXT (populate.cfm) → validationtype "string", so the carve-out is N/A.
		var _isSQLite = CreateObject("component", "wheels.migrator.Migration").init().adapter.adapterName() == "SQLiteModel";

		describe("Binary column property assignment", () => {

			// Photo.fileData maps to a binary (blob/longblob/bytea) column on
			// every adapter. CFML engines surface binary file content
			// differently — Lucee 7 / Adobe expose it as `byte[]` (IsArray=false,
			// IsBinary=true), while BoxLang and some Lucee 6 configurations
			// surface it as a CFML array (IsArray=true). Either shape must
			// reach the JDBC layer; the scalar-column guard in $setProperty
			// must not reject array-shaped values bound for binary columns.

			it("accepts array-shaped binary data without tripping the scalar-column guard", () => {
				if (_isSQLite) return;
				var ctx = { bytes: [137, 80, 78, 71, 13, 10, 26, 10] }
				expect(() => {
					g.model("photo").new(filename = "test.png", fileData = ctx.bytes)
				}).notToThrow(type = "Wheels.PropertyIsIncorrectType")
			})

			it("preserves the binary value on the model when assigned via new()", () => {
				if (_isSQLite) return;
				var ctx = { bytes: [137, 80, 78, 71, 13, 10, 26, 10] }
				var photo = g.model("photo").new(filename = "test.png", fileData = ctx.bytes)
				expect(photo.fileData).toBe(ctx.bytes)
			})

			it("still rejects array values bound to non-binary scalar columns (regression for ##2412)", () => {
				expect(() => {
					g.model("photo").new(filename = ["should", "not", "work"])
				}).toThrow(type = "Wheels.PropertyIsIncorrectType")
			})

			it("still rejects struct values bound to non-binary scalar columns (regression for ##2412)", () => {
				expect(() => {
					g.model("photo").new(filename = {nested = "should not work"})
				}).toThrow(type = "Wheels.PropertyIsIncorrectType")
			})
		})
	}
}
