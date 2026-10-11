/**
 * A request that ends with `abort` inside a Wheels transaction (invokeWithTransaction(), a nested
 * call that joins it, or a savepoint unit) leaves none of the transaction's writes behind, and a
 * transaction that completes normally is unaffected. Each scenario runs as its own HTTP request
 * through $testClient (TransactionAbortProbe controller, route in vendor/wheels/tests/routes.cfm),
 * since an abort ends the request it runs in. Each aborting scenario also checks a marker set right
 * before the abort, so it can't pass because the request never reached the write.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.g = application.wo;
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
		try {
			variables.migration.dropTable("c_o_r_e_txnabortprobes");
		} catch (any e) {
		}
		var t = variables.migration.createTable(name = "c_o_r_e_txnabortprobes");
		t.string(columnNames = "marker");
		t.create();
		StructDelete(application.wheels.models, "TransactionAbortProbe");
	}

	function afterAll() {
		try {
			variables.migration.dropTable("c_o_r_e_txnabortprobes");
		} catch (any e) {
		}
		StructDelete(application.wheels.models, "TransactionAbortProbe");
	}

	function newMarker(required string scenario) {
		return arguments.scenario & Left(Replace(CreateUUID(), "-", "", "all"), 10);
	}

	// Runs a scenario in its own request; returns its status code.
	function runScenario(required string scenario, required string marker) {
		var tc = $testClient();
		tc.get("/_txnabort/run?scenario=#arguments.scenario#&marker=#arguments.marker#");
		return tc.statusCode();
	}

	function rowsFor(required string marker) {
		return variables.g.model("transactionAbortProbe").count(where = "marker LIKE '#arguments.marker#%'");
	}

	function reachedAbort(required string marker) {
		return StructKeyExists(server, "wheelsTxnAbortProbe_" & arguments.marker);
	}

	function run() {

		describe("A request that ends with abort inside a Wheels transaction", () => {

			it("leaves none of the transaction's writes", () => {
				var marker = newMarker("abort");
				expect(runScenario("abort", marker)).toBe(200);
				expect(reachedAbort(marker)).toBeTrue("the request never reached the write before the abort");
				expect(rowsFor(marker)).toBe(0);
			});

			it("leaves none of them when the abort is in a nested call that joins the transaction", () => {
				var marker = newMarker("nested");
				expect(runScenario("nestedAbort", marker)).toBe(200);
				expect(reachedAbort(marker & "-inner")).toBeTrue("the request never reached the write before the abort");
				expect(rowsFor(marker)).toBe(0);
			});

			it("leaves none of them when the abort is in a savepoint unit", () => {
				var marker = newMarker("savepoint");
				expect(runScenario("savepointAbort", marker)).toBe(200);
				expect(reachedAbort(marker & "-inner")).toBeTrue("the request never reached the write before the abort");
				expect(rowsFor(marker)).toBe(0);
			});

		});

		describe("A Wheels transaction that completes normally", () => {

			it("keeps its writes", () => {
				var marker = newMarker("commit");
				expect(runScenario("commit", marker)).toBe(200);
				expect(rowsFor(marker)).toBe(1);
			});

			it("keeps the outer write when a savepoint unit returns false", () => {
				var marker = newMarker("savepointFalse");
				expect(runScenario("savepointFalse", marker)).toBe(200);
				expect(rowsFor(marker & "-outer")).toBe(1);
				expect(rowsFor(marker & "-inner")).toBe(0);
			});

		});

	}

}
