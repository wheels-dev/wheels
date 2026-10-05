/**
 * enqueue(transactional = false), or a job class with this.transactional = false, writes the job
 * after the outermost Wheels-managed transaction resolves, whether it commits or rolls back, so a
 * failure notice or an audit record survives the rollback. With no transaction open it's written
 * immediately, and the default (transactional = true) still joins the transaction. The core test
 * runner sets transactionMode = "none", so these specs pass `transaction` explicitly.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.g = application.wo;
		// the job store exists before any transaction
		new wheels.tests._assets.jobs.ProbeJob().enqueue(data = {}, queue = "durable_warmup");
	}

	function deleteDurableJobs() {
		QueryExecute("DELETE FROM wheels_jobs WHERE queue LIKE 'durable_%'", [], {datasource = variables.g.get("dataSourceName")});
	}

	function jobCount(required string queue) {
		return QueryExecute(
			"SELECT COUNT(*) AS n FROM wheels_jobs WHERE queue = :q",
			{q = arguments.queue},
			{datasource = variables.g.get("dataSourceName")}
		).n;
	}

	function probe() {
		return variables.g.model("jobTxnProbe");
	}

	function errorOf(required any callback) {
		var state = {type = ""};
		var target = arguments.callback;
		try {
			target();
		} catch (any e) {
			state.type = e.type;
		}
		return state.type;
	}

	function run() {

		describe("Durable job enqueue", () => {

			afterEach(() => {
				deleteDurableJobs();
			});

			describe("A job enqueued with transactional = false", () => {

				it("is written once the transaction commits", () => {
					probe().invokeWithTransaction(method = "enqueueThenReturn", transaction = "commit", marker = "durable_commit", outcome = true);
					expect(jobCount("durable_commit")).toBe(1);
				});

				it("is still written when the transaction rolls back", () => {
					probe().invokeWithTransaction(method = "enqueueThenReturn", transaction = "commit", marker = "durable_false", outcome = false);
					probe().invokeWithTransaction(method = "enqueueThenReturn", transaction = "rollback", marker = "durable_rollback", outcome = true);
					expect(jobCount("durable_false")).toBe(1);
					expect(jobCount("durable_rollback")).toBe(1);
				});

				it("is still written when the transaction's method throws", () => {
					expect(errorOf(() => probe().invokeWithTransaction(method = "enqueueThenThrow", transaction = "commit", marker = "durable_throw"))).toBe("JobTxnProbe.Boom");
					expect(jobCount("durable_throw")).toBe(1);
				});

				it("is still written when a savepoint unit rolls back", () => {
					probe().invokeWithTransaction(method = "outerThenSavepointFalse", transaction = "commit", marker = "durable_sp");
					probe().invokeWithTransaction(method = "outerFalseAfterSavepointFalse", transaction = "commit", marker = "durable_sp_both");
					expect(jobCount("durable_sp")).toBe(1);
					expect(jobCount("durable_sp_both")).toBe(1);
				});

				it("is written when the outermost transaction rolls back after a nested one joined it", () => {
					probe().invokeWithTransaction(method = "outerFalseAfterNested", transaction = "commit", marker = "durable_nested");
					expect(jobCount("durable_nested")).toBe(1);
				});

				it("follows a job class's this.transactional = false default", () => {
					probe().invokeWithTransaction(method = "enqueueWithClassDefault", transaction = "commit", marker = "durable_classdefault");
					expect(jobCount("durable_classdefault")).toBe(1);
				});

				it("is written immediately when no transaction is open", () => {
					var result = new wheels.tests._assets.jobs.ProbeJob().enqueue(data = {}, queue = "durable_none", transactional = false);
					expect(result.persisted).toBeTrue();
					expect(jobCount("durable_none")).toBe(1);
				});

			});

			describe("The transactional = true default", () => {

				it("still rolls the job back with the transaction", () => {
					probe().invokeWithTransaction(method = "enqueueThenReturn", transaction = "commit", marker = "durable_default_false", outcome = false, transactional = true);
					probe().invokeWithTransaction(method = "enqueueThenReturn", transaction = "commit", marker = "durable_default_true", outcome = true, transactional = "");
					expect(jobCount("durable_default_false")).toBe(0);
					expect(jobCount("durable_default_true")).toBe(1);
				});

				it("drops a job from a savepoint unit that rolls back", () => {
					probe().invokeWithTransaction(method = "outerThenSavepointFalse", transaction = "commit", marker = "durable_sp_ctrl", transactional = true);
					expect(jobCount("durable_sp_ctrl")).toBe(0);
				});

			});

			describe("Choosing the transaction a durable job waits for", () => {

				it("is the outermost open Wheels-managed transaction", () => {
					var job = new wheels.tests._assets.jobs.ProbeJob();
					var saved = {
						stack = StructKeyExists(request.wheels, "$txnOwnerStack") ? request.wheels.$txnOwnerStack : "",
						callbacks = StructKeyExists(request.wheels, "$txnCallbacks") ? request.wheels.$txnCallbacks : ""
					};
					var picked = {};
					try {
						request.wheels.$txnCallbacks = {
							outerKey = {real = true, queue = []},
							innerKey = {real = true, queue = []},
							foreignKey = {real = false, foreign = true, queue = []}
						};
						request.wheels.$txnOwnerStack = ["foreignKey", "outerKey", "innerKey"];
						picked.outer = job.$outermostWheelsTransaction();
						request.wheels.$txnOwnerStack = [];
						picked.none = job.$outermostWheelsTransaction();
					} finally {
						restoreTransactionState(saved);
					}
					expect(picked.outer).toBe("outerKey");
					expect(picked.none).toBe("");
				});

			});


		});

	}

	function restoreTransactionState(required struct saved) {
		if (IsSimpleValue(arguments.saved.stack)) {
			StructDelete(request.wheels, "$txnOwnerStack");
		} else {
			request.wheels.$txnOwnerStack = arguments.saved.stack;
		}
		if (IsSimpleValue(arguments.saved.callbacks)) {
			StructDelete(request.wheels, "$txnCallbacks");
		} else {
			request.wheels.$txnCallbacks = arguments.saved.callbacks;
		}
	}

}
