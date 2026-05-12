/**
 * Code statistics and annotation extraction service.
 *
 * Scans project directories for file counts, lines of code, comments,
 * and developer annotations (TODO, FIXME, etc.). All operations are
 * local file reads — no running server required.
 */
component {

	public function init(
		required any helpers,
		required string projectRoot
	) {
		variables.helpers = arguments.helpers;
		variables.projectRoot = arguments.projectRoot;
		return this;
	}

	/**
	 * Gather code statistics across all project directories.
	 */
	public struct function getStats() {
		var categories = [
			{name: "Controllers", path: "app/controllers", extensions: "cfc"},
			{name: "Models", path: "app/models", extensions: "cfc"},
			{name: "Views", path: "app/views", extensions: "cfm"},
			{name: "Helpers", path: "app/helpers", extensions: "cfc"},
			{name: "Tests", path: "tests/specs", extensions: "cfc"},
			{name: "Migrations", path: "app/migrator/migrations", extensions: "cfc"},
			{name: "Config", path: "config", extensions: "cfm"}
		];

		var results = [];
		var totalFiles = 0;
		var totalLOC = 0;
		var totalComments = 0;
		var totalBlanks = 0;
		var totalLines = 0;
		var allFiles = [];

		for (var cat in categories) {
			var dirPath = variables.projectRoot & "/" & cat.path;
			var catResult = {
				name: cat.name,
				files: 0,
				loc: 0,
				comments: 0,
				blanks: 0,
				total: 0
			};

			if (directoryExists(dirPath)) {
				var fileList = directoryList(dirPath, true, "path", "*." & cat.extensions);
				catResult.files = arrayLen(fileList);

				for (var filePath in fileList) {
					try {
						var analysis = analyzeFile(filePath);
						catResult.loc += analysis.loc;
						catResult.comments += analysis.comments;
						catResult.blanks += analysis.blanks;
						catResult.total += analysis.total;
						arrayAppend(allFiles, {path: filePath, lines: analysis.total});
					} catch (any e) {
						// Skip unreadable files
					}
				}
			}

			totalFiles += catResult.files;
			totalLOC += catResult.loc;
			totalComments += catResult.comments;
			totalBlanks += catResult.blanks;
			totalLines += catResult.total;
			arrayAppend(results, catResult);
		}

		// Sort allFiles by line count descending for top-10
		arraySort(allFiles, function(a, b) { return b.lines - a.lines; });
		var topFiles = arrayLen(allFiles) > 10 ? allFiles.slice(1, 10) : allFiles;

		// Make paths relative
		for (var i = 1; i <= arrayLen(topFiles); i++) {
			topFiles[i].path = replace(topFiles[i].path, variables.projectRoot & "/", "");
		}

		var testLOC = 0;
		var codeLOC = 0;
		for (var cat in results) {
			if (cat.name == "Tests") {
				testLOC = cat.loc;
			} else {
				codeLOC += cat.loc;
			}
		}

		return {
			categories: results,
			totals: {
				files: totalFiles,
				loc: totalLOC,
				comments: totalComments,
				blanks: totalBlanks,
				total: totalLines
			},
			codeToTestRatio: codeLOC > 0 ? numberFormat(testLOC / codeLOC, "0.00") : "0.00",
			avgLinesPerFile: totalFiles > 0 ? round(totalLines / totalFiles) : 0,
			topFiles: topFiles
		};
	}

	/**
	 * Extract developer annotations (TODO, FIXME, etc.) from source files.
	 */
	public struct function getNotes(
		string annotations = "TODO,FIXME,OPTIMIZE",
		string custom = ""
	) {
		var allAnnotations = arguments.annotations;
		if (len(arguments.custom)) {
			allAnnotations = listAppend(allAnnotations, arguments.custom);
		}
		var annotationTypes = listToArray(uCase(allAnnotations));

		var scanDirs = ["app", "config", "tests"];
		var extensions = "cfc,cfm,js,css";
		var found = {};
		var totalCount = 0;

		// Initialize result buckets
		for (var aType in annotationTypes) {
			found[aType] = [];
		}

		for (var dir in scanDirs) {
			var dirPath = variables.projectRoot & "/" & dir;
			if (!directoryExists(dirPath)) continue;

			// Scan each extension
			for (var ext in listToArray(extensions)) {
				var fileList = directoryList(dirPath, true, "path", "*." & ext);
				for (var filePath in fileList) {
					try {
						scanFileForAnnotations(filePath, annotationTypes, found);
					} catch (any e) {
						// Skip unreadable files
					}
				}
			}
		}

		// Count totals
		for (var aType in annotationTypes) {
			totalCount += arrayLen(found[aType]);
		}

		return {
			annotations: found,
			types: annotationTypes,
			total: totalCount
		};
	}

	// ── Private helpers ──────────────────────────────────────

	private struct function analyzeFile(required string filePath) {
		var content = fileRead(arguments.filePath);
		var lines = listToArray(content, chr(10), true);
		var loc = 0;
		var comments = 0;
		var blanks = 0;
		var inBlockComment = false;

		for (var line in lines) {
			var trimmed = trim(line);

			if (!len(trimmed)) {
				blanks++;
				continue;
			}

			// CFML block comments: <!--- ... --->
			if (!inBlockComment && findNoCase("<!---", trimmed) && !findNoCase("--->", trimmed)) {
				inBlockComment = true;
				comments++;
				continue;
			}
			if (inBlockComment) {
				comments++;
				if (findNoCase("--->", trimmed)) {
					inBlockComment = false;
				}
				continue;
			}
			// Single-line CFML comment
			if (findNoCase("<!---", trimmed) && findNoCase("--->", trimmed)) {
				comments++;
				continue;
			}

			// JS/CSS block comments: /* ... */
			if (!inBlockComment && left(trimmed, 2) == "/*" && !find("*/", trimmed)) {
				inBlockComment = true;
				comments++;
				continue;
			}
			if (!inBlockComment && left(trimmed, 2) == "/*" && find("*/", trimmed)) {
				comments++;
				continue;
			}

			// Line comments
			if (left(trimmed, 2) == "//") {
				comments++;
				continue;
			}

			loc++;
		}

		return {loc: loc, comments: comments, blanks: blanks, total: arrayLen(lines)};
	}

	private void function scanFileForAnnotations(
		required string filePath,
		required array annotationTypes,
		required struct found
	) {
		var content = fileRead(arguments.filePath);
		var lines = listToArray(content, chr(10), true);
		var relativePath = replace(arguments.filePath, variables.projectRoot & "/", "");

		for (var lineNum = 1; lineNum <= arrayLen(lines); lineNum++) {
			var line = lines[lineNum];
			for (var aType in arguments.annotationTypes) {
				// Match annotation in comment context: // TODO: ..., <!--- FIXME: ... --->, /* OPTIMIZE: ... */
				var pattern = aType & "[\s:]+(.*)";
				var match = reFindNoCase(pattern, line, 1, true);
				if (match.pos[1] > 0) {
					var text = "";
					if (arrayLen(match.pos) > 1 && match.pos[2] > 0) {
						text = trim(mid(line, match.pos[2], match.len[2]));
						// Strip trailing comment delimiters
						text = reReplaceNoCase(text, "\s*--->.*$", "");
						text = reReplaceNoCase(text, "\s*\*/.*$", "");
					}
					arrayAppend(arguments.found[aType], {
						file: relativePath,
						line: lineNum,
						text: text
					});
				}
			}
		}
	}

}
