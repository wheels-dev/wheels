component extends="wheels.WheelsTest" {

	/*
	 * Since 10.2.7 MariaDB reports column defaults as SQL expressions: a nullable
	 * column with no default comes back as the text NULL, and a string default as
	 * a quoted literal ('draft'). Wheels read those as real defaults, so
	 * validatesPresenceOf was skipped for any unset nullable column on create
	 * (#3927). The MySQL adapter now normalizes them on MariaDB only.
	 */
	function run() {

		g = application.wo

		describe("MariaDB column default normalization", () => {

			beforeEach(() => {
				adapter = CreateObject("component", "wheels.databaseAdapters.MySQL.MySQLModel");
			});

			it("treats an unquoted NULL as no default", () => {
				expect(adapter.$normalizeMariaDBColumnDefault("NULL")).toBe("");
			});

			it("keeps a literal string default 'NULL' as the text NULL", () => {
				expect(adapter.$normalizeMariaDBColumnDefault("'NULL'")).toBe("NULL");
			});

			it("unquotes a string default and its doubled quotes", () => {
				expect(adapter.$normalizeMariaDBColumnDefault("'draft'")).toBe("draft");
				expect(adapter.$normalizeMariaDBColumnDefault("'it''s'")).toBe("it's");
				expect(adapter.$normalizeMariaDBColumnDefault("''")).toBe("");
			});

			it("leaves numbers and other expressions as they are", () => {
				expect(adapter.$normalizeMariaDBColumnDefault("0")).toBe("0");
				expect(adapter.$normalizeMariaDBColumnDefault("1.25")).toBe("1.25");
				expect(adapter.$normalizeMariaDBColumnDefault("current_timestamp()")).toBe("current_timestamp()");
				expect(adapter.$normalizeMariaDBColumnDefault("b'0'")).toBe("b'0'");
				expect(adapter.$normalizeMariaDBColumnDefault("")).toBe("");
			});

			it("applies only to MariaDB 10.2.7 and later", () => {
				expect(adapter.$isExpressionDefaultMariaDB("MySQL", "11.4.13-MariaDB-ubu2404")).toBeTrue();
				expect(adapter.$isExpressionDefaultMariaDB("MariaDB", "10.2.7")).toBeTrue();
				expect(adapter.$isExpressionDefaultMariaDB("MySQL", "10.2.6-MariaDB")).toBeFalse();
				expect(adapter.$isExpressionDefaultMariaDB("MySQL", "10.1.48-MariaDB")).toBeFalse();
				expect(adapter.$isExpressionDefaultMariaDB("MySQL", "8.4.0")).toBeFalse();
				expect(adapter.$isExpressionDefaultMariaDB("MySQL", "9.7.0")).toBeFalse();
			});
		});

		describe("Column defaults read from a MySQL-family database", () => {

			beforeEach(() => {
				isMySQLFamily = CompareNoCase(CreateObject("component", "wheels.migrator.Migration").init().adapter.adapterName(), "MySQL") == 0;
			});

			it("reads a string default without SQL quotes", () => {
				if (!isMySQLFamily) skip("needs a MySQL or MariaDB database");
				expect(g.model("post").$propertyInfo("status").columnDefault).toBe("draft");
			});

			it("reports no default for a nullable column without one", () => {
				if (!isMySQLFamily) skip("needs a MySQL or MariaDB database");
				expect(g.model("tag").$propertyInfo("name").columnDefault).toBe("");
			});
		});
	}

}
