/**
 * Code analysis service for detecting anti-patterns and quality issues.
 *
 * Scans app/models/, app/controllers/, and app/views/ for common Wheels
 * anti-patterns, security issues, complexity metrics, and naming violations.
 * Core ~60% of the CommandBox AnalysisService — defers duplication detection
 * and optimization suggestions to Phase 3.
 *
 * Ported from cli/src/models/AnalysisService.cfc — no WireBox dependencies.
 */
component {

	public function init(
		required any helpers,
		required string projectRoot
	) {
		variables.helpers = arguments.helpers;
		variables.projectRoot = arguments.projectRoot;
		variables.config = getDefaultConfig();

		initPatterns();

		return this;
	}

	/**
	 * Analyze code quality and detect anti-patterns
	 */
	public struct function analyze(string target = "all") {
		var startTime = getTickCount();

		var results = {
			totalFiles: 0,
			totalLines: 0,
			totalFunctions: 0,
			codeSmells: [],
			deprecatedCalls: [],
			complexFunctions: [],
			antiPatterns: [],
			metrics: {
				averageComplexity: 0,
				healthScore: 100,
				grade: "A"
			}
		};

		var dirs = [];
		switch (arguments.target) {
			case "models":
				dirs = [variables.projectRoot & "/app/models"];
				break;
			case "controllers":
				dirs = [variables.projectRoot & "/app/controllers"];
				break;
			case "views":
				dirs = [variables.projectRoot & "/app/views"];
				break;
			default:
				dirs = [
					variables.projectRoot & "/app/models",
					variables.projectRoot & "/app/controllers",
					variables.projectRoot & "/app/views"
				];
		}

		var allFiles = [];
		for (var dir in dirs) {
			if (directoryExists(dir)) {
				var files = directoryList(dir, true, "path", "*.cfc|*.cfm", "name asc");
				allFiles.addAll(files);
			}
		}

		// Analyze each file
		for (var file in allFiles) {
			if (isExcluded(file)) continue;
			analyzeFile(file, results);
		}

		// Finalize metrics
		finalizeMetrics(results);
		results.executionTime = (getTickCount() - startTime) / 1000;

		return results;
	}

	/**
	 * Quick validation focused on errors (lighter than full analyze)
	 */
	public struct function validate() {
		var issues = [];

		// Check model associations. Skip the framework's parent Model.cfc —
		// it intentionally extends "wheels.Model" rather than "Model", since
		// it IS the parent that user models inherit from.
		var modelsDir = variables.projectRoot & "/app/models";
		if (directoryExists(modelsDir)) {
			var models = directoryList(modelsDir, false, "path", "*.cfc");
			for (var modelFile in models) {
				if (listLast(modelFile, "/\") == "Model.cfc") {
					continue;
				}
				issues.addAll(validateModel(modelFile));
			}
		}

		// Check controller conventions. Skip the framework's parent
		// Controller.cfc for the same reason as Model.cfc above.
		var controllersDir = variables.projectRoot & "/app/controllers";
		if (directoryExists(controllersDir)) {
			var controllers = directoryList(controllersDir, false, "path", "*.cfc");
			for (var ctrlFile in controllers) {
				if (listLast(ctrlFile, "/\") == "Controller.cfc") {
					continue;
				}
				issues.addAll(validateController(ctrlFile));
			}
		}

		// Check route syntax
		var routesFile = variables.projectRoot & "/config/routes.cfm";
		if (fileExists(routesFile)) {
			issues.addAll(validateRoutes(routesFile));
		}

		// Check view cfparams
		var viewsDir = variables.projectRoot & "/app/views";
		if (directoryExists(viewsDir)) {
			var views = directoryList(viewsDir, true, "path", "*.cfm");
			for (var viewFile in views) {
				issues.addAll(validateView(viewFile));
			}
		}

		return {
			valid: !issues.some(function(i) { return i.severity == "error"; }),
			totalIssues: arrayLen(issues),
			issues: issues
		};
	}

	// ── Private — File Analysis ─────────────────────

	private void function analyzeFile(required string path, required struct results) {
		var content = fileRead(arguments.path);
		var lines = listToArray(content, chr(10));

		results.totalFiles++;
		results.totalLines += arrayLen(lines);

		// Run all checks
		checkWheelsAntiPatterns(arguments.path, content, lines, results);
		checkSecurity(arguments.path, content, results);
		checkComplexity(arguments.path, content, results);
		checkCodeSmells(arguments.path, content, lines, results);
	}

	/**
	 * Detect Wheels-specific anti-patterns from CLAUDE.md top 10
	 */
	private void function checkWheelsAntiPatterns(
		required string path,
		required string content,
		required array lines,
		required struct results
	) {
		var fileName = listLast(arguments.path, "/\");
		var isModel = findNoCase("/models/", arguments.path) > 0;
		var isController = findNoCase("/controllers/", arguments.path) > 0;
		var isView = findNoCase("/views/", arguments.path) > 0;

		// Anti-pattern 1: Mixed positional + named arguments
		var mixedMatches = reFindAll(variables.MIXED_ARGS_PATTERN, arguments.content, false);
		for (var m in mixedMatches) {
			arrayAppend(results.antiPatterns, {
				file: arguments.path,
				line: getLineNumber(arguments.content, m.pos),
				severity: "error",
				rule: "mixed-argument-styles",
				message: "Mixed positional and named arguments — use all named params when passing options"
			});
		}

		// Anti-pattern 2: Query/Array confusion in views
		if (isView) {
			if (reFindNoCase(variables.CFLOOP_ARRAY_PATTERN, arguments.content)) {
				arrayAppend(results.antiPatterns, {
					file: arguments.path,
					line: 1,
					severity: "warning",
					rule: "query-array-confusion",
					message: "Model finders return query objects — use cfloop query not cfloop array"
				});
			}
		}

		// Anti-pattern 9: Public controller filters
		if (isController) {
			// Find filters referenced in config()
			var filterNames = [];
			var filterMatches = reFindAll(variables.FILTER_PATTERN, arguments.content, true);
			for (var fm in filterMatches) {
				if (arrayLen(fm.groups) >= 2) {
					arrayAppend(filterNames, fm.groups[2]);
				}
			}

			// Check if those functions are public (not marked private)
			var bs = chr(92);
			var s = bs & "s";
			for (var fname in filterNames) {
				var funcDefPattern = "(?:public" & s & "+)?(?:any|void|string|boolean|struct)?" & s & "*function" & s & "+" & fname & s & "*" & bs & "(";
				if (reFindNoCase(funcDefPattern, arguments.content)) {
					// Check if it's NOT preceded by "private"
					var privateFuncPattern = "private" & s & "+(?:any|void|string|boolean|struct)?" & s & "*function" & s & "+" & fname & s & "*" & bs & "(";
					if (!reFindNoCase(privateFuncPattern, arguments.content)) {
						arrayAppend(results.antiPatterns, {
							file: arguments.path,
							line: 1,
							severity: "warning",
							rule: "public-filter-function",
							message: "Filter function '#fname#' should be declared private"
						});
					}
				}
			}
		}

		// Anti-pattern 10: Missing cfparam in views
		if (isView && !findNoCase("_form", arguments.path)) {
			// Skip partials that start with _
			if (left(fileName, 1) != "_" && !findNoCase("cfparam", arguments.content) && findNoCase("##", arguments.content)) {
				arrayAppend(results.antiPatterns, {
					file: arguments.path,
					line: 1,
					severity: "warning",
					rule: "missing-cfparam",
					message: "View uses variables but has no cfparam declarations"
				});
			}
		}
	}

	/**
	 * Check for security issues
	 */
	private void function checkSecurity(required string path, required string content, required struct results) {
		// SQL injection: preserveSingleQuotes
		if (reFindNoCase(variables.PRESERVE_PATTERN, arguments.content)) {
			arrayAppend(results.antiPatterns, {
				file: arguments.path,
				line: 1,
				severity: "error",
				rule: "sql-injection",
				message: "preserveSingleQuotes() is a SQL injection risk"
			});
		}

		// evaluate() usage
		if (reFindNoCase(variables.EVALUATE_PATTERN, arguments.content)) {
			arrayAppend(results.antiPatterns, {
				file: arguments.path,
				line: 1,
				severity: "error",
				rule: "no-evaluate",
				message: "evaluate() is dangerous — use structured alternatives"
			});
		}
	}

	/**
	 * Check function complexity
	 */
	private void function checkComplexity(required string path, required string content, required struct results) {
		var matches = reFindAll(variables.FUNC_DEF_PATTERN, arguments.content, true);

		for (var m in matches) {
			results.totalFunctions++;
			var funcName = m.groups[1];
			var funcBody = extractFunctionBody(arguments.content, m.pos);
			var complexity = calculateCyclomaticComplexity(funcBody);

			if (complexity > variables.config.maxComplexity) {
				arrayAppend(results.complexFunctions, {
					file: arguments.path,
					functionName: funcName,
					complexity: complexity,
					message: "Cyclomatic complexity #complexity# exceeds threshold (#variables.config.maxComplexity#)"
				});
			}
		}
	}

	/**
	 * Detect general code smells
	 */
	private void function checkCodeSmells(
		required string path,
		required string content,
		required array lines,
		required struct results
	) {
		// Long files
		if (arrayLen(arguments.lines) > variables.config.maxFileLength) {
			arrayAppend(results.codeSmells, {
				file: arguments.path,
				rule: "max-file-length",
				message: "File has #arrayLen(arguments.lines)# lines (max #variables.config.maxFileLength#)"
			});
		}

		// Long parameter lists
		var funcMatches = reFindAll(variables.FUNC_PARAMS_PATTERN, arguments.content, true);
		for (var m in funcMatches) {
			if (arrayLen(m.groups) >= 1) {
				var paramCount = listLen(m.groups[1], ",");
				if (paramCount > 5) {
					arrayAppend(results.codeSmells, {
						file: arguments.path,
						rule: "long-parameter-list",
						message: "Function has #paramCount# parameters — consider using a struct"
					});
				}
			}
		}

		// TODO/FIXME comments
		var todoMatches = reFindAll(variables.TODO_PATTERN, arguments.content, false);
		for (var m in todoMatches) {
			arrayAppend(results.codeSmells, {
				file: arguments.path,
				line: getLineNumber(arguments.content, m.pos),
				rule: "todo-comment",
				message: "TODO/FIXME found — technical debt"
			});
		}
	}

	// ── Private — Validation ────────────────────────

	private array function validateModel(required string path) {
		var issues = [];
		var content = fileRead(arguments.path);
		var fileName = listLast(arguments.path, "/\");
		var activeContent = $stripCfmlComments(content);

		// Check extends (against comment-stripped content so a commented-out
		// `extends="Model"` doesn't satisfy the substring match — see #2491).
		if (!findNoCase('extends="Model"', activeContent) && !findNoCase("extends='Model'", activeContent)) {
			arrayAppend(issues, {
				file: arguments.path,
				severity: "error",
				message: "#fileName# does not extend Model"
			});
		}

		// Check mixed argument styles (uses same pattern as analyze).
		// Scan comment-stripped content so a commented-out association with
		// mixed args doesn't false-positive (anti-pattern #14).
		if (reFindNoCase(variables.MIXED_ARGS_PATTERN, activeContent)) {
			arrayAppend(issues, {
				file: arguments.path,
				severity: "error",
				message: "#fileName#: Mixed positional and named args in association declaration"
			});
		}

		return issues;
	}

	private array function validateController(required string path) {
		var issues = [];
		var content = fileRead(arguments.path);
		var fileName = listLast(arguments.path, "/\");
		var activeContent = $stripCfmlComments(content);

		if (!findNoCase('extends="Controller"', activeContent) && !findNoCase("extends='Controller'", activeContent)) {
			arrayAppend(issues, {
				file: arguments.path,
				severity: "error",
				message: "#fileName# does not extend Controller"
			});
		}

		return issues;
	}

	private string function $stripCfmlComments(required string source) {
		var result = arguments.source;
		result = reReplace(result, "<!---[\s\S]*?--->", "", "all");
		result = reReplace(result, "/\*[\s\S]*?\*/", "", "all");
		result = reReplace(result, "//[^\r\n]*", "", "all");
		return result;
	}

	private array function validateRoutes(required string path) {
		var issues = [];
		// Strip comments first so commented-out mapper()/.end()/.wildcard()/
		// .resources() lines don't skew the balance/order checks (anti-pattern #14).
		var content = $stripCfmlComments(fileRead(arguments.path));

		// Check for balanced mapper/end
		var mapperCount = 0;
		var endCount = 0;
		var pos = 1;
		while (pos > 0) {
			pos = findNoCase("mapper(", content, pos);
			if (pos > 0) { mapperCount++; pos++; }
		}
		pos = 1;
		while (pos > 0) {
			pos = findNoCase(".end()", content, pos);
			if (pos > 0) { endCount++; pos++; }
		}

		if (mapperCount > 0 && endCount < mapperCount) {
			arrayAppend(issues, {
				file: arguments.path,
				severity: "error",
				message: "routes.cfm has #mapperCount# mapper() calls but only #endCount# .end() calls"
			});
		}

		// Check wildcard is last
		var wildcardPos = findNoCase(".wildcard()", content);
		if (wildcardPos > 0) {
			var endPos = findNoCase(".end()", content, wildcardPos);
			// If there are resource routes after wildcard, warn
			var afterWildcard = mid(content, wildcardPos, len(content) - wildcardPos + 1);
			if (reFindNoCase(variables.RESOURCE_AFTER_WILDCARD, afterWildcard)) {
				arrayAppend(issues, {
					file: arguments.path,
					severity: "warning",
					message: "Resource routes defined after .wildcard() — they will never match"
				});
			}
		}

		return issues;
	}

	private array function validateView(required string path) {
		var issues = [];
		var content = fileRead(arguments.path);
		var fileName = listLast(arguments.path, "/\");

		// Skip layouts and partials
		if (fileName == "layout.cfm" || left(fileName, 1) == "_") return issues;

		// Check for variable usage without cfparam. Scan comment-stripped
		// content so a view whose only # / cfparam / cfset lives inside a
		// CFML comment doesn't warn (or falsely appear protected) — #14.
		var activeContent = $stripCfmlComments(content);
		var hashChar = chr(35);
		var cfsetTag = chr(60) & "cfset";
		if (findNoCase(hashChar, activeContent) && !findNoCase("cfparam", activeContent) && !findNoCase(cfsetTag, activeContent)) {
			arrayAppend(issues, {
				file: arguments.path,
				severity: "warning",
				message: fileName & " uses variables but has no cfparam declarations"
			});
		}

		return issues;
	}

	// ── Private — Pattern initialization ────────────

	/**
	 * Build regex patterns at runtime to avoid Lucee 7 CFC parser issues
	 * with backslash sequences in string literals. Uses a .cfm include
	 * because Lucee 7's .cfc parser chokes on \s, \w, \b even in chr()-based
	 * concatenation when adjacent to certain characters.
	 */
	private void function initPatterns() {
		var p = buildPatterns();
		variables.MIXED_ARGS_PATTERN = p.mixed;
		variables.CFLOOP_ARRAY_PATTERN = p.cfloop;
		variables.FILTER_PATTERN = p.filter;
		variables.PRESERVE_PATTERN = p.preserve;
		variables.EVALUATE_PATTERN = p.evaluate;
		variables.FUNC_DEF_PATTERN = p.funcDef;
		variables.FUNC_PARAMS_PATTERN = p.funcParams;
		variables.TODO_PATTERN = p.todo;
		variables.RESOURCE_AFTER_WILDCARD = p.resource;
		variables.COMPLEXITY_PATTERNS = p.complexity;
	}

	private struct function buildPatterns() {
		var bs = chr(92);
		var q = chr(34);
		var h = chr(35);
		var S = bs & "s";
		var W = bs & "w";
		var B = bs & "b";
		var LP = bs & "(";
		var RP = bs & ")";

		var lt = chr(60);  // <
		return {
			mixed: "(hasMany|hasOne|belongsTo|validatesPresenceOf|validatesUniquenessOf|validatesFormatOf)" & S & "*" & LP & S & "*" & q & "[^" & q & "]+" & q & S & "*," & S & "*" & W & "+" & S & "*=",
			cfloop: lt & "cfloop" & S & "+array" & S & "*=" & S & "*" & q & h & h & W & "+" & h & h & q,
			filter: "(filters|beforeFilter|verifies)" & S & "*" & LP & "[^)]*(?:through|handler)" & S & "*=" & S & "*" & q & "(" & W & "+)" & q,
			preserve: "preserveSingleQuotes" & S & "*" & LP,
			evaluate: B & "evaluate" & S & "*" & LP,
			funcDef: "function" & S & "+(" & W & "+)" & S & "*" & LP,
			funcParams: "function" & S & "+" & W & "+" & S & "*" & LP & "([^)]+)" & RP,
			todo: "(" & bs & "//" & "|<!---?)" & S & "*(TODO|FIXME|HACK|XXX|BUG):?",
			resource: bs & ".resources" & S & "*" & LP,
			complexity: [
				B & "if" & S & "*" & LP,
				B & "elseif" & S & "*" & LP,
				B & "case" & S & "+",
				B & "for" & S & "*" & LP,
				B & "while" & S & "*" & LP,
				B & "catch" & S & "*" & LP,
				bs & "&" & bs & "&",
				bs & "|" & bs & "|"
			]
		};
	}

	// ── Private — Utility ───────────────────────────

	private struct function getDefaultConfig() {
		return {
			maxComplexity: 10,
			maxFileLength: 500,
			maxFunctionLength: 50,
			exclude: ["vendor/", "node_modules/", ".git/", "testbox/", "tests/", "build/"]
		};
	}

	private boolean function isExcluded(required string path) {
		for (var pattern in variables.config.exclude) {
			if (findNoCase(pattern, arguments.path)) return true;
		}
		return false;
	}

	private numeric function calculateCyclomaticComplexity(required string code) {
		var complexity = 1;
		for (var pattern in variables.COMPLEXITY_PATTERNS) {
			complexity += arrayLen(reFindAll(pattern, arguments.code, false));
		}
		return complexity;
	}

	private string function extractFunctionBody(required string content, required numeric startPos) {
		var braceCount = 0;
		var i = arguments.startPos;

		// Find opening brace
		while (i <= len(arguments.content)) {
			if (mid(arguments.content, i, 1) == "{") { braceCount = 1; i++; break; }
			i++;
		}

		// Track start position, then find closing brace
		var bodyStart = i;
		while (i <= len(arguments.content) && braceCount > 0) {
			var char = mid(arguments.content, i, 1);
			if (char == "{") braceCount++;
			else if (char == "}") braceCount--;
			i++;
		}

		// Single mid() call instead of per-character concatenation
		return mid(arguments.content, bodyStart, max(0, i - bodyStart - 1));
	}

	private numeric function getLineNumber(required string content, required numeric pos) {
		return listLen(left(arguments.content, arguments.pos), chr(10));
	}

	private void function finalizeMetrics(required struct results) {
		// Average complexity
		var totalComplexity = 0;
		for (var f in results.complexFunctions) {
			totalComplexity += f.complexity;
		}
		if (arrayLen(results.complexFunctions) > 0) {
			results.metrics.averageComplexity = round(totalComplexity / arrayLen(results.complexFunctions));
		}

		// Health score
		var score = 100;
		score -= arrayLen(results.antiPatterns) * 8;
		score -= arrayLen(results.codeSmells) * 3;
		score -= arrayLen(results.complexFunctions) * 5;
		results.metrics.healthScore = max(0, score);

		if (score >= 90) results.metrics.grade = "A";
		else if (score >= 80) results.metrics.grade = "B";
		else if (score >= 70) results.metrics.grade = "C";
		else if (score >= 60) results.metrics.grade = "D";
		else results.metrics.grade = "F";
	}

	/**
	 * Find all regex matches (returns array of structs with pos and groups)
	 */
	private array function reFindAll(required string pattern, required string text, boolean returnGroups = false) {
		var matches = [];
		var start = 1;
		while (start <= len(arguments.text)) {
			var found = reFind(arguments.pattern, arguments.text, start, true);
			if (found.pos[1] == 0) break;

			var match = {pos: found.pos[1], len: found.len[1]};
			if (arguments.returnGroups && arrayLen(found.pos) > 1) {
				match.groups = [];
				for (var i = 2; i <= arrayLen(found.pos); i++) {
					if (found.pos[i] > 0) {
						arrayAppend(match.groups, mid(arguments.text, found.pos[i], found.len[i]));
					} else {
						arrayAppend(match.groups, "");
					}
				}
			}

			arrayAppend(matches, match);
			start = found.pos[1] + max(1, found.len[1]);
		}
		return matches;
	}

}
