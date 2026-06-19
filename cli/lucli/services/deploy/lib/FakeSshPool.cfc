/**
 * In-memory test double for SshPool.
 *
 * Records every .run() / .upload() / etc. call for later inspection via .calls().
 * Returns scripted results when configured via .expect(host, cmd, result); otherwise
 * returns {exitCode: 0, stdout: "", stderr: "", durationMs: 0}.
 *
 * Strict mode throws on any command that wasn't explicitly expected — useful for
 * locking down the exact sequence a Cli verb emits.
 */
component {

	public FakeSshPool function init(struct opts = {}) {
		variables.strict = arguments.opts.strict ?: false;
		variables.calls = [];
		variables.expectations = {};
		variables.connectFailures = {};
		// Resolved-secret values to scrub from RemoteExecutionFailed command
		// summaries (#3159). Mirrors SshClient — seeded empty, populated via
		// $setSecretValues.
		variables.$secretValues = [];
		return this;
	}

	/**
	 * Scripted result for a (host, cmd) pair. Beyond the usual
	 * {exitCode, stdout, stderr} shape, a result containing a
	 * `transportError` key makes the fake's run() THROW that message
	 * regardless of opts.raise — modeling a dead cached connection whose
	 * startSession() fails inside the real SshClient.run (a transport
	 * failure is a thrown Java exception, never an exit code, so
	 * {raise: false} cannot suppress it).
	 */
	public void function expect(required string host, required string cmd, required struct result) {
		variables.expectations["#arguments.host#|#arguments.cmd#"] = arguments.result;
	}

	/**
	 * Script a transport-level connection failure for a host — models the
	 * real SshPool.getConnection, whose eager SshClient.init connect throws
	 * on an unreachable host. Mirrored semantics per entry point:
	 *   - onEach pre-resolves EVERY host before running any task, so one
	 *     dead host aborts the whole fan-out with zero commands executed;
	 *   - sequential resolves lazily, so earlier hosts have already run;
	 *   - onAny catches per host and tries the next.
	 */
	public void function failConnection(required string host, string message = "") {
		variables.connectFailures[arguments.host] = len(arguments.message)
			? arguments.message
			: "Connection refused: " & arguments.host & " (scripted transport failure)";
	}

	public array function calls() { return variables.calls; }
	public void function reset() { arrayClear(variables.calls); }

	public void function onEach(required array hosts, required any callback) {
		// Mirror real SshPool.onEach: connections are pre-resolved for EVERY
		// host on the submitting thread before any task runs, so a single
		// unreachable host aborts the whole fan-out before any command
		// executes anywhere.
		for (var host in arguments.hosts) {
			$resolveOrThrow(host);
		}
		for (var host in arguments.hosts) {
			var ssh = $makeFakeSsh(host);
			arguments.callback(ssh, host);
		}
	}

	public any function onAny(required array hosts, required any callback) {
		// Mirror real SshPool.onAny: serial, first success wins, per-host
		// failures swallowed, last error rethrown if every host fails.
		if (arrayLen(arguments.hosts) == 0) return;
		var state = {lastError: "", haveError: false};
		for (var host in arguments.hosts) {
			try {
				$resolveOrThrow(host);
				var ssh = $makeFakeSsh(host);
				return arguments.callback(ssh, host);
			} catch (any e) {
				state.lastError = e;
				state.haveError = true;
			}
		}
		if (state.haveError) {
			throw(object = state.lastError);
		}
	}

	public void function sequential(required array hosts, required any callback) {
		// Mirror real SshPool.sequential: connections resolve lazily per
		// host, in order — earlier hosts have already executed when a later
		// host's connect fails.
		for (var host in arguments.hosts) {
			$resolveOrThrow(host);
			var ssh = $makeFakeSsh(host);
			arguments.callback(ssh, host);
		}
	}

	private void function $resolveOrThrow(required string host) {
		if (structKeyExists(variables.connectFailures, arguments.host)) {
			throw(
				type = "FakeSshPool.ConnectionFailure",
				message = variables.connectFailures[arguments.host]
			);
		}
	}

	// Closure accessors — closures can't reach variables scope directly on Adobe.
	public array function $accessCalls() { return variables.calls; }
	public struct function $accessExpectations() { return variables.expectations; }
	public boolean function $accessStrict() { return variables.strict; }

	/**
	 * Mirror SshClient.$raiseRemoteFailure — same throw type / message shape /
	 * detail-trim behavior so tests can assert one contract regardless of
	 * which pool the deploy layer is talking to. Regression #2696.
	 *
	 * MIRROR: SshClient.$raiseRemoteFailure (and $setSecretValues /
	 * $redactSecrets) is the source of truth. If you change the trim limits,
	 * throw type, message template, or redaction behavior there, update these
	 * methods in lockstep. We don't share the helper because FakeSshPool is a
	 * test double that should not import the real SSH client.
	 *
	 * Resolved secret values registered via $setSecretValues are scrubbed from
	 * the command summary BEFORE the trim so a boundary value can't partially
	 * leak (#3159).
	 */
	public void function $raiseRemoteFailure(
		required string host,
		required string cmd,
		required struct result
	) {
		var stderr = arguments.result.stderr ?: "";
		if (len(stderr) > 500) {
			stderr = left(stderr, 500) & "…";
		}
		var cmdSummary = $redactSecrets(arguments.cmd);
		if (len(cmdSummary) > 200) {
			cmdSummary = left(cmdSummary, 200) & "…";
		}
		throw(
			type = "Wheels.Deploy.RemoteExecutionFailed",
			message = "Remote command failed on " & arguments.host
				& " (exit " & arguments.result.exitCode & "): " & cmdSummary,
			detail = stderr
		);
	}

	/**
	 * Register the set of resolved secret values to redact from
	 * RemoteExecutionFailed command summaries (#3159).
	 *
	 * MIRROR: keep byte-identical with SshClient.$setSecretValues.
	 */
	public void function $setSecretValues(required array values) {
		variables.$secretValues = arguments.values;
	}

	/**
	 * Replace every occurrence of each registered secret value with
	 * [REDACTED]. Empty and trivially short values are skipped so they can't
	 * mangle unrelated text. A value may appear multiple times (#3159).
	 *
	 * MIRROR: keep byte-identical with SshClient.$redactSecrets.
	 */
	public string function $redactSecrets(required string text) {
		var out = arguments.text;
		var values = variables.$secretValues ?: [];
		for (var v in values) {
			if (isSimpleValue(v) && len(v) >= 4) {
				out = replace(out, v, "[REDACTED]", "all");
			}
		}
		return out;
	}

	private any function $makeFakeSsh(required string host) {
		var pool = this;
		return {
			run: function(cmd, opts = {}) {
				arrayAppend(pool.$accessCalls(), {host: host, cmd: cmd, opts: opts, kind: "run"});
				var key = "#host#|#cmd#";
				var expectations = pool.$accessExpectations();
				var result = "";
				if (structKeyExists(expectations, key)) {
					result = expectations[key];
				} else if (pool.$accessStrict()) {
					throw(type="FakeSshPool.Unexpected",
						message="Unexpected command on #host#: #cmd#");
				} else {
					result = {exitCode: 0, stdout: "", stderr: "", durationMs: 0};
				}
				// A scripted transport failure throws BEFORE the raise check —
				// the real SshClient.run dies in startSession() on a dead
				// cached connection, so {raise: false} can never suppress it.
				if (structKeyExists(result, "transportError")) {
					throw(
						type = "FakeSshPool.TransportFailure",
						message = result.transportError
					);
				}
				// Mirror SshClient.run's opts.raise contract — #2696. Tests
				// assert that the deploy dispatch layer surfaces nonzero exit
				// codes by opting into raise=true at the call site.
				if ((arguments.opts.raise ?: false) && (result.exitCode ?: 0) != 0) {
					pool.$raiseRemoteFailure(host, cmd, result);
				}
				return result;
			},
			upload: function(local, remote, opts = {}) {
				arrayAppend(pool.$accessCalls(), {host: host, kind: "upload",
					local: local, remote: remote, opts: opts});
			},
			uploadString: function(content, remote, opts = {}) {
				arrayAppend(pool.$accessCalls(), {host: host, kind: "uploadString",
					content: content, remote: remote, opts: opts});
			},
			download: function(remote, local) {
				arrayAppend(pool.$accessCalls(), {host: host, kind: "download",
					remote: remote, local: local});
			},
			close: function() {}
		};
	}
}
