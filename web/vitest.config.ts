// Workspace-root config — only picks up tests when vitest is invoked
// from `web/` (e.g. `pnpm test` at the workspace root).
//
// Per-site `pnpm test` invocations run from `sites/<name>/` cwd and do
// NOT inherit this config's include glob. Each site that wants tests
// needs its own minimal `sites/<name>/vitest.config.ts` with
// `include: ['src/**/*.test.ts']`. See `sites/packages/vitest.config.ts`
// for an example.
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    include: ['sites/*/src/**/*.test.ts'],
    exclude: ['**/node_modules/**', '**/dist/**'],
  },
});
