<cfscript>
	// Included from Application.cfc AFTER config/app.cfm finalizes this.name.
	// Issue #3374: bind test-runner / TestClient / browser requests to a
	// separate CFML application scope so the live application.wheels is never
	// mutated. This file is constructor-context (not a function) — do not use
	// the local scope; temp state lives on this.wheels and is deleted after.
	//
	// Keep the suffix / header CGI key / cookie name in lockstep with
	// wheels.events.TestContext — TestContextIsolationSpec scans both.
	//
	// Cannot CreateObject("wheels.events.TestContext") from here: this.mappings
	// is not guaranteed to be registered during Application.cfc's constructor.
	//
	// The switch is gated three ways (defense in depth):
	//   1. environment: only development / testing (resolved from WHEELS_ENV,
	//      the one env signal readable in the constructor); fail closed otherwise.
	//   2. the runner path is matched against path_info / script_name.
	//   3. the header / cookie must equal the per-process runner secret
	//      (server.$wheelsTestContextSecret, constant-time compare) AND arrive
	//      from a loopback socket peer (cgi.remote_addr, never a forwarded header).
	// The authoritative backstop is the production refusal in
	// events/onapplicationstart.cfc — this constructor gate is defense in depth,
	// because WHEELS_ENV is not a trustworthy production signal.

	if (StructKeyExists(this, "name") && Len(this.name)) {
		// Mark that test-context isolation is CONFIGURED for this app — this include is present and ran.
		// The test-runner actions (wheels.Public testbox / tests_testbox) read this to refuse running
		// specs in the live scope when a request reached them WITHOUT binding the isolated application
		// (e.g. a custom route the path trigger doesn't cover). Apps without this include never set it,
		// so they keep the existing live-scope swap behaviour.
		request.$wheelsTestContextConfigured = true;

		this.wheels.$testContext = {
			suffix = "_wheelsTest",
			match = false,
			env = "",
			envAllows = false,
			pathHaystack = "",
			remoteAddr = "",
			isLoopback = false,
			candidate = "",
			secretPresent = (StructKeyExists(server, "$wheelsTestContextSecret") && Len(server.$wheelsTestContextSecret))
		};

		// Already isolated (a nested test request) — keep the suffix, no re-check.
		if (
			Len(this.name) >= Len(this.wheels.$testContext.suffix)
			&& Right(this.name, Len(this.wheels.$testContext.suffix)) == this.wheels.$testContext.suffix
		) {
			this.wheels.$testContext.match = true;
		} else {
			// (1) Resolve the environment from WHEELS_ENV. The constructor already
			// computes `currentEnv` for the same purpose (session-cookie Secure);
			// reuse it when present, else fall back to this.env / the system env.
			if (StructKeyExists(variables, "currentEnv") && IsSimpleValue(variables.currentEnv)) {
				this.wheels.$testContext.env = variables.currentEnv;
			} else if (StructKeyExists(this, "env") && IsStruct(this.env) && StructKeyExists(this.env, "WHEELS_ENV")) {
				this.wheels.$testContext.env = this.env["WHEELS_ENV"];
			} else {
				try {
					this.wheels.$testContext.sysEnv = CreateObject("java", "java.lang.System").getenv("WHEELS_ENV");
					if (!IsNull(this.wheels.$testContext.sysEnv) && Len(this.wheels.$testContext.sysEnv)) {
						this.wheels.$testContext.env = this.wheels.$testContext.sysEnv;
					}
				} catch (any e) {
					// system environment unavailable — env stays "" (fail closed)
				}
			}
			this.wheels.$testContext.env = LCase(Trim(ToString(this.wheels.$testContext.env)));
			this.wheels.$testContext.envAllows = (
				this.wheels.$testContext.env == "development"
				|| this.wheels.$testContext.env == "testing"
			);

			if (this.wheels.$testContext.envAllows) {
				// (2) Path trigger — path_info or script_name must START with a runner endpoint
				// (/wheels/core/tests or /wheels/app/tests) at a whole-segment boundary, so a runner
				// path merely embedded inside an application route does not bind the test context.
				// For each value: lowercase/trim, then cut the query string off FIRST (so a '//' or
				// '..' living inside a query cannot reject a legitimate runner URL), reject any
				// remaining '..' traversal or '//' empty segment, then start-anchored match.
				// Inline, constructor-safe copy of TestContext.$pathTriggersTestContext() (no vars/
				// loops/CreateObject here) — keep the two in lockstep.
				this.wheels.$testContext.pInfo = ReReplace(IsDefined("cgi.path_info") ? LCase(Trim(ToString(cgi.path_info))) : "", "\?.*$", "");
				this.wheels.$testContext.pScript = ReReplace(IsDefined("cgi.script_name") ? LCase(Trim(ToString(cgi.script_name))) : "", "\?.*$", "");
				this.wheels.$testContext.match = (
					(
						!ReFind("\.\.|//", this.wheels.$testContext.pInfo)
						&& ReFindNoCase("^/wheels/(core/tests|app/tests|testbox|tests_testbox)(/|$)", this.wheels.$testContext.pInfo) > 0
					)
					|| (
						!ReFind("\.\.|//", this.wheels.$testContext.pScript)
						&& ReFindNoCase("^/wheels/(core/tests|app/tests|testbox|tests_testbox)(/|$)", this.wheels.$testContext.pScript) > 0
					)
				);

				// (3) Header / cookie trigger — per-process secret (constant-time)
				// AND a loopback socket peer. Skipped entirely until a runner has
				// generated server.$wheelsTestContextSecret.
				if (!this.wheels.$testContext.match && this.wheels.$testContext.secretPresent) {
					if (IsDefined("cgi.remote_addr")) {
						this.wheels.$testContext.remoteAddr = Trim(ToString(cgi.remote_addr));
					}
					if (Len(this.wheels.$testContext.remoteAddr)) {
						try {
							this.wheels.$testContext.isLoopback = CreateObject("java", "java.net.InetAddress")
								.getByName(this.wheels.$testContext.remoteAddr)
								.isLoopbackAddress();
						} catch (any e) {
							// unresolvable address — treat as non-loopback (fail closed)
						}
					}

					if (this.wheels.$testContext.isLoopback) {
						if (
							IsDefined("cgi.http_x_wheels_test_context")
							&& Len(ToString(cgi.http_x_wheels_test_context))
						) {
							this.wheels.$testContext.candidate = ToString(cgi.http_x_wheels_test_context);
						} else {
							try {
								if (IsDefined("cookie.WHEELS_TEST_CONTEXT") && Len(ToString(cookie.WHEELS_TEST_CONTEXT))) {
									this.wheels.$testContext.candidate = ToString(cookie.WHEELS_TEST_CONTEXT);
								}
							} catch (any e) {
								// cookie scope unavailable in this constructor — header still applies
							}
						}

						if (Len(this.wheels.$testContext.candidate)) {
							// Constant-time compare: hash both sides to equal-length hex,
							// then OR the per-character XOR so neither length nor a shared
							// prefix leaks. Mirrors TestContext.$secureEquals().
							this.wheels.$testContext.ha = Hash(this.wheels.$testContext.candidate, "SHA-256");
							this.wheels.$testContext.hb = Hash(server.$wheelsTestContextSecret, "SHA-256");
							this.wheels.$testContext.diff = 0;
							for (
								this.wheels.$testContext.i = 1;
								this.wheels.$testContext.i <= Len(this.wheels.$testContext.ha);
								this.wheels.$testContext.i++
							) {
								this.wheels.$testContext.diff = BitOr(
									this.wheels.$testContext.diff,
									BitXor(
										Asc(Mid(this.wheels.$testContext.ha, this.wheels.$testContext.i, 1)),
										Asc(Mid(this.wheels.$testContext.hb, this.wheels.$testContext.i, 1))
									)
								);
							}
							if (this.wheels.$testContext.diff == 0) {
								this.wheels.$testContext.match = true;
							}
						}
					}
				}
			}

			if (this.wheels.$testContext.match) {
				this.name = this.name & this.wheels.$testContext.suffix;
			}
		}

		StructDelete(this.wheels, "$testContext");
	}
</cfscript>
