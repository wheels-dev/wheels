/**
 * A deliberately small source reader for in-place scaffold edits, not a CFML
 * rewriter. Tokens retain ORIGINAL offsets; comments never shift an edit.
 * Unsupported/malformed source fails closed so the caller can offer a warning.
 */
component {

	public struct function scan(required string source) {
		var result = {valid: true, tokens: [], reason: ""};
		var i = 1;
		var size = Len(arguments.source);
		var stack = [];
		var depth = 0;
		while (i <= size) {
			var ch = Mid(arguments.source, i, 1);
			if (ReFind("\s", ch)) { i++; continue; }
			var start = i;
			// CFML tag comments can nest. Line/block comment delimiters inside
			// a string are just characters, handled by the string branch below.
			if (Mid(arguments.source, i, 5) == (Chr(60) & "!---")) {
				i = $tagCommentEnd(arguments.source, i);
				if (!i) return {valid: false, tokens: [], reason: "unterminated tag comment"};
				continue;
			}
			if (Mid(arguments.source, i, 2) == "//") {
				while (i <= size && !ListFind("10,13", Asc(Mid(arguments.source, i, 1)))) i++;
				continue;
			}
			if (Mid(arguments.source, i, 2) == "/*") {
				var ending = Find("*/", arguments.source, i + 2);
				if (!ending) return {valid: false, tokens: [], reason: "unterminated block comment"};
				i = ending + 2;
				continue;
			}
			var kind = "symbol";
			var value = ch;
			if (ch == '"' || ch == "'") {
				kind = "string";
				var quote = ch;
				var closed = false;
				value = "";
				i++;
				while (i <= size) {
					ch = Mid(arguments.source, i, 1);
					if (ch == quote) {
						if (Mid(arguments.source, i + 1, 1) == quote) { value &= quote; i += 2; continue; }
						i++; closed = true; break;
					}
					if (ch == Chr(35)) {
						if (Mid(arguments.source, i + 1, 1) != Chr(35)) {
							return {valid: false, tokens: [], reason: "interpolated strings require manual wiring"};
						}
						i++;
					}
					value &= ch;
					i++;
				}
				if (!closed) return {valid: false, tokens: [], reason: "unterminated string"};
			} else if (ReFind("[A-Za-z0-9_$]", ch)) {
				kind = "word";
				i++;
				while (i <= size && ReFind("[A-Za-z0-9_$]", Mid(arguments.source, i, 1))) i++;
				value = Mid(arguments.source, start, i - start);
			} else {
				i++;
			}
			var token = {value: value, kind: kind, start: start, end: i - 1, depth: depth, pair: 0};
			ArrayAppend(result.tokens, token);
			var idx = ArrayLen(result.tokens);
			if (kind == "symbol") {
				if (Find(value, "({[")) {
					ArrayAppend(stack, idx);
					if (value == "{") depth++;
				} else if (Find(value, ")}]")) {
					if (!ArrayLen(stack)) return {valid: false, tokens: [], reason: "unbalanced delimiters"};
					var openIdx = stack[ArrayLen(stack)];
					var open = result.tokens[openIdx].value;
					if (Find(open, "({[") != Find(value, ")}]")) return {valid: false, tokens: [], reason: "unbalanced delimiters"};
					result.tokens[openIdx].pair = idx;
					result.tokens[idx].pair = openIdx;
					ArrayDeleteAt(stack, ArrayLen(stack));
					if (value == "}") depth--;
				}
			}
		}
		if (ArrayLen(stack)) return {valid: false, tokens: [], reason: "unbalanced delimiters"};
		return result;
	}

	/** Preserve every existing association; ambiguous declarations need a human. */
	public struct function inverse(required string source, required string association, required string childName) {
		var parsed = scan(arguments.source);
		var config = method(parsed, "config");
		if (!config.valid) return {ready: false, reason: config.reason};
		var tokens = parsed.tokens;
		var found = false;
		for (var i = 1; i + 2 <= ArrayLen(tokens); i++) {
			if (tokens[i].kind == "string" && ListFindNoCase("hasMany,hasOne,belongsTo", tokens[i].value)) {
				return {ready: false, reason: "possible indirect association declaration"};
			}
			if (tokens[i].kind != "word" || !ListFindNoCase("hasMany,hasOne,belongsTo", tokens[i].value) || tokens[i + 1].value != "(") continue;
			var declaration = $associationCall(tokens, i);
			if (!Len(declaration.name)) return {ready: false, reason: "dynamic association name"};
			if (declaration.name == arguments.association || declaration.target == arguments.childName) {
				if (found || !declaration.simple || declaration.name != arguments.association || tokens[i].value != "hasMany"
					|| i < config.first || i > config.last || tokens[i].depth != 2) {
					return {ready: false, reason: "existing custom association preserved"};
				}
				found = true;
			}
		}
		if (found) return {ready: true, content: arguments.source};
		var nl = Find(Chr(13) & Chr(10), arguments.source) ? Chr(13) & Chr(10) : Chr(10);
		var lineStart = config.declaration;
		while (lineStart > 1 && Mid(arguments.source, lineStart - 1, 1) != Chr(10)) lineStart--;
		var prefix = Mid(arguments.source, lineStart, config.declaration - lineStart);
		var indent = ReReplace(prefix, "[^\t ].*$", "") & Chr(9);
		var addition = nl & indent & 'hasMany(name="' & arguments.association & '");' & nl;
		return {ready: true, content: Insert(addition, arguments.source, config.brace)};
	}

	/** Read literal association names in either argument order, without evaluating code. */
	private struct function $associationCall(required array tokens, required numeric start) {
		var tokens = arguments.tokens;
		var i = arguments.start;
		var result = {name: "", target: "", simple: false};
		var closing = tokens[i + 1].pair;
		if (!closing) return result;
		if (tokens[i + 2].kind == "string") {
			if (i + 3 != closing && tokens[i + 3].value != ",") return result;
			result.name = tokens[i + 2].value;
		}
		for (var j = i + 2; j + 2 < closing; j++) {
			if (tokens[j].kind != "word" || !ListFindNoCase("name,modelName", tokens[j].value) || tokens[j + 1].value != "=") continue;
			// A literal prefix of an expression is NOT a static association
			// name (e.g. name="com" & "ments"). Fail closed for dynamic targets.
			if (tokens[j + 2].kind != "string" || (j + 3 != closing && tokens[j + 3].value != ",")) return {name: "", target: "", simple: false};
			if (tokens[j].value == "name") result.name = tokens[j + 2].value;
			if (tokens[j].value == "modelName") result.target = tokens[j + 2].value;
		}
		result.simple = (closing == i + 3 && tokens[i + 2].kind == "string")
			|| (closing == i + 5 && tokens[i + 2].value == "name" && tokens[i + 3].value == "=" && tokens[i + 4].kind == "string");
		return result;
	}

	/** Only the conventional single finder assignment in show() is rewritten. */
	public struct function showInclude(required string source, required string parentVar, required string parentModel, required string association) {
		var parsed = scan(arguments.source);
		var action = method(parsed, "show");
		if (!action.valid) return {ready: false, reason: action.reason};
		var tokens = parsed.tokens;
		var first = action.first;
		var count = action.last - first + 1;
		var skipped = {ready: false, reason: "custom show() finder or include expression"};
		if (count < 14) return skipped;
		var prefix = [arguments.parentVar, "=", "model", "(", arguments.parentModel, ")", ".", "findByKey", "("];
		for (var i = 1; i <= ArrayLen(prefix); i++) {
			if (tokens[first + i - 1].value != prefix[i]) return skipped;
			if (i == 5 && tokens[first + i - 1].kind != "string") return skipped;
			if (i != 5 && tokens[first + i - 1].kind == "string") return skipped;
		}
		var closing = tokens[first + 8].pair;
		if (closing != action.last - 1 || tokens[action.last].value != ";") return skipped;
		var finder = $finderArguments(tokens, first + 9, closing);
		if (!finder.valid) return skipped;
		var updated = arguments.source;
		if (finder.includePos) {
			var include = tokens[finder.includePos];
			// Nested/dynamic include syntax is not a flat list. Leave it alone.
			if (Len(Trim(include.value)) && !ReFind("^\s*[A-Za-z][A-Za-z0-9_]*(\s*,\s*[A-Za-z][A-Za-z0-9_]*)*\s*$", include.value)) return skipped;
			for (var item in ListToArray(include.value)) {
				if (Trim(item) == arguments.association) return {ready: true, content: updated};
			}
			updated = Insert((Len(Trim(include.value)) ? "," : "") & arguments.association, updated, include.end - 1);
		} else {
			updated = Insert(', include="' & arguments.association & '"', updated, tokens[closing].start - 1);
			if (!finder.named) updated = Insert("key=", updated, tokens[finder.keyPos].start - 1);
		}
		return {ready: true, content: updated};
	}

	/** Accept only params.key or key=params.key plus a literal include. */
	private struct function $finderArguments(required array tokens, required numeric start, required numeric closing) {
		var tokens = arguments.tokens;
		var cursor = arguments.start;
		var closing = arguments.closing;
		var result = {valid: false, named: tokens[cursor + 1].value == "=", keyPos: 0, includePos: 0};
		if (!result.named) {
			result.keyPos = cursor;
			if (cursor + 3 != closing) return result;
		} else {
			while (cursor < closing) {
				if (cursor + 2 >= closing || tokens[cursor].kind != "word" || tokens[cursor + 1].value != "=") return result;
				if (tokens[cursor].value == "key" && !result.keyPos) {
					result.keyPos = cursor + 2;
					cursor += 5;
				} else if (tokens[cursor].value == "include" && !result.includePos && tokens[cursor + 2].kind == "string") {
					result.includePos = cursor + 2;
					cursor += 3;
				} else return result;
				if (cursor == closing) break;
				if (cursor >= closing || tokens[cursor].value != ",") return result;
				cursor++;
				if (cursor == closing) return result;
			}
		}
		var keyPos = result.keyPos;
		if (!keyPos || keyPos + 2 >= closing || tokens[keyPos].value != "params" || tokens[keyPos + 1].value != "." || tokens[keyPos + 2].value != "key") return result;
		for (var p = keyPos; p <= keyPos + 2; p++) if (tokens[p].kind == "string") return result;
		result.valid = true;
		return result;
	}

	/**
	 * Recognize the scaffold's param + single output wrapper, not arbitrary
	 * template programs. Ignore tag comments, HTML comments, quoted attributes
	 * and output expressions before looking at tags. All offsets stay original.
	 */
	public numeric function viewAnchor(required string source, required string parentVar) {
		var i = 1;
		var size = Len(arguments.source);
		var stack = [];
		var outputSeen = false;
		var paramSeen = false;
		var anchor = 0;
		while (i <= size) {
			var ch = Mid(arguments.source, i, 1);
			if (ReFind("\s", ch)) { i++; continue; }
			if (Mid(arguments.source, i, 5) == (Chr(60) & "!---")) {
				i = $tagCommentEnd(arguments.source, i);
				if (!i) return 0;
				continue;
			}
			if (Mid(arguments.source, i, 4) == (Chr(60) & "!--")) {
				var endComment = Find("-->", arguments.source, i + 4);
				if (!endComment) return 0;
				i = endComment + 3; continue;
			}
			// No active markup/code outside the conventional wrapper.
			if (anchor) return 0;
			if (ch == Chr(35)) {
				if (!outputSeen) return 0;
				i = $expressionEnd(arguments.source, i);
				if (!i) return 0;
				continue;
			}
			if (ch != Chr(60)) { if (!outputSeen) return 0; i++; continue; }
			var start = i;
			var tagQuote = "";
			i++;
			while (i <= size) {
				ch = Mid(arguments.source, i, 1);
				if (Len(tagQuote)) { if (ch == tagQuote) tagQuote = ""; }
				else if (ch == '"' || ch == "'") tagQuote = ch;
				else if (ch == Chr(62)) break;
				i++;
			}
			if (i > size) return 0;
			var tag = Mid(arguments.source, start, i - start + 1);
			i++;
			var match = ReFindNoCase("^<(/?)([A-Za-z]+)", tag, 1, true);
			if (!match.pos[1]) return 0;
			var closing = match.len[2] > 0;
			var name = LCase(Mid(tag, match.pos[3], match.len[3]));
			if (ListFind("script,style", name)) return 0;
			if (Left(name, 2) != "cf") { if (!outputSeen) return 0; continue; }
			if (name == "cfparam" && !paramSeen && !outputSeen) {
				if (!ReFindNoCase('^' & Chr(60) & 'cfparam\s+name\s*=\s*["'']' & arguments.parentVar & '["'']\s+default\s*=\s*["'']["'']\s*>$', tag)) return 0;
				paramSeen = true; continue;
			}
			if (name == "cfoutput" && !closing) {
				if (!paramSeen || outputSeen || !ReFindNoCase("^" & Chr(60) & "cfoutput\s*>$", tag)) return 0;
				outputSeen = true;
			} else if (!outputSeen) return 0;
			if (name == "cfset") {
				// Generated related blocks keep per-association seen-ID sets.
				// Recognize only those assignments, not arbitrary template code.
				if (closing || !$relatedSeenAssignment(tag)) return 0;
				continue;
			}
			if (ListFind("cfelse,cfelseif", name)) {
				if (!ArrayLen(stack) || stack[ArrayLen(stack)] != "cfif") return 0;
				continue;
			}
			if (!ListFind("cfoutput,cfif,cfloop", name)) return 0;
			if (closing) {
				if (!ArrayLen(stack) || stack[ArrayLen(stack)] != name) return 0;
				ArrayDeleteAt(stack, ArrayLen(stack));
				if (name == "cfoutput") anchor = start;
			} else ArrayAppend(stack, name);
		}
		return ArrayLen(stack) ? 0 : anchor;
	}

	/** The only stateful statements emitted by the related-block template. */
	private boolean function $relatedSeenAssignment(required string tag) {
		var identifier = "[A-Za-z][A-Za-z0-9_]*";
		var initializer = "\s*=\s*\{\s*\}";
		var recordId = "\s*\[\s*" & identifier & "\.id\s*\]\s*=\s*true";
		return ReFindNoCase("^" & Chr(60) & "cfset\s+wheelsRelated" & identifier & "Seen(?:" & initializer & "|" & recordId & ")\s*>$", arguments.tag) > 0;
	}

	/** End offsets are exclusive; zero means malformed/unsupported source. */
	private numeric function $tagCommentEnd(required string source, required numeric start) {
		var nesting = 1;
		var i = arguments.start + 5;
		while (i <= Len(arguments.source) && nesting) {
			if (Mid(arguments.source, i, 5) == (Chr(60) & "!---")) { nesting++; i += 5; }
			else if (Mid(arguments.source, i, 4) == "--->") { nesting--; i += 4; }
			else i++;
		}
		return nesting ? 0 : i;
	}

	private numeric function $expressionEnd(required string source, required numeric start) {
		var i = arguments.start + 1;
		var quote = "";
		while (i <= Len(arguments.source)) {
			var ch = Mid(arguments.source, i, 1);
			if (Len(quote)) {
				if (ch == Chr(35)) return 0; // custom nested interpolation
				if (ch == quote) {
					if (Mid(arguments.source, i + 1, 1) == quote) i++;
					else quote = "";
				}
			} else if (ch == '"' || ch == "'") quote = ch;
			else if (ch == Chr(35)) return i + 1;
			i++;
		}
		return 0;
	}

	/** Return the body bounds of one conventional top-level script method. */
	public struct function method(required struct parsed, required string name) {
		var result = {valid: false, reason: "missing or custom " & arguments.name & "()"};
		if (!arguments.parsed.valid) { result.reason = arguments.parsed.reason; return result; }
		var tokens = arguments.parsed.tokens;
		if (!ArrayLen(tokens) || tokens[1].kind != "word" || tokens[1].value != "component") {
			result.reason = "only script components are wired automatically";
			return result;
		}
		var matches = [];
		for (var i = 1; i + 4 <= ArrayLen(tokens); i++) {
			if (tokens[i].kind == "word" && tokens[i].value == "function" && tokens[i + 1].kind == "word" && tokens[i + 1].value == arguments.name) {
				ArrayAppend(matches, i);
			}
		}
		if (ArrayLen(matches) != 1) return result;
		var pos = matches[1];
		if (tokens[pos].depth != 1 || tokens[pos + 2].value != "(" || tokens[pos + 3].value != ")" || tokens[pos + 4].value != "{") return result;
		return {valid: true, first: pos + 5, last: tokens[pos + 4].pair - 1, brace: tokens[pos + 4].end, declaration: tokens[pos].start};
	}
}
