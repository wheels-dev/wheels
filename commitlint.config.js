/**
 * Commitlint configuration for conventional commits.
 *
 * Valid types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
 *
 * Examples:
 *   feat: add route model binding
 *   fix(model): correct association eager loading
 *   docs: update migration guide
 *   ci: add commit message validation to PR workflow
 */
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Wheels-specific scope allowlist (optional — empty means all scopes allowed)
    'scope-enum': [
      2,
      'always',
      [
        'model',
        'controller',
        'view',
        'router',
        'middleware',
        'migration',
        'cli',
        'test',
        'config',
        'di',
        'job',
        'mailer',
        'plugin',
        'sse',
        'seed',
        'docs'
      ]
    ],
    // Allow empty scope (scope is optional)
    'scope-empty': [0, 'never'],
    // Subject must not be empty
    'subject-empty': [2, 'never'],
    // Type must not be empty
    'type-empty': [2, 'never'],
    // Max header length
    'header-max-length': [2, 'always', 100]
  }
};
