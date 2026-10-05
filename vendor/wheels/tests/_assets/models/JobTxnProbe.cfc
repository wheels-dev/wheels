/**
 * Backs jobDurableEnqueueSpec: methods run through invokeWithTransaction() that enqueue a job
 * (queue = the marker) and then commit, return false, throw, or open a savepoint unit.
 * It sits on the authors table only so it has a model to run transactions through; it writes
 * no rows.
 */
component extends="Model" {

	function config() {
		table("c_o_r_e_authors");
	}

	public boolean function enqueueThenReturn(required string marker, required boolean outcome, any transactional = false) {
		new wheels.tests._assets.jobs.ProbeJob().enqueue(data = {}, queue = arguments.marker, transactional = arguments.transactional);
		return arguments.outcome;
	}

	// saves a tag first (queuing its commit callbacks), then enqueues a durable job
	public boolean function saveTagThenEnqueue(required string marker, required boolean outcome) {
		model("tag").create(name = arguments.marker, transaction = "commit");
		new wheels.tests._assets.jobs.ProbeJob().enqueue(data = {}, queue = arguments.marker, transactional = false);
		return arguments.outcome;
	}

	public boolean function enqueueThenThrow(required string marker) {
		new wheels.tests._assets.jobs.ProbeJob().enqueue(data = {}, queue = arguments.marker, transactional = false);
		Throw(type = "JobTxnProbe.Boom", message = "boom");
	}

	public boolean function enqueueWithClassDefault(required string marker) {
		new wheels.tests._assets.jobs.DurableProbeJob().enqueue(data = {}, queue = arguments.marker);
		return false;
	}

	// the outer transaction commits; a savepoint unit inside it enqueues and returns false
	public boolean function outerThenSavepointFalse(required string marker, any transactional = false) {
		this.invokeWithTransaction(method = "enqueueThenReturn", transaction = "savepoint", marker = arguments.marker, outcome = false, transactional = arguments.transactional);
		return true;
	}

	// a savepoint unit enqueues and rolls back, then the outer transaction rolls back too
	public boolean function outerFalseAfterSavepointFalse(required string marker) {
		this.invokeWithTransaction(method = "enqueueThenReturn", transaction = "savepoint", marker = arguments.marker, outcome = false);
		return false;
	}

	// nested invokeWithTransaction() joins (alreadyopen); the outer one rolls back
	public boolean function outerFalseAfterNested(required string marker) {
		this.invokeWithTransaction(method = "enqueueThenReturn", marker = arguments.marker, outcome = true);
		return false;
	}

}
