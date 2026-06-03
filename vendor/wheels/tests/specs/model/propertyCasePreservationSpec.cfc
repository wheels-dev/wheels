component extends="wheels.WheelsTest" {

	function run() {
		g = application.wo

		// Regression for the 3.0-era force-lowercasing of auto-derived property names (#2852).
		describe("Auto-derived property name casing", () => {
			it("preserves the database column case for undeclared properties", () => {
				// c_o_r_e_casepreservation has an undeclared, mixed-case `isHidden` column (see populate.cfm)
				var names = g.model("CasePreservation").propertyNames();

				// preserve-case engines report `isHidden`; lower/upper-folding engines report `ishidden`
				var preservesCase = ListFindNoCase("SQLiteModel,MySQLModel,MicrosoftSQLServerModel", get("adapterName")) GT 0;
				var expected = preservesCase ? "isHidden" : "ishidden";

				// case-sensitive: the regression is invisible to ListFindNoCase
				expect(ListFind(names, expected)).toBeGT(0);
			});
		});
	}

}
