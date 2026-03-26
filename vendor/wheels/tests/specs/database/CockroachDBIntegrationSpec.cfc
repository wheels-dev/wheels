component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("CockroachDB Integration Tests", () => {

			// Guard: only run when connected to CockroachDB
			var migration = CreateObject("component", "wheels.migrator.Migration").init();
			if (migration.adapter.adapterName() != "CockroachDB") return;

			describe("CRUD lifecycle", () => {

				it("creates a record and returns a numeric key", () => {
					transaction action="begin" {
						var author = g.model("author").create(
							firstName = "CRDBTest",
							lastName = "Integration"
						);
						expect(author.key()).toBeNumeric();
						expect(author.key()).toBeGT(0);
						transaction action="rollback";
					}
				});

				it("retrieves a created record by key", () => {
					transaction action="begin" {
						var author = g.model("author").create(
							firstName = "CRDBFind",
							lastName = "ByKey"
						);
						var found = g.model("author").findByKey(author.key());
						expect(found).toBeInstanceOf("component");
						expect(found.firstName).toBe("CRDBFind");
						expect(found.lastName).toBe("ByKey");
						transaction action="rollback";
					}
				});

				it("updates a record and persists the change", () => {
					transaction action="begin" {
						var author = g.model("author").create(
							firstName = "CRDBUpdate",
							lastName = "Before"
						);
						author.update(lastName = "After");
						var reloaded = g.model("author").findByKey(author.key());
						expect(reloaded.lastName).toBe("After");
						transaction action="rollback";
					}
				});

				it("deletes a record", () => {
					transaction action="begin" {
						var author = g.model("author").create(
							firstName = "CRDBDelete",
							lastName = "Me"
						);
						var theKey = author.key();
						author.delete();
						var gone = g.model("author").findByKey(theKey);
						expect(gone).toBeFalse();
						transaction action="rollback";
					}
				});
			});

			describe("Boolean handling", () => {

				it("stores and retrieves true as a CFML boolean", () => {
					transaction action="begin" {
						var record = g.model("sqlType").create(booleanType = true);
						var found = g.model("sqlType").findByKey(record.key());
						expect(found.booleanType).toBeBoolean();
						expect(found.booleanType).toBeTrue();
						transaction action="rollback";
					}
				});

				it("stores and retrieves false as a CFML boolean", () => {
					transaction action="begin" {
						var record = g.model("sqlType").create(booleanType = false);
						var found = g.model("sqlType").findByKey(record.key());
						expect(found.booleanType).toBeBoolean();
						expect(found.booleanType).toBeFalse();
						transaction action="rollback";
					}
				});
			});

			describe("Identity select", () => {

				it("assigns unique increasing keys to sequential inserts", () => {
					transaction action="begin" {
						var a1 = g.model("author").create(firstName = "CRDB1", lastName = "Seq");
						var a2 = g.model("author").create(firstName = "CRDB2", lastName = "Seq");
						var a3 = g.model("author").create(firstName = "CRDB3", lastName = "Seq");
						expect(a1.key()).toBeNumeric();
						expect(a2.key()).toBeNumeric();
						expect(a3.key()).toBeNumeric();
						expect(a2.key()).toBeGT(a1.key());
						expect(a3.key()).toBeGT(a2.key());
						transaction action="rollback";
					}
				});
			});

			describe("FindAll", () => {

				it("returns a query object with records", () => {
					var authors = g.model("author").findAll();
					expect(authors).toBeQuery();
					expect(authors.recordCount).toBeGT(0);
				});
			});
		});
	}

}
