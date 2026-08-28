/**
 * Static cyclomatic-complexity analysis for the debug bar's "Complexity" panel.
 * Scans a source root (default app/) and reports per-file cyclomatic
 * complexity, mirroring the CI gate at tools/code-quality/cfml-complexity.py.
 *
 * Regex patterns are built with Chr(92) (backslash) rather than string-literal
 * escapes: Lucee treats `\b` as a backspace escape, so a literal backslash in a
 * regex must be concatenated, not typed inside a string.
 */
component output="false" {

	// backslash + common regex escapes, built unambiguously
	variables.bs = Chr(92);
	variables.wb = variables.bs & "b";  // \b word boundary
	variables.ws = variables.bs & "s";  // \s whitespace
	variables.ww = variables.bs & "w";  // \w word char
	variables.nn = variables.bs & "n";  // \n newline

	// script-syntax decision points (each match = +1 branch)
	variables.scriptDecision = ArrayToList([
		variables.wb & "if" & variables.wb,
		variables.wb & "elseif" & variables.wb,
		variables.wb & "else" & variables.ws & "+if" & variables.wb,
		variables.wb & "for" & variables.wb,
		variables.wb & "while" & variables.wb,
		variables.wb & "do" & variables.wb,
		variables.wb & "case" & variables.wb,
		variables.wb & "catch" & variables.wb,
		variables.wb & "and" & variables.wb,
		variables.wb & "or" & variables.wb,
		"&&",
		variables.bs & "|" & variables.bs & "|",  // \|\| literal ||
		variables.bs & "?"                         // \? literal ?
	], "|");

	variables.tagDecision = "<" & "cf(?:if|elseif|loop|while|case|defaultcase|catch)" & variables.wb;
	variables.scriptFn = variables.wb & "function" & variables.ws & "+[A-Za-z_$][" & variables.ww & "$]*" & variables.ws & "*" & variables.bs & "(";
	variables.tagFn = "<" & "cffunction" & variables.wb & "[^>]*?" & variables.wb & "name";
	variables.blockComment = "/" & variables.bs & "*.*?" & variables.bs & "*/";
	variables.lineComment = "(?m)(?<!:)//[^" & variables.nn & "]*";
	variables.tagComment = "<!---.*?--->";

	/**
	 * Analyze every .cfc/.cfm under `root` and return:
	 *   summary = { files, functions, maxComplexity, avgComplexity }
	 *   files   = [ { file, functions, complexity, avg }, ... ] (complexity desc)
	 */
	public struct function analyze(required string root) {
		local.files = [];
		local.summary = { files = 0, functions = 0, maxComplexity = 0, avgComplexity = 0 };
		local.totalComplexity = 0;
		local.paths = $collectFiles(arguments.root);
		for (local.path in local.paths) {
			local.rel = $relativePath(arguments.root, local.path);
			try {
				local.content = FileRead(local.path);
				local.fnCount = $countFunctions(local.content);
				local.complexity = $cyclomatic(local.content);
			} catch (any e) {
				local.fnCount = 0;
				local.complexity = 1;
			}
			arrayAppend(local.files, {
				file = local.rel,
				functions = local.fnCount,
				complexity = local.complexity,
				avg = (local.complexity / Max(1, local.fnCount))
			});
			local.totalComplexity += local.complexity;
			local.summary.functions += local.fnCount;
			if (local.complexity > local.summary.maxComplexity) {
				local.summary.maxComplexity = local.complexity;
			}
		}
		local.summary.files = arrayLen(local.files);
		local.summary.avgComplexity = local.summary.files ? Round(local.totalComplexity / local.summary.files) : 0;
		return { summary = local.summary, files = $sortByComplexityDesc(local.files) };
	}

	/**
	 * Cached analyze() for the debug bar. Caches on application.wheels for the
	 * app lifetime (recomputed on reload) and degrades to an empty result so a
	 * failure can never break the debug bar or the request.
	 */
	public struct function load(required string root) {
		if (StructKeyExists(application.wheels, "codeComplexity")) {
			return application.wheels.codeComplexity;
		}
		local.result = { summary = { files = 0, functions = 0, maxComplexity = 0, avgComplexity = 0 }, files = [] };
		try {
			local.result = analyze(arguments.root);
		} catch (any e) {
			// leave the empty default
		}
		application.wheels.codeComplexity = local.result;
		return local.result;
	}

	/** Cyclomatic complexity of a whole source body (1 + decision points). */
	public numeric function $cyclomatic(required string text) {
		local.cleaned = $stripComments(arguments.text);
		return 1 + arrayLen(reMatchNoCase(variables.scriptDecision, local.cleaned))
			+ arrayLen(reMatchNoCase(variables.tagDecision, local.cleaned));
	}

	/** Count named functions (script `function name(` + tag `cffunction name=`). */
	public numeric function $countFunctions(required string text) {
		local.cleaned = $stripComments(arguments.text);
		return arrayLen(reMatchNoCase(variables.scriptFn, local.cleaned))
			+ arrayLen(reMatchNoCase(variables.tagFn, local.cleaned));
	}

	/** Strip CFML comments (tag <!--- --->, block / * * /, line //). */
	public string function $stripComments(required string text) {
		local.rv = reReplace(arguments.text, variables.tagComment, "", "all");
		local.rv = reReplace(local.rv, variables.blockComment, "", "all");
		local.rv = reReplace(local.rv, variables.lineComment, "", "all");
		return local.rv;
	}

	/** Recursively list .cfc/.cfm files under root, skipping tests dirs. */
	public array function $collectFiles(required string root) {
		local.out = [];
		local.entries = DirectoryList(arguments.root, true, "path");
		for (local.entry in local.entries) {
			local.lower = LCase(local.entry);
			if ((Right(local.lower, 4) == ".cfc" || Right(local.lower, 4) == ".cfm")
				&& Find("/tests/", Replace(local.entry, Chr(92), "/", "all")) == 0) {
				arrayAppend(local.out, local.entry);
			}
		}
		return local.out;
	}

	/** Strip the root prefix (and any leading slash) to get a display path. */
	public string function $relativePath(required string root, required string path) {
		local.rv = Replace(Replace(arguments.path, arguments.root, ""), Chr(92), "/", "all");
		if (Left(local.rv, 1) == "/") {
			local.rv = Right(local.rv, Len(local.rv) - 1);
		}
		return local.rv;
	}

	/** Insertion sort by complexity desc (no closure — cross-engine safe). */
	public array function $sortByComplexityDesc(required array files) {
		local.sorted = [];
		for (local.f in arguments.files) {
			local.inserted = false;
			for (local.j = 1; local.j <= arrayLen(local.sorted); local.j++) {
				if (local.f.complexity > local.sorted[local.j].complexity) {
					arrayInsertAt(local.sorted, local.j, local.f);
					local.inserted = true;
					break;
				}
			}
			if (!local.inserted) {
				arrayAppend(local.sorted, local.f);
			}
		}
		return local.sorted;
	}

}
