/**
 * The transactionIsolation setting (#4059): the isolation level model
 * transactions use when the caller passes no `isolation`. The default stays
 * read_committed; "" sends no isolation attribute, so the engine's or driver's
 * default applies.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("The transactionIsolation setting", () => {

			afterEach(() => {
				g.set(transactionIsolation = "read_committed");
				g.model("tag").deleteAll(where = "name LIKE 'iso-%'", instantiate = false, callbacks = false, transaction = "commit");
			});

			it("defaults to read_committed", () => {
				expect(g.get("transactionIsolation")).toBe("read_committed");
			});

			it("accepts the four levels and an empty string, and rejects anything else", () => {
				var tag = g.model("tag");
				for (var level in ["read_uncommitted", "read_committed", "repeatable_read", "serializable", ""]) {
					tag.$assertTransactionArgs(transaction = "commit", isolation = level);
				}
				var state = {type = ""};
				try {
					tag.$assertTransactionArgs(transaction = "commit", isolation = "snapshot");
				} catch (any e) {
					state.type = e.type;
				}
				expect(state.type).toBe("Wheels.InvalidTransactionIsolation");
			});

			it("writes with an empty transactionIsolation", () => {
				g.set(transactionIsolation = "");
				var tag = g.model("tag").new(name = "iso-empty");
				expect(tag.save(transaction = "commit")).toBeTrue();
				expect(g.model("tag").count(where = "name = 'iso-empty'")).toBe(1);
			});

			it("joins a raw transaction block with an empty transactionIsolation", () => {
				g.set(transactionIsolation = "");
				transaction {
					g.model("tag").create(name = "iso-raw", transaction = "commit");
				}
				expect(g.model("tag").count(where = "name = 'iso-raw'")).toBe(1);
			});

			describe("on MySQL", () => {

				beforeEach(() => {
					request.$isolationSeen = "";
				});

				it("uses the setting when the caller passes no isolation", () => {
					if (g.get("adapterName") != "MySQLModel") {
						skip("@@transaction_isolation is MySQL-only, not `#g.get('adapterName')#`.");
					}
					g.set(transactionIsolation = "serializable");
					g.model("tag").invokeWithTransaction(method = "txnRecordIsolation");
					expect(request.$isolationSeen).toBe("SERIALIZABLE");
				});

				it("lets an explicit isolation argument win over the setting", () => {
					if (g.get("adapterName") != "MySQLModel") {
						skip("@@transaction_isolation is MySQL-only, not `#g.get('adapterName')#`.");
					}
					g.set(transactionIsolation = "serializable");
					g.model("tag").invokeWithTransaction(method = "txnRecordIsolation", isolation = "repeatable_read");
					expect(request.$isolationSeen).toBe("REPEATABLE-READ");
				});

				it("uses the same level as a raw transaction block when the setting is empty", () => {
					if (g.get("adapterName") != "MySQLModel") {
						skip("@@transaction_isolation is MySQL-only, not `#g.get('adapterName')#`.");
					}
					// What the engine/driver gives a transaction that sends no isolation
					// (REPEATABLE-READ on Lucee and BoxLang, READ-COMMITTED through Adobe's
					// MySQL datasource), so compare against it rather than a fixed value.
					var raw = {iso = ""};
					transaction {
						raw.iso = QueryExecute("SELECT @@transaction_isolation AS iso", [], {datasource = g.get("dataSourceName")}).iso;
					}
					g.set(transactionIsolation = "");
					g.model("tag").invokeWithTransaction(method = "txnRecordIsolation");
					expect(request.$isolationSeen).toBe(raw.iso);
				});

			});

		});

	}

}
