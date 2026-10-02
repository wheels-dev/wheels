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
		local.cand = Replace(arguments.candidate, "\", "/", "all");
		local.base = REReplace(Replace(arguments.root, "\", "/", "all"), "/+$", "");
		if (Compare(local.cand, local.base) == 0) {
			return true;
		}
		return Len(local.cand) > Len(local.base)
			&& Compare(Left(local.cand, Len(local.base) + 1), local.base & "/") == 0;
	}

}
