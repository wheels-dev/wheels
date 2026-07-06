<!---
	tests/runner.cfm — entry point for /wheels/app/tests in the browser
	and `wheels test run` from the CLI. By default this defers to the
	framework's built-in app-test runner, which scans `tests/specs/` via
	TestBox and emits a structured result the CLI knows how to parse.

	Customise this file when you need pre-test setup the framework
	runner doesn't cover — e.g. registering a custom reporter,
	overriding test datasource resolution, applying app-specific
	bootstrap.

	Keep the include below as the last line (or replicate its body
	inline) — the framework runner is what produces the JSON / HTML
	output the rest of the system expects.

	The include path is resolved through $resolveSubpathInclude so it
	works both at the web root and under a URL subpath / CommandBox
	multi-subfolder install, where a bare `/wheels/...` mapping does not
	resolve (issue #3251).
--->
<cfinclude template="#application.wo.$resolveSubpathInclude('/wheels/tests/app-runner.cfm')#">
