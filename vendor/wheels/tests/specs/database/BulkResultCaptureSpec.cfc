/**
 * #3653: bulk statements must reach the driver without a generated-key request.
 *
 * A cfquery `result` attribute is what makes Lucee request generated keys
 * (Statement.RETURN_GENERATED_KEYS), and the Oracle driver implements that by appending
 * `RETURNING ROWID INTO ?` to every INSERT. After Oracle's
 * `INSERT ... SELECT ... FROM dual UNION ALL` bulk shape that is a syntax error
 * (ORA-03048), so every insertAll() failed on the Lucee + Oracle legs. Nothing on the
 * bulk paths reads the result or a key, so they now run with `$captureResult = false`,
 * which drops the attribute.
 *
 * The end-to-end check is model/bulkOperationsSpec on the Oracle legs, which are
 * soft-fail and weekly. These pin the contract on every leg.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Bulk statements skip the cfquery result (##3653)", () => {

			it("insertAll() and upsertAll() tell the adapter not to capture a result", () => {
				var authorClass = application.wo.model("author");
				var classData = authorClass.$classData();
				var originalAdapter = classData.adapter;
				var spy = CreateObject("component", "wheels.tests._assets.adapters.QuerySetupSpy");
				classData.adapter = spy;
				try {
					authorClass.insertAll(records = [{firstName = "Spy", lastName = "Insert"}], timestamps = false);
					authorClass.upsertAll(records = [{firstName = "Spy", lastName = "Upsert"}], uniqueBy = "firstName", timestamps = false);
				} finally {
					classData.adapter = originalAdapter;
				}
				expect(ArrayToList(spy.captureResult)).toBe("false,false");
			});

			it("$performQuery returns no result metadata when $captureResult is false", () => {
				var adapter = application.wo.model("author").$classData().adapter;
				var rv = adapter.$performQuery(
					sql = ["SELECT COUNT(*) AS authorCount FROM c_o_r_e_authors"],
					parameterize = false,
					$captureResult = false
				);
				expect(rv.result).toBeStruct();
				expect(StructIsEmpty(rv.result)).toBeTrue();
				// The resultset itself is still returned.
				expect(rv.query.recordCount).toBe(1);
			});

			it("$performQuery keeps the result metadata by default", () => {
				var adapter = application.wo.model("author").$classData().adapter;
				var rv = adapter.$performQuery(
					sql = ["SELECT COUNT(*) AS authorCount FROM c_o_r_e_authors"],
					parameterize = false
				);
				expect(rv.result).toHaveKey("sql");
				expect(rv.query.recordCount).toBe(1);
			});

		});

	}

}
