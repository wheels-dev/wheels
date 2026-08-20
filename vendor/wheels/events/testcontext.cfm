<cfscript>
	// Included from Application.cfc AFTER config/app.cfm finalizes this.name.
	// Issue #3374: bind test-runner / TestClient / browser requests to a
	// separate CFML application scope so the live application.wheels is never
	// mutated. This file is constructor-context (not a function) — do not use
	// the local scope; temp state lives on this.wheels and is deleted after.
	//
	// Keep the suffix / header CGI key / cookie name in lockstep with
	// wheels.events.TestContext — TestRunnerIsolationSpec scans both.
	//
	// Cannot CreateObject("wheels.events.TestContext") from here: this.mappings
	// is not guaranteed to be registered during Application.cfc's constructor.

	if (StructKeyExists(this, "name") && Len(this.name)) {
		this.wheels.$testContext = {
			suffix = "_wheelsTest",
			haystack = "",
			match = false
		};

		if (
			Len(this.name) >= Len(this.wheels.$testContext.suffix)
			&& Right(this.name, Len(this.wheels.$testContext.suffix)) == this.wheels.$testContext.suffix
		) {
			this.wheels.$testContext.match = true;
		} else {
			if (IsDefined("cgi.path_info")) {
				this.wheels.$testContext.haystack &= " " & ToString(cgi.path_info);
			}
			if (IsDefined("cgi.script_name")) {
				this.wheels.$testContext.haystack &= " " & ToString(cgi.script_name);
			}
			if (IsDefined("cgi.query_string")) {
				this.wheels.$testContext.haystack &= " " & ToString(cgi.query_string);
			}
			if (IsDefined("cgi.request_url")) {
				this.wheels.$testContext.haystack &= " " & ToString(cgi.request_url);
			}
			if (IsDefined("cgi.http_url")) {
				this.wheels.$testContext.haystack &= " " & ToString(cgi.http_url);
			}

			if (
				FindNoCase("/wheels/core/tests", this.wheels.$testContext.haystack)
				|| FindNoCase("/wheels/app/tests", this.wheels.$testContext.haystack)
			) {
				this.wheels.$testContext.match = true;
			}

			if (
				!this.wheels.$testContext.match
				&& IsDefined("cgi.http_x_wheels_test_context")
				&& Len(ToString(cgi.http_x_wheels_test_context))
			) {
				this.wheels.$testContext.match = true;
			}

			if (!this.wheels.$testContext.match) {
				try {
					if (IsDefined("cookie.WHEELS_TEST_CONTEXT") && Len(ToString(cookie.WHEELS_TEST_CONTEXT))) {
						this.wheels.$testContext.match = true;
					}
				} catch (any e) {
					// cookie scope unavailable in this constructor — header/path still apply
				}
			}

			if (this.wheels.$testContext.match) {
				this.name = this.name & this.wheels.$testContext.suffix;
			}
		}

		StructDelete(this.wheels, "$testContext");
	}
</cfscript>
