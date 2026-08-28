/**
 * Coverage service for `wheels coverage` — instruments app/ with function-level
 * coverage counters, runs the app test suite over HTTP, and combines the
 * collected coverage with per-file cyclomatic complexity into a CRAP ranking
 * (Change Risk Anti-Patterns: complexity^2 * (1 - coverage)^3 + complexity).
 *
 * Counters write to `server.__wheels_cov` (process-wide); the app test runner
 * (vendor/wheels/tests/app-runner.cfm) dumps that struct to
 * /tmp/wheels-app-coverage.json when the request carries `?coverage=true`.
 *
 * Cross-engine notes (Lucee): regex backslashes are built with Chr(92);
 * `<cf` inside a string is parsed as a tag, so tag patterns concatenate "<".
 */
component output="false" {

	variables.bs = Chr(92);

	// \bfunction\s+([A-Za-z_$][\w$]*)\s*\([^)]*\)\s*\{ — name captured in group 1
	variables.scriptFnPattern = variables.bs & "bfunction" & variables.bs & "s+([A-Za-z_$][" & variables.bs & "w$]*)" & variables.bs & "s*" & variables.bs & "([^)]*" & variables.bs & ")" & variables.bs & "s*" & variables.bs & "{";

	// script decision points (mirrors wheelstest.system.CodeComplexity)
	variables.scriptDecision = ArrayToList([
		variables.bs & "bif" & variables.bs & "b",
		variables.bs & "belseif" & variables.bs & "b",
		variables.bs & "belse" & variables.bs & "s+if" & variables.bs & "b",
		variables.bs & "bfor" & variables.bs & "b",
		variables.bs & "bwhile" & variables.bs & "b",
		variables.bs & "bdo" & variables.bs & "b",
		variables.bs & "bcase" & variables.bs & "b",
		variables.bs & "bcatch" & variables.bs & "b",
		variables.bs & "band" & variables.bs & "b",
		variables.bs & "bor" & variables.bs & "b",
		"&&",
		variables.bs & "|" & variables.bs & "|",
		variables.bs & "?"
	], "|");
	variables.tagDecision = "<" & "cf(?:if|elseif|loop|while|case|defaultcase|catch)" & variables.bs & "b";
	variables.tagComment = "<!---.*?--->";
	variables.blockComment = "/" & variables.bs & "*.*?" & variables.bs & "*/";
	variables.lineComment = "(?m)(?<!:)//[^" & variables.bs & "n]*";

	// Self-initializing counter, written into script function bodies. Single-
	// quoted so the embedded double quotes need no escaping.
	variables.scriptCounter = 'server.__wheels_cov = isDefined("server.__wheels_cov") ? server.__wheels_cov : {}; server.__wheels_cov["{ID}"] = true;';

	variables.dumpPath = "/tmp/wheels-app-coverage.json";

	/**
	 * Insert a coverage counter at the top of every script function under root.
	 * Returns the number of counters inserted. Originals are backed up under
	 * <root>/.coverage-backup/ so $revert() restores them exactly.
	 */
	public numeric function $instrument(required string root) {
		local.count = 0;
		local.paths = [];
		$collectFiles(arguments.root, local.paths);
		for (local.path in local.paths) {
			local.rel = $relPath(arguments.root, local.path);
			local.content = FileRead(local.path);
			local.orig = local.content;
			local.pos = 1;
			while (true) {
				local.m = reFind(variables.scriptFnPattern, local.content, local.pos, true);
				if (local.m.pos[1] == 0) {
					break;
				}
				local.name = Mid(local.content, local.m.pos[2], local.m.len[2]);
				local.counter = Replace(variables.scriptCounter, "{ID}", local.rel & ":" & local.name);
				local.insertAt = local.m.pos[1] + local.m.len[1] - 1;
				local.content = Left(local.content, local.insertAt) & local.counter & Mid(local.content, local.insertAt + 1);
				local.pos = local.insertAt + Len(local.counter);
				local.count++;
			}
			if (local.content != local.orig) {
				$backup(arguments.root, local.rel, local.orig);
				FileWrite(local.path, local.content);
			}
		}
		return local.count;
	}

	/** Restore the pre-instrumentation sources and remove the backup dir. */
	public void function $revert(required string root) {
		local.backupDir = arguments.root & "/.coverage-backup";
		if (!DirectoryExists(local.backupDir)) {
			return;
		}
		local.backups = DirectoryList(local.backupDir, true, "path");
		for (local.b in local.backups) {
			if (FileExists(local.b)) {
				local.rel = Replace(local.b, local.backupDir, "");
				if (Left(local.rel, 1) == "/") {
					local.rel = Right(local.rel, Len(local.rel) - 1);
				}
				FileWrite(arguments.root & "/" & local.rel, FileRead(local.b));
			}
		}
		DirectoryDelete(local.backupDir, true);
	}

	/** Run the app test suite over HTTP (the runner dumps coverage when ?coverage=true). */
	public struct function $runSuite(required numeric serverPort, boolean useTestDb = true) {
		local.url = "http://localhost:" & arguments.serverPort & "/wheels/app/tests?format=json&coverage=true&useTestDB=" & (arguments.useTestDb ? "true" : "false");
		local.http = new http(url = local.url, method = "GET", timeout = 1800);
		local.result = local.http.send().getPrefix();
		return { status = local.result.statusCode ?: "0", body = local.result.fileContent ?: "" };
	}

	/** Read the coverage dump written by the app test runner. */
	public struct function $collect() {
		if (FileExists(variables.dumpPath)) {
			try {
				return DeserializeJSON(FileRead(variables.dumpPath));
			} catch (any e) {
				return {};
			}
		}
		return {};
	}

	/**
	 * Per-file coverage + complexity + CRAP, sorted by CRAP desc.
	 * coverage keys are "<rel>:<fn>"; a file is covered when any of its
	 * functions fired.
	 */
	public array function $analyze(required string root, required struct coverage) {
		local.rows = [];
		local.paths = [];
		$collectFiles(arguments.root, local.paths);
		for (local.path in local.paths) {
			local.rel = $relPath(arguments.root, local.path);
			local.content = FileRead(local.path);
			local.complexity = $fileComplexity(local.content);
			local.covered = $isCovered(arguments.coverage, local.rel);
			local.uncovered = 1 - (local.covered ? 1 : 0);
			local.crap = (local.complexity * local.complexity) * (local.uncovered * local.uncovered * local.uncovered) + local.complexity;
			arrayAppend(local.rows, {
				file = local.rel,
				complexity = local.complexity,
				covered = local.covered,
				crap = local.crap
			});
		}
		return $sortByCrapDesc(local.rows);
	}

	/** Render the CRAP report as CLI text. */
	public string function $report(required array rows, numeric top = 15, numeric instrumented = 0, string suiteStatus = "") {
		local.lines = [];
		local.total = arrayLen(arguments.rows);
		local.covered = 0;
		for (local.r in arguments.rows) {
			if (local.r.covered) {
				local.covered++;
			}
		}
		local.pct = local.total ? Round(100 * local.covered / local.total) : 0;
		arrayAppend(local.lines, "Function coverage: " & local.covered & "/" & local.total & " files (" & local.pct & "%) - " & arguments.instrumented & " counters instrumented" & (Len(arguments.suiteStatus) ? "; suite HTTP " & arguments.suiteStatus : ""));
		arrayAppend(local.lines, "");
		arrayAppend(local.lines, "Top CRAP (change risk = complexity^2 x (1 - coverage)^3 + complexity):");
		arrayAppend(local.lines, "  CRAP   comp  cov  file");
		local.shown = 0;
		for (local.r in arguments.rows) {
			if (local.shown >= arguments.top) {
				break;
			}
			if (!local.r.covered || local.r.complexity > 10) {
				arrayAppend(local.lines, "  " & NumberFormat(local.r.crap, "0000") & "  " & NumberFormat(local.r.complexity, "000") & "  " & (local.r.covered ? "yes" : "NO ") & "  " & local.r.file);
				local.shown++;
			}
		}
		return ArrayToList(local.lines, Chr(10));
	}

	/** Cyclomatic complexity of a whole file (1 + decision points). */
	private numeric function $fileComplexity(required string text) {
		local.cleaned = $stripComments(arguments.text);
		return 1 + arrayLen(reMatchNoCase(variables.scriptDecision, local.cleaned))
			+ arrayLen(reMatchNoCase(variables.tagDecision, local.cleaned));
	}

	/** Strip CFML comments (tag <!--- --->, block / * * /, line //). */
	private string function $stripComments(required string text) {
		local.rv = reReplace(arguments.text, variables.tagComment, "", "all");
		local.rv = reReplace(local.rv, variables.blockComment, "", "all");
		local.rv = reReplace(local.rv, variables.lineComment, "", "all");
		return local.rv;
	}

	/** True when any coverage key belongs to this file ("<rel>:<fn>"). */
	private boolean function $isCovered(required struct coverage, required string rel) {
		local.prefix = arguments.rel & ":";
		for (local.key in arguments.coverage) {
			if (Left(local.key, Len(local.prefix)) == local.prefix) {
				return true;
			}
		}
		return false;
	}

	/** Recursively list .cfc/.cfm files under root, skipping tests + backup dirs. */
	private void function $collectFiles(required string root, required array out) {
		local.entries = DirectoryList(arguments.root, true, "path");
		for (local.entry in local.entries) {
			local.norm = Replace(local.entry, Chr(92), "/", "all");
			local.lower = LCase(local.entry);
			if ((Right(local.lower, 4) == ".cfc" || Right(local.lower, 4) == ".cfm")
				&& Find("/tests/", local.norm) == 0
				&& Find("/.coverage-backup/", local.norm) == 0) {
				arrayAppend(arguments.out, local.entry);
			}
		}
	}

	/** Strip the root prefix (and any leading slash) for a display path. */
	private string function $relPath(required string root, required string path) {
		local.rv = Replace(Replace(arguments.path, arguments.root, ""), Chr(92), "/", "all");
		if (Left(local.rv, 1) == "/") {
			local.rv = Right(local.rv, Len(local.rv) - 1);
		}
		return local.rv;
	}

	/** Write an original to the backup dir (mirroring the rel path). */
	private void function $backup(required string root, required string rel, required string content) {
		local.backupPath = arguments.root & "/.coverage-backup/" & arguments.rel;
		local.parent = GetDirectoryFromPath(local.backupPath);
		if (!DirectoryExists(local.parent)) {
			DirectoryCreate(local.parent, true);
		}
		FileWrite(local.backupPath, arguments.content);
	}

	/** Insertion sort by CRAP desc (no closure — cross-engine safe). */
	private array function $sortByCrapDesc(required array rows) {
		local.sorted = [];
		for (local.r in arguments.rows) {
			local.inserted = false;
			for (local.j = 1; local.j <= arrayLen(local.sorted); local.j++) {
				if (local.r.crap > local.sorted[local.j].crap) {
					arrayInsertAt(local.sorted, local.j, local.r);
					local.inserted = true;
					break;
				}
			}
			if (!local.inserted) {
				arrayAppend(local.sorted, local.r);
			}
		}
		return local.sorted;
	}

}
