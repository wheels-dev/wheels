/**
 * Exact, separator-qualified containment check for two ALREADY-CANONICAL filesystem
 * paths. Used by every path-boundary guard that confines a resolved target to a root
 * directory (dump output, zip extraction, package mappings, dev-asset/docs serving,
 * image-tag source resolution).
 *
 * Why a shared helper: the previous guards compared with CFML `==` / `CompareNoCase` /
 * `Left(x, n) != y`, all of which are CASE-INSENSITIVE. On a case-sensitive filesystem
 * a canonical target under a case-distinct sibling of the root (e.g. `/srv/app/...`
 * when the root is `/srv/App`) compared equal and was wrongly treated as contained.
 * Some sites also omitted the trailing-separator qualifier, so a prefix sibling
 * (`/srv/App-extra`) passed too.
 *
 * KEEP IN SYNC: the Wheels CLI carries its own copy of this logic in
 * `cli/lucli/Module.cfc` ($pathWithinExact / $nativeSeparator, #4090/#4130) because
 * the CLI runtime does not load this component. That copy is deliberately NOT identical:
 * (1) $pathWithinExact takes an optional `separator` argument so its specs can exercise
 * Windows behaviour on any host, and (2) its $nativeSeparator is public for the same
 * reason. Mirror behavioural changes here into that copy, preserving those two
 * differences. (The Global mixin `$nativePathSeparator` in global/util.cfm is NOT a
 * separate copy — it delegates to this component's $nativeSeparator.)
 *
 * [section: Internal]
 * [category: Security]
 */
component output="false" {

	/**
	 * True when `candidate` is `root` itself or a descendant of it.
	 *
	 * Both paths must be passed ALREADY CANONICALISED THE SAME WAY (getCanonicalPath on
	 * JVM engines, which reports the real on-disk case; a lexical `.`/`..` collapse on
	 * the JVM-free RustCFML). Canonicalising the root too — not only the candidate — is
	 * what keeps a root configured in a different case from its real on-disk spelling
	 * (e.g. `c:\app` vs `C:\App`) from falsely refusing its own descendants on a
	 * case-insensitive filesystem.
	 *
	 * The comparison is EXACT (`Compare() == 0`, case-sensitive on every engine,
	 * cross-engine invariant 20) and separator-qualified: exact-root equality is
	 * allowed, and a descendant must match the root plus a `/` boundary, so a
	 * case-distinct sibling or a `root + "-extra"` prefix sibling is rejected.
	 * Pure string work, so it behaves identically on every engine including RustCFML.
	 *
	 * @root The canonical root directory (any trailing separators are ignored).
	 * @candidate The canonical path to test for containment under root.
	 */
	public boolean function pathWithinExact(required string root, required string candidate) {
		// Normalise ONLY the platform's native separator. A backslash is a legal filename
		// byte on POSIX, so converting it there would merge a distinct sibling ("App\x")
		// into the root ("App/x"); only Windows uses "\" as a path separator.
		local.windows = ($nativeSeparator() == "\");
		local.cand = local.windows ? Replace(arguments.candidate, "\", "/", "all") : arguments.candidate;
		local.baseInput = local.windows ? Replace(arguments.root, "\", "/", "all") : arguments.root;
		local.base = REReplace(local.baseInput, "/+$", "");
		if (Compare(local.cand, local.base) == 0) {
			return true;
		}
		return Len(local.cand) > Len(local.base)
			&& Compare(Left(local.cand, Len(local.base) + 1), local.base & "/") == 0;
	}

	/**
	 * The platform's native path separator. Prefers java.io.File.separator (JVM); falls
	 * back to the OS name when no JVM is present (the JVM-free RustCFML); defaults to the
	 * POSIX "/". It is NEVER inferred from seeing a backslash in a path — a backslash is a
	 * legal filename byte on POSIX, not evidence of a Windows separator.
	 *
	 * Public (with the `$` internal-prefix) so the Global mixin `$nativePathSeparator`
	 * (global/util.cfm) can delegate to it rather than duplicate the logic — this is the
	 * single source of the separator detection for the framework runtime.
	 */
	public string function $nativeSeparator() {
		try {
			local.sep = CreateObject("java", "java.io.File").separator;
			if (local.sep == "\" || local.sep == "/") {
				return local.sep;
			}
		} catch (any e) {
		}
		try {
			if (StructKeyExists(server, "os") && StructKeyExists(server.os, "name") && FindNoCase("windows", server.os.name)) {
				return "\";
			}
		} catch (any e) {
		}
		return "/";
	}

}
