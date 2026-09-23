/**
 * #3647: `create()` with an explicit primary key must work on every database.
 *
 * SQL Server rejects an explicit value for an IDENTITY column unless IDENTITY_INSERT is
 * ON for the table, so `model("RefParent").create(id = 41, ...)` failed there with
 * "Cannot insert explicit value for identity column ... when IDENTITY_INSERT is set to
 * OFF" while every other supported database accepted it. The SQL Server adapter now
 * wraps such an INSERT in a catalog-guarded ON/OFF pair; every other adapter leaves the
 * statement alone.
 *
 * These run against the live datasource on every database; on SQL Server they are the
 * regression test itself. The wrapper's shape is pinned on every leg by
 * database/MicrosoftSQLServerUnitSpec.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("create() with an explicit primary key", () => {

			it("persists the supplied key", () => {
				transaction action="begin" {
					var parent = g.model("RefParent").create(id = 941, name = "Explicit key 941");
					expect(Val(parent.id)).toBe(941);

					var found = g.model("RefParent").findByKey(941);
					expect(IsObject(found)).toBeTrue();
					expect(found.name).toBe("Explicit key 941");
					transaction action="rollback";
				}
			});

			it("still generates a key for the next insert that does not supply one", () => {
				// One transaction means one connection. On SQL Server this proves the
				// explicit insert switched IDENTITY_INSERT back off: while it is on, an
				// INSERT without the identity column fails ("Explicit value must be
				// specified for identity column"). parameterize=false because inlined
				// values run as a plain batch, where the setting outlives the statement;
				// a prepared statement's setting does not survive its execution.
				transaction action="begin" {
					g.model("RefParent").create(id = 942, name = "Explicit key 942", parameterize = false);
					var generated = g.model("RefParent").create(name = "Generated after explicit");
					expect(Val(generated.id)).toBeGT(0);
					expect(Val(generated.id)).notToBe(942);
					expect(g.model("RefParent").count(where = "name = 'Generated after explicit'")).toBe(1);
					transaction action="rollback";
				}
			});

			it("raises a duplicate explicit key and still switches IDENTITY_INSERT off", () => {
				// Only SQL Server has a session setting to leak. Elsewhere a failed
				// statement can abort the surrounding transaction (PostgreSQL), which would
				// make the follow-up insert below meaningless.
				if (g.get("adapterName") != "MicrosoftSQLServerModel") {
					return;
				}
				var state = {error = "", generatedId = 0};
				transaction action="begin" {
					g.model("RefParent").create(id = 943, name = "Explicit key 943");
					try {
						g.model("RefParent").create(id = 943, name = "Duplicate key 943", parameterize = false);
					} catch (any e) {
						// Adobe puts the driver's text in detail; message is the generic
						// "Error Executing Database Query."
						state.error = e.message & " " & e.detail;
					}
					// The trailing OFF has to run even though the INSERT failed; if it
					// did not, this insert on the same connection would fail.
					state.generatedId = g.model("RefParent").create(name = "Generated after duplicate").id;
					transaction action="rollback";
				}
				// The error must surface. A TRY/CATCH + THROW wrapper made Lucee drop it,
				// so the duplicate came back as a successful create().
				expect(state.error).toInclude("PRIMARY KEY");
				expect(Val(state.generatedId)).toBeGT(0);
			});

		});

	}

}
