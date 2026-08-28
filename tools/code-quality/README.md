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
