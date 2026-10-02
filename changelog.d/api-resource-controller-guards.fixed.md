- `wheels generate api-resource` controllers:
  - answer 400 with a clear message when the body has no `{"<model>": {...}}` wrapper or is not valid JSON, instead of a 500;
  - answer 404 for a key that cannot exist (`/api/products/abc`) instead of a 500;
  - return the index as a JSON array of records instead of query columns;
  - quote their top-level keys, so they are lower-case on every engine (`products`, `product`, `error`) rather than upper-case on Lucee.
  Existing generated controllers are unchanged; regenerate or copy the pattern (#3881)
