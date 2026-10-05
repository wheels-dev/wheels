/**
 * The offline docs index behind `wheels lookup` and the `lookup` MCP tool.
 *
 * Reads cli/lucli/data/docs-index.json, which tools/build/scripts/build-docs-index.mjs
 * writes at release and snapshot build time: one entry per API function
 * (`kind: "api"`) and one per guide section (`kind: "guides"`). No network, no
 * server, no project needed.
 *
 * lookup(query) answers in one of three modes:
 *   - "id":     the query is an entry id from an earlier result (api:model.findAll,
 *               guides:basics/routing#nested-resources); returns that whole entry;
 *   - "exact":  the query is a function name, optionally with () or a scope
 *               (findAll, model.findAll); returns every matching API entry in full;
 *   - "search": anything else; returns ranked results with a snippet, a link
 *               and the id to ask for the whole entry.
 *
 * The parsed index is cached in the server scope by path and modification time,
 * so a long-lived MCP server parses the ~3 MB file once.
 */
component {

	variables.KINDS = ["all", "api", "guides"];
	variables.MAX_LIMIT = 20;
	variables.SNIPPET_LENGTH = 300;

	public any function init(required string path) {
		variables.path = arguments.path;
		return this;
	}

	public boolean function exists() {
		return fileExists(variables.path);
	}

	/**
	 * frameworkVersion, apiSource and guidesSlug: what the index was built from.
	 */
	public struct function meta() {
		var data = $load();
		return {
			"frameworkVersion" = data.frameworkVersion ?: "",
			"apiSource" = data.apiSource ?: "",
			"guidesSlug" = data.guidesSlug ?: ""
		};
	}

	public struct function lookup(required string query, string kind = "all", numeric limit = 5) {
		var q = trim(arguments.query);
		var kind = lCase(trim(arguments.kind));
		if (!len(q)) {
			throw(type = "Wheels.InvalidArguments", message = "Missing a query: a function name, a phrase, or an id from an earlier result.");
		}
		if (!arrayFindNoCase(variables.KINDS, kind)) {
			throw(type = "Wheels.InvalidArguments", message = "Unknown kind ""#arguments.kind#"": use all, api or guides.");
		}
		var limit = max(1, min(variables.MAX_LIMIT, int(val(arguments.limit))));
		var data = $load();
		var rv = {"query" = q, "kind" = kind, "limit" = limit, "mode" = "search", "entries" = [], "results" = []};

		if (reFindNoCase("^(api|guides):", q)) {
			rv.mode = "id";
			for (var entry in data.entries) {
				if (compareNoCase(entry.id, q) == 0) {
					arrayAppend(rv.entries, entry);
				}
			}
			return rv;
		}

		if (kind != "guides") {
			var exact = $exactApiMatches(data.entries, q);
			if (arrayLen(exact)) {
				rv.mode = "exact";
				rv.entries = exact;
				return rv;
			}
		}

		rv.results = $search(data, q, kind, limit);
		return rv;
	}

	/**
	 * API entries whose name is the query: `findAll`, `findAll()`, or a scope-qualified
	 * `model.findAll` (which must also name one of the entry's scopes).
	 */
	public array function $exactApiMatches(required array entries, required string query) {
		var name = reReplace(trim(arguments.query), "\(\s*\)$", "");
		var scope = "";
		if (listLen(name, ".") == 2) {
			scope = listFirst(name, ".");
			name = listLast(name, ".");
		}
		if (!reFind("^[A-Za-z_$][A-Za-z0-9_$]*$", name)) {
			return [];
		}
		var rv = [];
		for (var entry in arguments.entries) {
			if (entry.kind != "api" || compareNoCase(entry.name, name) != 0) {
				continue;
			}
			if (len(scope) && !arrayFindNoCase(entry.scopes, scope)) {
				continue;
			}
			arrayAppend(rv, entry);
		}
		return rv;
	}

	private array function $search(required struct data, required string query, required string kind, required numeric limit) {
		var tokens = $tokens(arguments.query);
		if (!arrayLen(tokens)) {
			return [];
		}
		var phrase = lCase(arrayToList(tokens, " "));
		var scored = [];
		var matchedAll = false;
		for (var i = 1; i <= arrayLen(arguments.data.entries); i++) {
			var entry = arguments.data.entries[i];
			if (arguments.kind != "all" && entry.kind != arguments.kind) {
				continue;
			}
			var hit = $score(entry, arguments.data.searchText[i], tokens, phrase);
			if (hit.score > 0) {
				hit.index = i;
				arrayAppend(scored, hit);
				if (hit.all) matchedAll = true;
			}
		}
		// Every word present beats some words present: when any entry has them all,
		// the partial matches are left out.
		if (matchedAll) {
			scored = arrayFilter(scored, function(hit) {
				return hit.all;
			});
		}
		arraySort(scored, function(a, b) {
			if (a.score != b.score) {
				return a.score > b.score ? -1 : 1;
			}
			return a.index < b.index ? -1 : 1;
		});
		var rv = [];
		for (var hit in scored) {
			if (arrayLen(rv) >= arguments.limit) {
				break;
			}
			arrayAppend(rv, $result(arguments.data.entries[hit.index], tokens));
		}
		return rv;
	}

	/**
	 * Name and heading matches outweigh body text; a phrase match and every word
	 * present add a bonus.
	 */
	private struct function $score(required struct entry, required struct text, required array tokens, required string phrase) {
		var score = 0;
		var found = 0;
		for (var token in arguments.tokens) {
			var inTitle = findNoCase(token, arguments.text.title) > 0;
			var inBody = findNoCase(token, arguments.text.body) > 0;
			if (inTitle || inBody) found++;
			if (arguments.entry.kind == "api") {
				if (compareNoCase(arguments.entry.name, token) == 0) score += 100;
				else if (left(lCase(arguments.entry.name), len(token)) == token) score += 40;
				else if (inTitle) score += 20;
			} else if (inTitle) {
				score += 10;
			}
			if (inBody) score += min(5, $count(arguments.text.body, token));
		}
		if (found == 0) {
			return {score = 0, all = false};
		}
		var all = found == arrayLen(arguments.tokens);
		if (all) score += 15;
		if (arrayLen(arguments.tokens) > 1) {
			if (findNoCase(arguments.phrase, arguments.text.title)) score += 30;
			else if (findNoCase(arguments.phrase, arguments.text.body)) score += 10;
		}
		return {score = score, all = all};
	}

	private struct function $result(required struct entry, required array tokens) {
		var e = arguments.entry;
		if (e.kind == "api") {
			return {
				"id" = e.id,
				"kind" = "api",
				"title" = e.name & "()",
				"url" = e.url,
				"snippet" = $firstLine(e.hint)
			};
		}
		return {
			"id" = e.id,
			"kind" = "guides",
			"title" = compare(e.page, e.heading) == 0 ? e.page : e.page & " › " & e.heading,
			"url" = e.url,
			"snippet" = $snippet(e.text, arguments.tokens)
		};
	}

	/**
	 * Up to SNIPPET_LENGTH characters of the text, around the first matching word.
	 */
	public string function $snippet(required string text, required array tokens) {
		var flat = trim(reReplace(arguments.text, "\s+", " ", "all"));
		var at = 0;
		for (var token in arguments.tokens) {
			var pos = findNoCase(token, flat);
			if (pos > 0 && (at == 0 || pos < at)) at = pos;
		}
		var start = max(1, at - 80);
		var piece = mid(flat, start, variables.SNIPPET_LENGTH);
		return (start > 1 ? "…" : "") & piece & (start + variables.SNIPPET_LENGTH <= len(flat) ? "…" : "");
	}

	private string function $firstLine(required string text) {
		var line = trim(listFirst(arguments.text, chr(10)));
		return len(line) > variables.SNIPPET_LENGTH ? left(line, variables.SNIPPET_LENGTH) & "…" : line;
	}

	/**
	 * Lower-cased words of two or more characters.
	 */
	public array function $tokens(required string query) {
		var rv = [];
		for (var word in listToArray(lCase(arguments.query), " ,;:!?()[]{}""'`|/\" & chr(9))) {
			word = reReplace(word, "^[^a-z0-9_$]+|[^a-z0-9_$]+$", "", "all");
			if (len(word) >= 2 && !arrayFind(rv, word)) {
				arrayAppend(rv, word);
			}
		}
		return rv;
	}

	private numeric function $count(required string haystack, required string needle) {
		var n = 0;
		var pos = findNoCase(arguments.needle, arguments.haystack);
		while (pos > 0 && n < 5) {
			n++;
			pos = findNoCase(arguments.needle, arguments.haystack, pos + len(arguments.needle));
		}
		return n;
	}

	/**
	 * The parsed index plus, per entry, the lower-cased title and body the search
	 * compares against. Cached in the server scope by path and modification time.
	 */
	private struct function $load() {
		if (!exists()) {
			throw(type = "Wheels.DocsIndexMissing", message = "No docs index at #variables.path#.");
		}
		var info = getFileInfo(variables.path);
		var key = "wheelsDocsIndex:" & variables.path;
		var stamp = info.lastModified & "|" & info.size;
		if (structKeyExists(server, key) && server[key].stamp == stamp) {
			return server[key].data;
		}
		var data = deserializeJSON(fileRead(variables.path, "utf-8"));
		if (!isStruct(data) || !structKeyExists(data, "entries") || !isArray(data.entries)) {
			throw(type = "Wheels.DocsIndexMissing", message = "The docs index at #variables.path# is not a valid index.");
		}
		data.searchText = [];
		for (var entry in data.entries) {
			if (entry.kind == "api") {
				arrayAppend(data.searchText, {
					title = entry.name,
					body = entry.hint & " " & entry.section & " " & entry.category
				});
			} else {
				arrayAppend(data.searchText, {
					title = entry.page & " " & entry.heading,
					body = entry.text
				});
			}
		}
		server[key] = {stamp = stamp, data = data};
		return data;
	}

}
