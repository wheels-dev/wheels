/**
 * Callable proxy target for SshPool.onEach.
 *
 * Lucee 7 tightened `createDynamicProxy` to require a Component (CFC)
 * instance as the first argument — passing a struct with inline closures
 * fails with "Can't cast Complex Object Type Struct to String". This CFC
 * holds the pool reference, host spec, and callback so the parallel task
 * body can live in its own lexical scope (one instance per submitted
 * host, so closure loop-variable capture isn't a concern).
 */
component {

	public SshPoolTask function init(required any pool, required string host, required any callback) {
		variables.pool = arguments.pool;
		variables.host = arguments.host;
		variables.callback = arguments.callback;
		return this;
	}

	/**
	 * java.util.concurrent.Callable#call(). Returns Boolean.TRUE on success;
	 * exceptions propagate to Future.get() as ExecutionException.cause.
	 */
	public any function call() {
		var ssh = variables.pool.getConnection(variables.host);
		variables.callback(ssh, variables.host);
		return javaCast("boolean", true);
	}

}
