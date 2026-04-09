component extends="wheels.WheelsTest" {

	function run() {

		describe("$quoteValue()", () => {

			beforeEach(() => {
				adapter = CreateObject("component", "wheels.databaseAdapters.SQLite.SQLiteModel");
			});

			it("wraps string values in single quotes", () => {
				expect(adapter.$quoteValue(str="hello")).toBe("'hello'");
			});

			it("returns numeric values unquoted for integer type", () => {
				expect(adapter.$quoteValue(str="42", type="integer")).toBe("42");
			});

			it("returns numeric values unquoted for float type", () => {
				expect(adapter.$quoteValue(str="3.14", type="float")).toBe("3.14");
			});

			it("returns numeric values unquoted for boolean type", () => {
				expect(adapter.$quoteValue(str="1", type="boolean")).toBe("1");
			});

			it("quotes empty strings even for numeric types", () => {
				expect(adapter.$quoteValue(str="", type="integer")).toBe("''");
			});

			it("escapes single quotes to prevent SQL injection", () => {
				expect(adapter.$quoteValue(str="test' OR '1'='1")).toBe("'test'' OR ''1''=''1'");
			});

			it("escapes multiple single quotes in a value", () => {
				expect(adapter.$quoteValue(str="it's a 'test'")).toBe("'it''s a ''test'''");
			});

			it("handles strings with no single quotes unchanged", () => {
				expect(adapter.$quoteValue(str="normal value")).toBe("'normal value'");
			});

			it("handles a single quote character", () => {
				expect(adapter.$quoteValue(str="'")).toBe("''''");
			});

		});

	}

}
