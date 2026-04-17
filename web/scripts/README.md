# web/scripts

Build-time generators for the static sites under `web/sites/`.

## generate-api-docs.mjs

Reads `docs/api/v{version}.json` (generated upstream from the Wheels
framework's docblock annotations) and emits one markdown file per
function into `web/sites/api/src/content/docs/v{version}/`.

### Run

```bash
node web/scripts/generate-api-docs.mjs 3.0.0
```

Output structure:
```
web/sites/api/src/content/docs/v3.0.0/
├── index.md                               # version overview
└── <section-slug>/
    ├── index.md                           # section overview
    └── <function-slug>.md                 # one per function
```

Safe to re-run — clears the per-version output directory first.
