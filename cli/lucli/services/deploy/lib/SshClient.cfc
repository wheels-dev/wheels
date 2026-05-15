/**
 * SshClient — single-host SSH facade over sshj 0.39.0.
 *
 * One instance == one remote host. `init()` opens the connection; call
 * `.close()` when done. For parallel fan-out across multiple hosts, Task 9
 * introduces `SshPool` which manages a pool of SshClient instances.
 *
 * All sshj classes are loaded through JarLoader's isolated URLClassLoader so
 * BouncyCastle (sshj's crypto backend) doesn't collide with Lucee's bundled
 * provider. Same pattern as Mustache.cfc / Yaml.cfc.
 *
 * Capabilities:
 *   - run(cmd, opts)                remote shell + stdout/stderr/exitCode/durationMs
 *   - upload(local, remote, opts)   SFTP put
 *   - uploadString(content, remote) write-to-temp + SFTP put
 *   - download(remote, local)       SFTP get
 *   - close()                       disconnect if connected
 *
 * Sudo wrapping: pass `opts.sudo = true` to `run()`. If the user is not root,
 * the command is prefixed with `sudo -n `. If sudo requires a password (not
 * configured for NOPASSWD), sshj surfaces "a password is required" on stderr
 * and we throw `SshClient.SudoNoPassword`.
 */
component {

	/**
	 * Open the SSH connection.
	 *
	 * @host Remote host (DNS or IP).
	 * @opts Keys:
	 *       - user                   default "root"
	 *       - port                   default 22
	 *       - privateKey             path to private key file; if empty, falls back to ssh-agent
	 *       - strictHostKeyChecking  default true; when false, PromiscuousVerifier is used
	 *       - timeoutMs              connect + session timeout, default 30000
	 */
	public SshClient function init(string host = "", struct opts = {}) {
		variables.$loader = new modules.wheels.services.deploy.lib.JarLoader();
		// Deferred-open pattern: `new SshClient()` with no args is a no-op so
		// Lucee's implicit init-on-new doesn't try to connect. Callers use
		// `new SshClient().init(host, opts)` to actually open a connection.
		if (!len(arguments.host)) {
			return this;
		}
		variables.$host = arguments.host;
		variables.$opts = {
			user: arguments.opts.user ?: "root",
			port: arguments.opts.port ?: 22,
			privateKey: arguments.opts.privateKey ?: "",
			strictHostKeyChecking: arguments.opts.strictHostKeyChecking ?: true,
			timeoutMs: arguments.opts.timeoutMs ?: 30000
		};

		// All sshj classes go through the isolated loader. TCCL swap ensures
		// sshj's internal ServiceLoader lookups (JCE, key formats) resolve
		// against our BouncyCastle, not Lucee's.
		var loader = variables.$loader;
		variables.$sshj = loader.newInstance("net.schmizz.sshj.SSHClient");

		loader.withIsolatedTCCL(() => {
			if (!variables.$opts.strictHostKeyChecking) {
				var promiscuous = loader.newInstance(
					"net.schmizz.sshj.transport.verification.PromiscuousVerifier"
				);
				variables.$sshj.addHostKeyVerifier(promiscuous);
			} else {
				variables.$sshj.loadKnownHosts();
			}
			variables.$sshj.setTimeout(javaCast("int", variables.$opts.timeoutMs));
			variables.$sshj.connect(variables.$host, javaCast("int", variables.$opts.port));

			if (len(variables.$opts.privateKey)) {
				var keyProvider = variables.$sshj.loadKeys(variables.$opts.privateKey);
				variables.$sshj.authPublickey(variables.$opts.user, [keyProvider]);
			} else {
				// Varargs-style fallback to ssh-agent. If the agent isn't running,
				// sshj raises UserAuthException — the caller should pass a
				// privateKey path instead.
				variables.$sshj.authPublickey(variables.$opts.user);
			}
		});
		return this;
	}

	/**
	 * Run `cmd` on the remote host via an SSH session.
	 *
	 * @cmd  Shell command string.
	 * @opts Keys:
	 *       - sudo   boolean, default false. If true AND user != "root", prefixes
	 *                the command with `sudo -n `. Throws SshClient.SudoNoPassword
	 *                if NOPASSWD isn't configured on the remote host.
	 *       - raise  boolean, default false. If true and the remote exit code is
	 *                nonzero, throws Wheels.Deploy.RemoteExecutionFailed with the
	 *                host, exitCode, and a command summary in the message and the
	 *                trimmed stderr in the detail. Mirrors the existing sudo-no-
	 *                password throw shape, just for arbitrary remote failures.
	 *                Regression #2696 — deploy verbs used to discard the result
	 *                struct and silently treat any nonzero exit as success.
	 *
	 * @return struct {exitCode, stdout, stderr, durationMs}
	 */
	public struct function run(required string cmd, struct opts = {}) {
		var useSudo = (arguments.opts.sudo ?: false) && variables.$opts.user != "root";
		var raise = arguments.opts.raise ?: false;
		var effectiveCmd = useSudo ? "sudo -n " & arguments.cmd : arguments.cmd;
		var loader = variables.$loader;
		var hostRef = variables.$host;
		var sshjRef = variables.$sshj;
		var origCmd = arguments.cmd;
		var start = getTickCount();

		return loader.withIsolatedTCCL(() => {
			// NOTE: variable name deliberately NOT "session" — that's a Lucee
			// reserved scope. Using `sess` to stay out of the scope resolver.
			var sess = sshjRef.startSession();
			try {
				var command = sess.exec(effectiveCmd);
				// Drain both streams before join() to avoid blocking on a full pipe buffer.
				// We read via JDK streams rather than commons-io — sshj 0.39.0 doesn't
				// ship IOUtils and we'd rather not bundle another JAR just for this.
				var stdout = $readStream(command.getInputStream());
				var stderr = $readStream(command.getErrorStream());
				command.join();

				var exitCode = command.getExitStatus();
				// sshj returns null for exitCode if the process died mid-flight
				// (closed by signal, network drop). Surface -1 for that case.
				if (isNull(exitCode)) {
					exitCode = -1;
				}

				var result = {
					exitCode: exitCode,
					stdout: stdout,
					stderr: stderr,
					durationMs: getTickCount() - start
				};

				if (useSudo && exitCode != 0 && findNoCase("a password is required", stderr)) {
					throw(
						type = "SshClient.SudoNoPassword",
						message = "Passwordless sudo not configured on #hostRef#"
					);
				}
				if (raise && exitCode != 0) {
					$raiseRemoteFailure(hostRef, origCmd, result);
				}
				return result;
			} finally {
				sess.close();
			}
		});
	}

	/**
	 * Throw Wheels.Deploy.RemoteExecutionFailed with structured detail. Public
	 * so FakeSshPool can share the exact same throw shape; tests assert against
	 * this contract. Regression #2696.
	 *
	 * Trims the command summary to 200 chars and stderr to 500 chars so log
	 * output stays scannable when long shell pipelines or noisy stderr would
	 * otherwise dominate the surfaced error.
	 *
	 * MIRROR: FakeSshPool.$raiseRemoteFailure must stay byte-identical to this
	 * method. If you change the trim limits, throw type, or message template
	 * here, update the test double in lockstep — tests assert against this
	 * exact shape regardless of which pool the deploy layer is talking to.
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

	/**
	 * SFTP upload a local file to `remotePath`.
	 *
	 * @opts Reserved for future SFTP flags (mode, preserve-times). Currently unused.
	 */
	public void function upload(
		required string localPath,
		required string remotePath,
		struct opts = {}
	) {
		var sshjRef = variables.$sshj;
		var localRef = arguments.localPath;
		var remoteRef = arguments.remotePath;
		variables.$loader.withIsolatedTCCL(() => {
			var sftp = sshjRef.newSFTPClient();
			try {
				sftp.put(localRef, remoteRef);
			} finally {
				sftp.close();
			}
		});
	}

	/**
	 * Write `content` to a temp file and upload it to `remotePath`. Temp file
	 * is deleted in a finally block regardless of upload outcome.
	 */
	public void function uploadString(
		required string content,
		required string remotePath,
		struct opts = {}
	) {
		var tmp = getTempFile(getTempDirectory(), "sshstr");
		fileWrite(tmp, arguments.content);
		try {
			upload(tmp, arguments.remotePath, arguments.opts);
		} finally {
			if (fileExists(tmp)) {
				fileDelete(tmp);
			}
		}
	}

	/**
	 * SFTP download `remotePath` to `localPath`.
	 */
	public void function download(required string remotePath, required string localPath) {
		var sshjRef = variables.$sshj;
		var remoteRef = arguments.remotePath;
		var localRef = arguments.localPath;
		variables.$loader.withIsolatedTCCL(() => {
			var sftp = sshjRef.newSFTPClient();
			try {
				sftp.get(remoteRef, localRef);
			} finally {
				sftp.close();
			}
		});
	}

	/**
	 * Disconnect from the remote host. Idempotent — safe to call multiple times.
	 */
	public void function close() {
		if (structKeyExists(variables, "$sshj") && variables.$sshj.isConnected()) {
			variables.$sshj.disconnect();
		}
	}

	// -----------------------------------------------------------------------
	// Internals
	// -----------------------------------------------------------------------

	/**
	 * Drain an `InputStream` into a UTF-8 string using pure JDK classes.
	 * Returns empty string if the stream is null (sshj may return null streams
	 * when a remote process dies before producing output).
	 */
	public string function $readStream(required any stream) {
		if (isNull(arguments.stream)) {
			return "";
		}
		var baos = createObject("java", "java.io.ByteArrayOutputStream").init();
		var buffer = createObject("java", "java.lang.reflect.Array")
			.newInstance(createObject("java", "java.lang.Byte").TYPE, javaCast("int", 8192));
		while (true) {
			var n = arguments.stream.read(buffer);
			if (n <= 0) {
				break;
			}
			baos.write(buffer, javaCast("int", 0), javaCast("int", n));
		}
		return baos.toString("UTF-8");
	}

}
