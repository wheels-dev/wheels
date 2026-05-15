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
		return this;
	}

	public void function expect(required string host, required string cmd, required struct result) {
		variables.expectations["#arguments.host#|#arguments.cmd#"] = arguments.result;
	}

	public array function calls() { return variables.calls; }
	public void function reset() { arrayClear(variables.calls); }

	public void function onEach(required array hosts, required any callback) {
		for (var host in arguments.hosts) {
			var ssh = $makeFakeSsh(host);
			arguments.callback(ssh, host);
		}
	}

	public void function onAny(required array hosts, required any callback) {
		if (arrayLen(arguments.hosts) == 0) return;
		var ssh = $makeFakeSsh(arguments.hosts[1]);
		arguments.callback(ssh, arguments.hosts[1]);
	}

	public void function sequential(required array hosts, required any callback) {
		onEach(arguments.hosts, arguments.callback);
	}

	// Closure accessors — closures can't reach variables scope directly on Adobe.
	public array function $accessCalls() { return variables.calls; }
	public struct function $accessExpectations() { return variables.expectations; }
	public boolean function $accessStrict() { return variables.strict; }

	/**
	 * Mirror SshClient.$raiseRemoteFailure — same throw type / message shape /
	 * detail-trim behavior so tests can assert one contract regardless of
	 * which pool the deploy layer is talking to. Regression #2696.
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
		var cmdSummary = arguments.cmd;
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
