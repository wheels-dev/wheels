component extends="wheels.WheelsTest" {

	function run() {
		g = application.wo

		describe("Auto-derived property name casing", () => {
			/*
				Regression coverage for the 2.x -> 3.x property-casing change.

				When a model declares no property() mappings, Wheels derives its
				properties from the database column metadata. Up through the 2.x
				line this preserved the column's original casing, so a column
				named `isHidden` produced the property `isHidden`. A change in the
				3.0 line (aimed at Oracle, whose driver reports columns in a fixed
				case) began force-lowercasing ALL auto-derived property names, so
				`isHidden` became `ishidden` on every engine — breaking
				case-sensitive consumers of serialized model output.

				Wheels now preserves the database's reported column casing, and
				only lowercases on adapters whose database folds unquoted
				identifiers to a non-meaningful uppercase default (Oracle, H2),
				where lowercasing keeps property names sane.

				`c_o_r_e_casepreservation` has an undeclared, mixed-case `isHidden`
				column (see tests/populate.cfm).
			*/
			it("preserves the database column case for undeclared properties", () => {
				var names = g.model("CasePreservation").propertyNames();

				// Databases that preserve the declared identifier case report
				// `isHidden`; lower-folding (Postgres/CockroachDB) and
				// upper-folding-then-lowercased (Oracle/H2) report `ishidden`.
				var preservesCase = ListFindNoCase("SQLiteModel,MySQLModel,MicrosoftSQLServerModel", get("adapterName")) GT 0;
				var expected = preservesCase ? "isHidden" : "ishidden";

				// Case-sensitive membership check — the bug is invisible to a
				// case-insensitive lookup, so ListFind (not ListFindNoCase).
				expect(ListFind(names, expected)).toBeGT(0);
			});
		});
	}

}
