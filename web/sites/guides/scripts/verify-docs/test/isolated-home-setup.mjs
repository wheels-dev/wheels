// Preloaded by `pnpm test:docs-harness` (node --import): the harness tests spawn
// `wheels` and create fixture apps too, so they run in the same kind of throwaway
// CLI home as verify:docs (#4422). Not a test file: the *.test.mjs glob skips it.
import { enterIsolatedHome } from '../lib/isolated-home.mjs';

enterIsolatedHome();
