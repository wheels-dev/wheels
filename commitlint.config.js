/**
 * Commitlint configuration for conventional commits.
 *
 * Required: type from the conventional-commits list, a non-empty
 * subject, header ≤ 100 chars, subject not in ALL-CAPS.
 *
 * Scope is OPTIONAL and unrestricted — pick any short noun that
 * makes the commit easier to scan in `git log` (e.g. `model`,
 * `web/blog`), or omit it entirely. The scope allowlist was
 * dropped because picking the "right" scope produced more friction
 * than value; conventional types still power changelog grouping.
 *
 * Valid types: feat, fix, docs, style, refactor, perf, test,
 * build, ci, chore, revert.
 *
 * Examples:
 *   feat: add route model binding
 *   fix(model): correct association eager loading
 *   docs(web/blog): publish LuCLI post
 *   ci: tighten visual regression path filter
 */
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'subject-empty': [2, 'never'],
    'type-empty': [2, 'never'],
    'header-max-length': [2, 'always', 100],
    // Allow sentence-case, pascal-case, start-case subjects (for proper nouns
    // like "Giscus", "Buttondown", "CockroachDB"). Only reject ALL-CAPS.
    'subject-case': [2, 'never', ['upper-case']]
  }
};
