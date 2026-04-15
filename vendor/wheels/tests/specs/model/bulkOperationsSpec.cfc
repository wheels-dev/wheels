component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("insertAll", () => {

			it("inserts multiple records in a single call", () => {
				transaction action="begin" {
					var records = [
						{firstName: "BulkAlice", lastName: "Anderson"},
						{firstName: "BulkBob", lastName: "Brown"},
						{firstName: "BulkCharlie", lastName: "Clark"}
					];
					var result = g.model("author").insertAll(records=records);

					expect(result.insertedCount).toBe(3);

					// Verify they exist.
					var found = g.model("author").findAll(where="firstname LIKE 'Bulk%'", order="firstname");
					expect(found.recordCount).toBe(3);
					expect(found.firstname[1]).toBe("BulkAlice");
					expect(found.firstname[2]).toBe("BulkBob");
					expect(found.firstname[3]).toBe("BulkCharlie");

					transaction action="rollback";
				}
			});

			it("returns zero count for empty records array", () => {
				var result = g.model("author").insertAll(records=[]);
				expect(result.insertedCount).toBe(0);
			});

			it("throws error when records have inconsistent keys", () => {
				var ctx = {
					records: [
						{firstName: "Alice", lastName: "Anderson"},
						{firstName: "Bob"}
					]
				};
				expect(() => {
					g.model("author").insertAll(records=ctx.records);
				}).toThrow("Wheels.InvalidRecordKeys");
			});

			it("inserts records with auto timestamps", () => {
				transaction action="begin" {
					var records = [
						{code: "BULK-TS-1", name: "TimestampItem1", quantity: 10},
						{code: "BULK-TS-2", name: "TimestampItem2", quantity: 20}
					];
					var result = g.model("bulkItem").insertAll(records=records, timestamps=true);

					expect(result.insertedCount).toBe(2);

					var found = g.model("bulkItem").findAll(where="code LIKE 'BULK-TS-%'", order="code");
					expect(found.recordCount).toBe(2);
					// createdAt should have been auto-populated.
					expect(Len(found.createdAt[1])).toBeGT(0);
					expect(Len(found.updatedAt[1])).toBeGT(0);

					transaction action="rollback";
				}
			});

			it("skips timestamps when timestamps argument is false", () => {
				transaction action="begin" {
					var records = [
						{code: "BULK-NTS-1", name: "NoTimestamp1", quantity: 5}
					];
					var result = g.model("bulkItem").insertAll(records=records, timestamps=false);

					expect(result.insertedCount).toBe(1);

					var found = g.model("bulkItem").findOne(where="code = 'BULK-NTS-1'");
					expect(found).toBeInstanceOf("component");
					expect(found.name).toBe("NoTimestamp1");
					// Timestamps should be empty since the column is nullable and timestamps=false.
					expect(Len(Trim(found.createdAt))).toBe(0, "createdAt should be empty when timestamps=false");
					expect(Len(Trim(found.updatedAt))).toBe(0, "updatedAt should be empty when timestamps=false");

					transaction action="rollback";
				}
			});

			it("handles single record insertion", () => {
				transaction action="begin" {
					var records = [
						{firstName: "SingleBulk", lastName: "Test"}
					];
					var result = g.model("author").insertAll(records=records);

					expect(result.insertedCount).toBe(1);

					var found = g.model("author").findOne(where="firstname = 'SingleBulk'");
					expect(found).toBeInstanceOf("component");
					expect(found.lastName).toBe("Test");

					transaction action="rollback";
				}
			});

		});

		describe("upsertAll", () => {

			it("inserts new records when no conflict exists", () => {
				transaction action="begin" {
					var records = [
						{code: "UPSERT-NEW-1", name: "Item1", quantity: 10},
						{code: "UPSERT-NEW-2", name: "Item2", quantity: 20}
					];
					var result = g.model("bulkItem").upsertAll(records=records, uniqueBy="code");

					expect(result.upsertedCount).toBe(2);

					var found = g.model("bulkItem").findAll(where="code LIKE 'UPSERT-NEW-%'", order="code");
					expect(found.recordCount).toBe(2);
					expect(found.name[1]).toBe("Item1");
					expect(found.name[2]).toBe("Item2");

					transaction action="rollback";
				}
			});

			it("updates existing records on conflict", () => {
				transaction action="begin" {
					// First insert.
					var records = [
						{code: "UPSERT-UPD-1", name: "Original", quantity: 5}
					];
					g.model("bulkItem").upsertAll(records=records, uniqueBy="code");

					// Upsert with updated values.
					var records2 = [
						{code: "UPSERT-UPD-1", name: "Updated", quantity: 99}
					];
					var result = g.model("bulkItem").upsertAll(records=records2, uniqueBy="code");

					expect(result.upsertedCount).toBe(1);

					var found = g.model("bulkItem").findOne(where="code = 'UPSERT-UPD-1'");
					expect(found.name).toBe("Updated");
					expect(found.quantity).toBe(99);

					transaction action="rollback";
				}
			});

			it("returns zero count for empty records array", () => {
				var result = g.model("bulkItem").upsertAll(records=[], uniqueBy="code");
				expect(result.upsertedCount).toBe(0);
			});

			it("throws error for invalid uniqueBy property", () => {
				var ctx = {
					records: [
						{code: "Test", name: "Desc", quantity: 1}
					]
				};
				expect(() => {
					g.model("bulkItem").upsertAll(records=ctx.records, uniqueBy="nonExistentProp");
				}).toThrow("Wheels.InvalidUniqueByProperty");
			});

			it("throws error when records have inconsistent keys", () => {
				var ctx = {
					records: [
						{code: "A", name: "Name1", quantity: 1},
						{code: "B", name: "Name2"}
					]
				};
				expect(() => {
					g.model("bulkItem").upsertAll(records=ctx.records, uniqueBy="code");
				}).toThrow("Wheels.InvalidRecordKeys");
			});

		});

	}

}
