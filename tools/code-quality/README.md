# Code Quality (deterministic)

Static quality tooling for the Wheels framework, inspired by the CRAP-score
(Change Risk Anti-Patterns) idea: risk = cyclomatic complexity × test coverage.

## `cfml-complexity.py`

Computes McCabe cyclomatic complexity per function across CFML, handling both
CFScript (`if/for/while/case/catch/&&/||/?:`) and tag
(`<cfif>/<cfloop>/<cfcase>/<cfcatch>`) syntax, and computes a CRAP score:

```
CRAP = complexity^2 * (1 - coverage)^3 + complexity
```

### Report

```bash
python3 tools/code-quality/cfml-complexity.py vendor/wheels --top 40
```

### Deterministic gate (CI)

`baseline.json` pins the current per-function complexity. The gate fails only on
**new** complexity (a new function over the threshold, or an existing function
that grew), so existing hotspots are tolerated and burned down separately.

```bash
# regenerate the baseline after a deliberate refactor
python3 tools/code-quality/cfml-complexity.py vendor/wheels --baseline write > tools/code-quality/baseline.json

# gate (used by .github/workflows/code-quality.yml)
python3 tools/code-quality/cfml-complexity.py vendor/wheels --gate 30 --baseline tools/code-quality/baseline.json
```

Coverage for CRAP is not yet wired — Wheels' `CoverageService.cfc` is a no-op
stub, so `--coverage` is currently a sensitivity input, not a measured value.

## `cfml-coverage.py` (function coverage measurement)

Function-level coverage for the CORE suite is measured via source
instrumentation (the no-op `CoverageService.cfc` can't provide it):

```bash
# 1. Static complexity baseline (ids: <file>:<line>:<function>)
python3 tools/code-quality/cfml-complexity.py vendor/wheels --json /tmp/complexity.json

# 2. Instrument (backs up originals under vendor/.cfml-cov-backup/)
python3 tools/code-quality/cfml-coverage.py instrument vendor/wheels

# 3. RESTART the CF engine, then run the suite with ?coverage=true — the core
#    runner (vendor/wheels/tests/runner.cfm) resets server.__wheels_cov at
#    request start and dumps it to /tmp/wheels-core-coverage.json at the end.
#    The restart matters: engine-compiled mixins are cached per app instance,
#    and a warm app would execute pre-instrumentation bytecode.
curl -s "http://localhost:8080/wheels/core/tests?db=sqlite&format=json&coverage=true"

# 4. Combine into a CRAP ranking (writes crap-report.json)
python3 tools/code-quality/cfml-coverage.py combine vendor/wheels \
  /tmp/wheels-core-coverage.json /tmp/complexity.json

# 5. Always revert — never commit instrumented sources
python3 tools/code-quality/cfml-coverage.py revert vendor/wheels
```

Baseline (Lucee 7 + SQLite, measured 2026-08): **83.2% function coverage**
(2,175/2,614 functions — template pseudo-entries and migrator generator
templates excluded from the denominator). Known caveats:

- Coverage is per-leg: `databaseAdapters/*` paths for MySQL/Oracle/SQLServer/
  CockroachDB only execute on those matrix legs — a SQLite-only measurement
  structurally under-reports them.
- `public/` dev-console views and `public/mcp/` are exercised by the CLI
  suite, not the core suite.
- Instrumentation perturbs structural source-guards: `PublicComponentProductionSpec`
  asserts `$blockInProduction()` is the FIRST statement of every `Public.cfc`
  handler, and injected counters precede it — expect those 31 failures during
  an instrumented run; coverage capture is unaffected.
- `Test.cfc` (legacy RocketUnit) is deprecated and intentionally not
  coverage-targeted.

The masker handles CFML lexing: tag/line/block comments, doubled-quote
escapes (`""`), and `#expr#` interpolation with nested string literals
(`"#Replace(x, "'", "''", "all")#'"`) — backslashes are ordinary content,
CFML's only string escape is doubling.
