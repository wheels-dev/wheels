import { cpSync, existsSync, mkdtempSync, rmSync, symlinkSync } from 'node:fs';
import { homedir, tmpdir } from 'node:os';
import { join } from 'node:path';

/**
 * verify:docs runs every {test:cli} block with a real `wheels` binary. In the
 * developer's own CLI home those blocks change it: `wheels packages registry
 * refresh` deletes <home>/cache/packages, and fixture apps register servers
 * (#4422). So the harness runs the CLI in a throwaway home built from the real
 * one, and removes it when the run ends.
 */

/** The CLI home the installed binary uses: LUCLI_HOME, else ~/.wheels. */
export function sourceHome(env = process.env) {
  return env.LUCLI_HOME || join(homedir(), '.wheels');
}

/**
 * A new home with a copy of the source's modules/ (the wheels module, which CI
 * overlays from the checkout, and BaseModule.cfc) and a link to its express/
 * Lucee runtime, which is large and only read. Everything else (cache, servers,
 * settings) starts empty.
 */
export function createIsolatedHome({ source = sourceHome(), parent = tmpdir() } = {}) {
  const home = mkdtempSync(join(parent, 'wheels-verify-docs-home-'));
  if (existsSync(join(source, 'modules'))) {
    cpSync(join(source, 'modules'), join(home, 'modules'), { recursive: true, verbatimSymlinks: true });
  }
  if (existsSync(join(source, 'express'))) {
    symlinkSync(join(source, 'express'), join(home, 'express'));
  }
  return home;
}

/**
 * The environment that points the CLI at `home`. The Homebrew launcher
 * overwrites LUCLI_HOME, so the home also goes in as the lucli.home JVM
 * property, which LuCLI reads first.
 */
export function isolatedEnv(home, env = process.env) {
  const javaArgs = [env.LUCLI_JAVA_ARGS, `-Dlucli.home=${home}`].filter(Boolean).join(' ');
  return { ...env, LUCLI_HOME: home, LUCLI_JAVA_ARGS: javaArgs };
}

/**
 * Builds the isolated home and points this process's environment at it, so
 * every `wheels` the harness spawns (which inherit the environment) uses it.
 * Returns { home, source }; the home is removed when the process exits. A
 * process whose parent already did this (the harness unit tests' files, run
 * by `node --test`) keeps the parent's home.
 */
export function enterIsolatedHome() {
  if (process.env.WHEELS_VERIFY_DOCS_HOME) {
    return { home: process.env.WHEELS_VERIFY_DOCS_HOME, source: process.env.WHEELS_VERIFY_DOCS_SOURCE_HOME };
  }
  const source = sourceHome();
  const home = createIsolatedHome({ source });
  Object.assign(process.env, isolatedEnv(home), {
    WHEELS_VERIFY_DOCS_HOME: home,
    WHEELS_VERIFY_DOCS_SOURCE_HOME: source,
  });
  process.on('exit', () => rmSync(home, { recursive: true, force: true }));
  return { home, source };
}
