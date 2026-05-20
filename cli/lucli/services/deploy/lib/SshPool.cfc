/**
 * SshPool — parallel multi-host fan-out over SshClient.
 *
 * Manages a pool of cached SshClient instances keyed by
 * `user@host:port`. `onEach` dispatches a callback against every host in
 * parallel using a bounded fixed thread pool; `onAny` tries hosts serially
 * until one succeeds; `sequential` runs them in order with no threading.
 *
 * Public surface mirrors FakeSshPool so tests and production code can swap
 * implementations freely:
 *   - onEach(hosts, cb)      parallel fan-out (waits on all; rethrows)
 *   - onAny(hosts, cb)       first-success-wins (rethrows last error)
 *   - sequential(hosts, cb)  serial, in order
 *   - getConnection(spec)    parse + cache lookup for a single host
 *   - close()                close cached clients and shutdown executor
 *
 * Host spec grammar: `user@host:port`, `host:port`, or `host`. Defaults come
 * from `init(defaults)`. Port defaults to 22; user defaults to "root" (same
 * as SshClient).
 */
component {

	/**
	 * @defaults Keys:
	 *           - user                   default "root"
	 *           - port                   default 22
	 *           - privateKey             path to private key file
	 *           - strictHostKeyChecking  default true
	 *           - timeoutMs              default 30000
	 *           - parallelism            thread pool size, capped at 10 (default 5)
	 */
	public SshPool function init(struct defaults = {}) {
		variables.$defaults = {
			user: arguments.defaults.user ?: "root",
			port: arguments.defaults.port ?: 22,
			privateKey: arguments.defaults.privateKey ?: "",
			strictHostKeyChecking: arguments.defaults.strictHostKeyChecking ?: true,
			timeoutMs: arguments.defaults.timeoutMs ?: 30000
		};
		var requested = arguments.defaults.parallelism ?: 5;
		// Cap at 10 — hitting the same LB harder than that tends to tickle
		// per-connection sshd MaxStartups limits rather than speed anything up.
		variables.$parallelism = Min(Max(requested, 1), 10);
		variables.$connections = {};
		variables.$executor = createObject("java", "java.util.concurrent.Executors")
			.newFixedThreadPool(javaCast("int", variables.$parallelism));
		return this;
	}

	/**
	 * Submit one task per host to the executor; block on all futures.
	 *
	 * Exception fidelity: `Future.get()` wraps user exceptions in
	 * ExecutionException. We unwrap the cause (first host that failed wins)
	 * and rethrow so Wheels-layer error handling sees the original type.
	 */
	public void function onEach(required array hosts, required any callback) {
		// Pre-resolve connections on the submitting (CFML) thread. Worker
		// threads launched by the executor don't inherit Lucee's component
		// classloader, so `new cli.lucli...SshClient()` from inside a
		// Callable fails with "cannot load class through its string name".
		// Pre-warming also means struct writes to `$connections` all happen
		// on one thread — no need for cflock around cache insertion.
		for (var host in arguments.hosts) {
			getConnection(host);
		}
		var futures = [];
		// Delegate submission to a helper so each iteration captures `host`
		// and `cb` in its own scope. Closures over loop vars bind to the LAST
		// iteration value on Lucee/Adobe, which is catastrophic for a thread
		// pool — all N tasks would target the final host.
		for (var host in arguments.hosts) {
			arrayAppend(futures, $submit(host, arguments.callback));
		}
		for (var future in futures) {
			try {
				future.get();
			} catch (any e) {
				// Future.get() on a failed Callable throws ExecutionException
				// wrapping the cause. Unwrap it so the caller sees the real
				// SshClient exception (SshClient.SudoNoPassword, etc.).
				if (structKeyExists(e, "cause") && !isNull(e.cause)) {
					throw(object = e.cause);
				}
				rethrow;
			}
		}
	}

	/**
	 * Try hosts one by one; return on first success. If all hosts fail,
	 * rethrow the LAST exception seen (keeps the "primary" error visible when
	 * fallback hosts are less meaningful).
	 */
	public any function onAny(required array hosts, required any callback) {
		if (arrayLen(arguments.hosts) == 0) {
			return;
		}
		var lastError = "";
		var haveError = false;
		for (var host in arguments.hosts) {
			try {
				var ssh = getConnection(host);
				return arguments.callback(ssh, host);
			} catch (any e) {
				lastError = e;
				haveError = true;
			}
		}
		if (haveError) {
			throw(object = lastError);
		}
	}

	/**
	 * Serial execution. No threading, no reordering. Useful when callers need
	 * a predictable execution order (logs, cordoned rollouts).
	 */
	public void function sequential(required array hosts, required any callback) {
		for (var host in arguments.hosts) {
			var ssh = getConnection(host);
			arguments.callback(ssh, host);
		}
	}

	/**
	 * Return a defensive copy of the resolved defaults. Exposes the seeded
	 * `user/port/privateKey/...` struct without requiring a live SSH
	 * connection — the copy guards against external mutation of internal
	 * state.
	 */
	public struct function $defaults() {
		return duplicate(variables.$defaults);
	}

	/**
	 * Parse a host spec and return a cached or newly-opened SshClient.
	 *
	 * NOTE: The connection cache is a plain struct. Writes from submitting
	 * thread are fine; if callers start issuing `getConnection` from inside
	 * `onEach` callbacks (which would be unusual), a `cflock` here would
	 * serialize struct mutation. For the deploy workload — callers resolve
	 * once per host, then re-use — unlocked access is acceptable.
	 */
	public any function getConnection(required string hostSpec) {
		var parsed = $parseSpec(arguments.hostSpec);
		var key = "#parsed.user#@#parsed.host#:#parsed.port#";
		if (structKeyExists(variables.$connections, key)) {
			return variables.$connections[key];
		}
		// NOTE: avoid `client` — Lucee reserved scope name that blows up
		// inside closures with "client scope is not enabled".
		var sc = new modules.wheels.services.deploy.lib.SshClient().init(
			parsed.host,
			{
				user: parsed.user,
				port: parsed.port,
				privateKey: variables.$defaults.privateKey,
				strictHostKeyChecking: variables.$defaults.strictHostKeyChecking,
				timeoutMs: variables.$defaults.timeoutMs
			}
		);
		variables.$connections[key] = sc;
		return sc;
	}

	/**
	 * Close every cached client and shut down the executor.
	 *
	 * `shutdown()` lets in-flight tasks finish — appropriate at end-of-flow.
	 * If you need to abort mid-operation, call `$executor.shutdownNow()`
	 * directly; we don't expose that today since deploy verbs always let
	 * onEach settle before closing.
	 */
	public void function close() {
		for (var key in variables.$connections) {
			try {
				variables.$connections[key].close();
			} catch (any e) {
				// Best-effort cleanup — swallow per-host close errors so one
				// dead TCP connection doesn't strand the rest.
			}
		}
		structClear(variables.$connections);
		if (structKeyExists(variables, "$executor")) {
			variables.$executor.shutdown();
		}
	}

	// -----------------------------------------------------------------------
	// Internals
	// -----------------------------------------------------------------------

	/**
	 * Submit a single (host, callback) pair to the executor. Extracting this
	 * out of the loop is how we avoid the shared-loop-variable closure bug
	 * on Lucee/Adobe: arguments scope gives each call fresh bindings.
	 */
	private any function $submit(required string host, required any cb) {
		// SshPoolTask is a proper CFC — Lucee 7 rejects struct-with-closure
		// targets for createDynamicProxy. Each submission constructs a fresh
		// task instance, sidestepping the shared-loop-variable closure bug.
		var target = new modules.wheels.services.deploy.lib.SshPoolTask(this, arguments.host, arguments.cb);
		var task = createDynamicProxy(target, ["java.util.concurrent.Callable"]);
		return variables.$executor.submit(task);
	}

	/**
	 * Parse `user@host:port`, `host:port`, or `host` into a struct with
	 * defaults from `$defaults`. Keep the grammar tight — no path/url/query
	 * segments; deploy specs are just network endpoints.
	 */
	private struct function $parseSpec(required string spec) {
		var remainder = arguments.spec;
		var user = variables.$defaults.user;
		var port = variables.$defaults.port;

		var atPos = find("@", remainder);
		if (atPos > 0) {
			user = left(remainder, atPos - 1);
			remainder = mid(remainder, atPos + 1, len(remainder) - atPos);
		}

		var colonPos = find(":", remainder);
		if (colonPos > 0) {
			port = val(mid(remainder, colonPos + 1, len(remainder) - colonPos));
			remainder = left(remainder, colonPos - 1);
		}

		return {user: user, host: remainder, port: port};
	}

}
