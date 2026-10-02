/**
 * Model writes inside a raw `transaction {}` block (#4045). Adobe CF rejects a nested
 * cftransaction whose isolation differs from the parent's, and a raw block with no
 * isolation counts as different from the `read_committed` Wheels sends, so these shapes
 * used to throw a Database error on Adobe. The core runner uses transactionMode="none",
 * so every write passes transaction="commit" to take the real (app default) path.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Model writes inside a raw transaction block (##4045)", () => {

			afterEach(() => {
				g.model("tag").deleteAll(where = "name LIKE 'iso4045-%'", transaction = "none")
			})

			it("commits two creates made inside the block", () => {
				var state = {inside = -1}
				transaction {
					g.model("tag").create(name = "iso4045-a1", transaction = "commit")
					g.model("tag").create(name = "iso4045-a2", transaction = "commit")
					state.inside = g.model("tag").count(where = "name LIKE 'iso4045-a%'")
				}
				expect(state.inside).toBe(2)
				expect(g.model("tag").count(where = "name LIKE 'iso4045-a%'")).toBe(2)
			})

			it("rolls back a save when the block rolls back", () => {
				transaction {
					var t = g.model("tag").new(name = "iso4045-rb")
					expect(t.save(transaction = "commit")).toBeTrue()
					transaction action="rollback";
				}
				expect(g.model("tag").count(where = "name = 'iso4045-rb'")).toBe(0)
			})

			it("surfaces the block's own exception and writes nothing", () => {
				var state = {type = ""}
				try {
					transaction {
						g.model("tag").create(name = "iso4045-ex", transaction = "commit")
						Throw(type = "Wheels.Test4045Boom", message = "boom")
					}
				} catch (any e) {
					state.type = e.type
				}
				expect(state.type).toBe("Wheels.Test4045Boom")
				expect(g.model("tag").count(where = "name = 'iso4045-ex'")).toBe(0)
			})

			it("updates a row loaded inside the block", () => {
				var t = g.model("tag").create(name = "iso4045-up", transaction = "commit")
				transaction {
					var loaded = g.model("tag").findByKey(t.id)
					expect(loaded.update(description = "changed", transaction = "commit")).toBeTrue()
				}
				expect(g.model("tag").findByKey(t.id).description).toBe("changed")
			})

			it("never silently drops a caller-chosen isolation", () => {
				// Engines that accept a nested isolation change run it; Adobe refuses with a clear
				// Wheels error instead of the raw Database one, and never retries without it.
				var state = {rv = "", type = ""}
				try {
					transaction {
						state.rv = g.model("tag").invokeWithTransaction(method = "callbackThatReturnsTrue", isolation = "read_committed")
					}
				} catch (any e) {
					state.type = e.type
				}
				expect(state.rv == true || state.type == "Wheels.TransactionIsolationMismatch").toBeTrue("rv=#state.rv# type=#state.type#")
			})

			it("recognises the nested isolation mismatch error loosely", () => {
				var m = g.model("tag")
				expect(m.$isNestedIsolationMismatch({
					message = "Nested cftransaction tag should specify same isolation level as the parent.",
					detail = "A child cftransaction tag cannot use an isolation level different from the parent cftransaction tag."
				})).toBeTrue()
				expect(m.$isNestedIsolationMismatch({message = "NESTED CFTRANSACTION ... ISOLATION", detail = ""})).toBeTrue()
				expect(m.$isNestedIsolationMismatch({message = "Error Executing Database Query.", detail = "Table not found"})).toBeFalse()
				expect(m.$isNestedIsolationMismatch({message = "isolation level not supported", detail = ""})).toBeFalse()
			})

		})

		describe("invokeWithTransaction at the top level (##4045)", () => {

			afterEach(() => {
				g.model("tag").deleteAll(where = "name LIKE 'iso4045-%'", transaction = "none")
			})

			it("still commits and rolls back outside any raw block", () => {
				g.model("tag").create(name = "iso4045-top", transaction = "commit")
				expect(g.model("tag").count(where = "name = 'iso4045-top'")).toBe(1)
				g.model("tag").create(name = "iso4045-toprb", transaction = "rollback")
				expect(g.model("tag").count(where = "name = 'iso4045-toprb'")).toBe(0)
			})

			it("still rejects an unsupported isolation level before opening a transaction", () => {
				expect(() => {
					g.model("tag").invokeWithTransaction(method = "callbackThatReturnsTrue", isolation = "bogus")
				}).toThrow()
			})

		})

	}

}
