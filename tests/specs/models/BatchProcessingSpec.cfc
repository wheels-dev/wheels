component extends="wheels.WheelsTest" {

	function run() {

		describe("findEach()", () => {

			it("iterates all records", () => {
				var result = {count = 0};
				model("author").findEach(
					order = "id",
					callback = function(record) {
						result.count++;
					}
				);
				var total = model("author").count();
				expect(result.count).toBe(total);
			})

			it("respects custom batchSize", () => {
				var result = {count = 0};
				model("author").findEach(
					order = "id",
					batchSize = 3,
					callback = function(record) {
						result.count++;
					}
				);
				expect(result.count).toBe(model("author").count());
			})

			it("passes model objects to the callback", () => {
				var result = {receivedObject = false};
				model("author").findEach(
					order = "id",
					batchSize = 2,
					callback = function(record) {
						if (IsObject(record) AND StructKeyExists(record, "firstName")) {
							result.receivedObject = true;
						}
					}
				);
				expect(result.receivedObject).toBeTrue();
			})

			it("filters with a where clause", () => {
				var result = {count = 0};
				model("author").findEach(
					where = "lastName = 'Djurner'",
					order = "id",
					callback = function(record) {
						result.count++;
					}
				);
				expect(result.count).toBe(1);
			})

			it("handles no matching records", () => {
				var result = {count = 0};
				model("author").findEach(
					where = "lastName = 'NonExistent'",
					order = "id",
					callback = function(record) {
						result.count++;
					}
				);
				expect(result.count).toBe(0);
			})

		})

		describe("findInBatches()", () => {

			it("processes all records across batches", () => {
				var result = {totalRecords = 0};
				model("author").findInBatches(
					order = "id",
					batchSize = 3,
					callback = function(records) {
						result.totalRecords += records.recordcount;
					}
				);
				expect(result.totalRecords).toBe(model("author").count());
			})

			it("creates the correct number of batches", () => {
				var result = {batchCount = 0};
				var authorCount = model("author").count();
				model("author").findInBatches(
					order = "id",
					batchSize = 3,
					callback = function(records) {
						result.batchCount++;
					}
				);
				expect(result.batchCount).toBe(Ceiling(authorCount / 3));
			})

			it("returns query objects by default", () => {
				var result = {receivedQuery = false};
				model("author").findInBatches(
					order = "id",
					batchSize = 5,
					callback = function(records) {
						if (IsQuery(records)) {
							result.receivedQuery = true;
						}
					}
				);
				expect(result.receivedQuery).toBeTrue();
			})

			it("produces correct batch sizes", () => {
				var result = {sizes = []};
				model("author").findInBatches(
					order = "id",
					batchSize = 4,
					callback = function(records) {
						ArrayAppend(result.sizes, records.recordcount);
					}
				);
				expect(result.sizes[1]).toBe(4);
				expect(result.sizes[2]).toBe(4);
				var authorCount = model("author").count();
				var remainder = authorCount MOD 4;
				if (remainder GT 0) {
					expect(result.sizes[ArrayLen(result.sizes)]).toBe(remainder);
				}
			})

			it("filters with a where clause", () => {
				var result = {totalRecords = 0};
				model("author").findInBatches(
					where = "lastName = 'Djurner'",
					order = "id",
					batchSize = 10,
					callback = function(records) {
						result.totalRecords += records.recordcount;
					}
				);
				expect(result.totalRecords).toBe(1);
			})

			it("handles no matching records", () => {
				var result = {batchCount = 0};
				model("author").findInBatches(
					where = "lastName = 'NonExistent'",
					order = "id",
					callback = function(records) {
						result.batchCount++;
					}
				);
				expect(result.batchCount).toBe(0);
			})

		})

	}
}
