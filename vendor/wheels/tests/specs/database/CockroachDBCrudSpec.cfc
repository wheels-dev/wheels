component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("CockroachDB CRUD Tests", () => {

			// Guard: only run when connected to CockroachDB
			var migration = CreateObject("component", "wheels.migrator.Migration").init();
			if (migration.adapter.adapterName() != "CockroachDB") return;

			describe("Create", () => {

				it("returns a model object with a numeric key", () => {
					transaction action="begin" {
						var author = g.model("author").create(firstName = "CRDBCrud", lastName = "Create");
						expect(author).toBeInstanceOf("author");
						expect(author.key()).toBeNumeric();
						expect(author.key()).toBeGT(0);
						transaction action="rollback";
					}
				});

				it("generates unique keys for sequential inserts", () => {
					transaction action="begin" {
						var a1 = g.model("author").create(firstName = "Seq1", lastName = "Test");
						var a2 = g.model("author").create(firstName = "Seq2", lastName = "Test");
						expect(a1.key()).toBeNumeric();
						expect(a2.key()).toBeNumeric();
						expect(a2.key()).notToBe(a1.key());
						transaction action="rollback";
					}
				});
			});

			describe("Read", () => {

				it("findFirst returns a valid record without assuming ID value", () => {
					var first = g.model("author").findFirst();
					expect(first).toBeInstanceOf("author");
					expect(first.key()).toBeNumeric();
					expect(first.key()).toBeGT(0);
				});

				it("findLastOne returns a valid record without assuming ID value", () => {
					var last = g.model("author").findLastOne();
					expect(last).toBeInstanceOf("author");
					expect(last.key()).toBeNumeric();
					expect(last.key()).toBeGT(0);
				});

				it("findAll returns query with records", () => {
					var authors = g.model("author").findAll();
					expect(authors).toBeQuery();
					expect(authors.recordCount).toBeGT(0);
				});

				it("findAll with maxrows limits results", () => {
					var authors = g.model("author").findAll(maxRows = 3);
					expect(authors).toBeQuery();
					expect(authors.recordCount).toBeLTE(3);
				});

				it("findOneByXXX works with dynamic finders", () => {
					var author = g.model("author").findOneByLastName("Djurner");
					expect(author).toBeInstanceOf("author");
					expect(author.firstName).toBe("Per");
				});
			});

			describe("Update", () => {

				it("updateAll updates records and returns count", () => {
					transaction action="begin" {
						var count = g.model("author").findAll().recordCount;
						var updated = g.model("author").updateAll(lastName = "Temp");
						expect(updated).toBeNumeric();
						expect(updated).toBe(count);
						transaction action="rollback";
					}
				});

				it("single record update persists", () => {
					transaction action="begin" {
						var author = g.model("author").create(firstName = "Upd", lastName = "Before");
						author.update(lastName = "After");
						var reloaded = g.model("author").findByKey(author.key());
						expect(reloaded.lastName).toBe("After");
						transaction action="rollback";
					}
				});
			});

			describe("Delete", () => {

				it("deleteAll removes records and returns count", () => {
					transaction action="begin" {
						var before = g.model("tag").findAll().recordCount;
						g.model("tag").deleteAll();
						var after = g.model("tag").findAll().recordCount;
						expect(after).toBe(0);
						transaction action="rollback";
					}
				});

				it("single record delete removes from database", () => {
					transaction action="begin" {
						var author = g.model("author").create(firstName = "Del", lastName = "Me");
						var theKey = author.key();
						author.delete();
						var gone = g.model("author").findByKey(theKey);
						expect(gone).toBeFalse();
						transaction action="rollback";
					}
				});
			});

			describe("Ordering", () => {

				it("findAll with order sorts correctly", () => {
					var authors = g.model("author").findAll(order = "lastName ASC");
					expect(authors).toBeQuery();
					expect(authors.recordCount).toBeGT(0);
					// Verify first record is alphabetically first
					if (authors.recordCount > 1) {
						expect(authors.lastName[1] LTE authors.lastName[2]).toBeTrue();
					}
				});

				it("findAll with pagination returns correct page", () => {
					var page1 = g.model("author").findAll(page = 1, perPage = 3, order = "lastName ASC");
					var page2 = g.model("author").findAll(page = 2, perPage = 3, order = "lastName ASC");
					expect(page1).toBeQuery();
					expect(page1.recordCount).toBeLTE(3);
					expect(page2).toBeQuery();
				});
			});
		});
	}

}
