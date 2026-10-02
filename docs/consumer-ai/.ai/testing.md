# Testing: changing settings in specs

Part of the Wheels application guide; start with `../CLAUDE.md`.

## Changing a setting in a spec

Read and write `application.wheels.<setting>` and restore it afterwards. Never write `application.$wheels.<setting>`: `$wheels` only exists while `onApplicationStart` runs, and because the framework reads from `$wheels` whenever that key exists, the write creates a one-key struct that every later request reads (errors like `key [MIXINS] doesn't exist`) until the test application is restarted.

```cfm
var original = application.wheels.cachePartials;
application.wheels.cachePartials = true;
try { /* exercise it */ } finally { application.wheels.cachePartials = original; }
```

To test partial caching, turn `cachePartials` on this way and call `application.wo.$clearCache("partial")` before and after, so cached output doesn't leak between specs.
