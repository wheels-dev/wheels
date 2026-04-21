# `wheels deploy` — Kamal Port Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port Basecamp Kamal's developer CLI into the Wheels CLI so users run `wheels deploy` to ship Dockerized apps to Linux servers, with no Ruby dependency. `kamal-proxy` (Go binary) stays as-is; only the orchestrator is ported.

**Architecture:** New subsystem under `cli/lucli/services/deploy/` in the Wheels module, layered as (top → bottom) CLI verbs → commands-as-strings classes → typed config tree → generic primitives (SSH, Mustache, YAML). Three bundled JARs (sshj, jmustache, snakeyaml) loaded via URLClassLoader isolation. On-server state byte-compatible with Ruby Kamal so users can alternate between the two tools during evaluation.

**Tech Stack:** CFML (Lucee 6/7 + Adobe CF 2023/2025), Java 21, sshj (SSH client), jmustache (templates), snakeyaml (YAML parser), Docker, kamal-proxy (unchanged Go binary invoked remotely), WheelsTest BDD, TestBox assertions, docker-compose test fixtures.

**Spec:** `docs/superpowers/specs/2026-04-20-wheels-deploy-kamal-port-design.md`

---

## File Map

### Phase 0 — Foundations

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `cli/lucli/lib/deploy/README.md` | Documents bundled JAR provenance |
| Create | `cli/lucli/lib/deploy/jmustache-1.16.jar` | Mustache template engine |
| Create | `cli/lucli/lib/deploy/snakeyaml-2.3.jar` | YAML parser |
| Create | `cli/lucli/lib/deploy/sshj-0.39.0.jar` + 8 transitives | SSH client + crypto |
| Create | `cli/lucli/lib/deploy/manifest.json` | JAR hash manifest |
| Create | `cli/lucli/services/deploy/lib/JarLoader.cfc` | URLClassLoader isolation |
| Create | `cli/lucli/services/deploy/lib/Mustache.cfc` | jmustache facade |
| Create | `cli/lucli/services/deploy/lib/Yaml.cfc` | snakeyaml facade |
| Create | `cli/lucli/services/deploy/lib/SshClient.cfc` | Single-host sshj facade |
| Create | `cli/lucli/services/deploy/lib/SshPool.cfc` | Parallel multi-host fan-out |
| Create | `cli/lucli/services/deploy/lib/FakeSshPool.cfc` | Recording test double |
| Create | `cli/lucli/services/deploy/lib/Output.cfc` | Host-prefixed streaming logs |
| Create | `tools/deploy-sshd-up.sh` | Lifecycle helper: start sshd fixture |
| Create | `tools/deploy-sshd-down.sh` | Lifecycle helper: stop sshd fixture |
| Create | `tests/specs/deploy/lib/MustacheSpec.cfc` | Template rendering tests |
| Create | `tests/specs/deploy/lib/YamlSpec.cfc` | Parser tests |
| Create | `tests/specs/deploy/lib/SshClientSpec.cfc` | SSH integration tests |
| Create | `tests/specs/deploy/lib/SshPoolSpec.cfc` | Parallel fan-out tests |
| Create | `tests/specs/deploy/lib/FakeSshPoolSpec.cfc` | Test double sanity tests |
| Create | `tests/specs/deploy/lib/OutputSpec.cfc` | Host-prefix sink tests |
| Create | `tests/_fixtures/deploy/sshd/docker-compose.yml` | 2× openssh-server containers |
| Create | `tests/_fixtures/deploy/sshd/authorized_keys` | Deterministic test key |

### Phase 1 — Config + dry-run deploy

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `cli/lucli/services/deploy/config/Config.cfc` | Root config tree |
| Create | `cli/lucli/services/deploy/config/Role.cfc` | Named server group |
| Create | `cli/lucli/services/deploy/config/Env.cfc` | clear/secret/tags merge |
| Create | `cli/lucli/services/deploy/config/Builder.cfc` | Image build config |
| Create | `cli/lucli/services/deploy/config/Proxy.cfc` | kamal-proxy config |
| Create | `cli/lucli/services/deploy/config/Registry.cfc` | Image registry + creds |
| Create | `cli/lucli/services/deploy/config/Ssh.cfc` | SSH defaults |
| Create | `cli/lucli/services/deploy/config/Validator.cfc` | Schema violations |
| Create | `cli/lucli/services/deploy/config/ConfigLoader.cfc` | Load pipeline |
| Create | `cli/lucli/services/deploy/commands/Base.cfc` | docker/chain/pipe helpers |
| Create | `cli/lucli/services/deploy/commands/DockerCommands.cfc` | Low-level docker |
| Create | `cli/lucli/services/deploy/commands/AppCommands.cfc` | App lifecycle strings |
| Create | `cli/lucli/services/deploy/commands/ProxyCommands.cfc` | kamal-proxy invocations |
| Create | `cli/lucli/services/deploy/commands/RegistryCommands.cfc` | login/logout strings |
| Create | `cli/lucli/services/deploy/commands/BuilderCommands.cfc` | build/push/pull strings |
| Create | `cli/lucli/services/deploy/commands/AuditorCommands.cfc` | Audit log strings |
| Create | `cli/lucli/services/deploy/cli/DeployMainCli.cfc` | Top-level verb dispatch |
| Modify | `cli/lucli/Module.cfc` | Add `public string function deploy()` |
| Create | `tests/specs/deploy/config/ConfigLoaderSpec.cfc` | Loader tests |
| Create | `tests/specs/deploy/commands/*Spec.cfc` | String-assertion tests |
| Create | `tests/specs/deploy/cli/DeployMainCliSpec.cfc` | Dry-run flow tests |
| Create | `tests/_fixtures/deploy/configs/*.yml` | Fixture configs |
| Create | `tools/deploy-dry-run-diff.sh` | Comparison harness vs Ruby Kamal |
| Create | `tools/deploy-dry-run-normalize.py` | Semantic-diff normalizer |

### Phase 2 — End-to-end deploy

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `cli/lucli/services/deploy/commands/LockCommands.cfc` | Lock acquire/release |
| Create | `cli/lucli/services/deploy/commands/HookCommands.cfc` | Local hook dispatch |
| Create | `cli/lucli/services/deploy/lib/SecretResolver.cfc` | `.kamal/secrets` expansion |
| Create | `cli/lucli/services/deploy/cli/DeployAppCli.cfc` | `app` subcommand |
| Create | `cli/lucli/services/deploy/cli/DeployProxyCli.cfc` | `proxy` subcommand |
| Create | `cli/lucli/services/deploy/cli/DeployRegistryCli.cfc` | `registry` subcommand |
| Create | `cli/lucli/templates/deploy/init/deploy.yml.mustache` | `init` output |
| Create | `cli/lucli/templates/deploy/init/secrets.mustache` | `.kamal/secrets` stub |
| Create | `tests/specs/deploy/integration/E2EDeploySpec.cfc` | Real v1→v2→rollback |
| Create | `tests/_fixtures/deploy/e2e/docker-compose.yml` | sshd + dind setup |
| Create | `tools/deploy-e2e-up.sh` | Lifecycle helper: e2e fixture |
| Create | `tools/deploy-e2e-down.sh` | Lifecycle helper: e2e fixture |

### Phase 3 — Parity fillout

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `cli/lucli/services/deploy/config/Accessory.cfc` | Sidecar config |
| Create | `cli/lucli/services/deploy/config/Boot.cfc` | Boot strategy |
| Create | `cli/lucli/services/deploy/config/Healthcheck.cfc` | Health probe config |
| Create | `cli/lucli/services/deploy/commands/AccessoryCommands.cfc` | Sidecar lifecycle |
| Create | `cli/lucli/services/deploy/cli/DeployAccessoryCli.cfc` | `accessory` subcommand |
| Create | `cli/lucli/services/deploy/cli/DeployBuildCli.cfc` | `build` subcommand |
| Create | `cli/lucli/services/deploy/cli/DeploySecretsCli.cfc` | `secrets` subcommand |
| Create | `cli/lucli/services/deploy/secrets/OnePasswordAdapter.cfc` | op CLI wrapper |
| Create | `cli/lucli/services/deploy/secrets/BitwardenAdapter.cfc` | bw CLI wrapper |
| Create | `cli/lucli/services/deploy/secrets/AwsSecretsAdapter.cfc` | aws CLI wrapper |
| Create | `cli/lucli/services/deploy/cli/DeployServerCli.cfc` | `server` subcommand |
| Create | `cli/lucli/services/deploy/cli/DeployPruneCli.cfc` | `prune` subcommand |
| Create | `cli/lucli/services/deploy/cli/DeployLockCli.cfc` | `lock` subcommand |
| Create | `docs/src/working-with-wheels/deployment/**` | User docs |
| Modify | `CLAUDE.md` | Deploy quick reference |
| Modify | `.github/workflows/tests.yml` | Add parity gate job |

### Phase 4 — Forward-looking (not in this plan)

LuCLI core promotion, Windows polish, telemetry, TUI. Tracked separately after Phase 3.

---

## Important Background

**Commands-are-strings invariant.** Every method on a `*Commands.cfc` returns either a string or a struct shaped `{cmd, env, raiseOnNonzero}`. Methods never open a connection. The `*Cli.cfc` layer and the orchestrator are the only places SSH actually happens. This is what makes `--dry-run` trivial and unit tests fast.

**On-server parity contract** (pinned, non-negotiable):
- Container names: `<service>-<role>-<version>`
- Labels: `service=`, `role=`, `destination=`, `version=`
- Docker network: `kamal`
- Proxy config dir: `/home/<user>/.config/kamal-proxy/`
- Lock path: `/tmp/kamal_deploy_lock_<service>`
- Hook env prefix: `KAMAL_*` (NOT `WHEELS_*`)

**Kamal source pinning.** Each `*Commands.cfc` carries a header comment pinning the Kamal release and source path. Current target: Kamal `v2.4.0`, kamal-proxy `v0.8.6`. When Kamal changes, that comment is the diff target.

**Classloader pattern.** We reuse the two-parent URLClassLoader pattern already proven for Playwright (PlatformClassLoader as parent, TCCL swap during native calls). See `reference_playwright_java_two_jar.md` in memory for the proven approach.

**CFML `##` gotcha.** Do NOT write Mustache templates as CFML `.cfm` files — Docker compose fragments and systemd units are full of `#` characters that would crash CFML parsers. All rendered artifacts use `.mustache` files loaded as raw strings.

**Test shell helpers pattern.** Integration tests that need docker containers use `tools/deploy-*-up.sh` / `deploy-*-down.sh` shell scripts called from WheelsTest `beforeAll` / `afterAll` via a single helper CFC (`tests/_helpers/DeployShellHelper.cfc`) rather than inline process spawns. This keeps test CFCs readable and the lifecycle logic in one place.

**Test suite gate.** Every task that modifies CFML MUST end with `bash tools/test-local.sh` and verify no regressions beyond the tests added in that task.

---

## Phase 0 — Foundations

### Task 1: Create `cli/lucli/lib/deploy/` directory and manifest

**Files:**
- Create: `cli/lucli/lib/deploy/README.md`
- Create: `cli/lucli/lib/deploy/manifest.json`

- [ ] **Step 1: Create directory**

```bash
mkdir -p cli/lucli/lib/deploy
```

- [ ] **Step 2: Write README**

Write `cli/lucli/lib/deploy/README.md`:

```markdown
# Deploy JARs

Bundled third-party JARs used by `wheels deploy`. Loaded via URLClassLoader
isolation (`cli/lucli/services/deploy/lib/JarLoader.cfc`) to avoid version
collisions with Lucee's bundled crypto and YAML parsers.

| JAR | Version | License | Purpose |
|-----|---------|---------|---------|
| jmustache | 1.16 | BSD-2 | Logic-free template rendering for deploy artifacts |
| snakeyaml | 2.3 | Apache-2.0 | YAML parsing of `deploy.yml` |
| sshj | 0.39.0 | Apache-2.0 | SSH client + SFTP |
| bcprov-jdk18on | 1.78 | MIT | Crypto transitive of sshj |
| bcpkix-jdk18on | 1.78 | MIT | PKI transitive of sshj |
| bcutil-jdk18on | 1.78 | MIT | Utility transitive of sshj |
| eddsa | 0.3.0 | CC0 | Ed25519 keys |
| jzlib | 1.1.3 | BSD-3 | Compression |
| slf4j-api | 2.0.13 | MIT | Logging facade |
| slf4j-nop | 2.0.13 | MIT | Logging no-op binding |

Regenerate `manifest.json` after any JAR change.
```

- [ ] **Step 3: Create empty manifest placeholder**

Write `cli/lucli/lib/deploy/manifest.json`:

```json
{
  "version": 1,
  "generated": "",
  "jars": []
}
```

- [ ] **Step 4: Commit**

```bash
git add cli/lucli/lib/deploy/README.md cli/lucli/lib/deploy/manifest.json
git commit -m "docs(config): scaffold deploy lib directory with JAR manifest"
```

---

### Task 2: Vendor jmustache JAR and create Mustache facade

**Files:**
- Create: `cli/lucli/lib/deploy/jmustache-1.16.jar`
- Create: `cli/lucli/services/deploy/lib/JarLoader.cfc`
- Create: `cli/lucli/services/deploy/lib/Mustache.cfc`
- Create: `tests/specs/deploy/lib/MustacheSpec.cfc`

- [ ] **Step 1: Download jmustache**

```bash
mkdir -p cli/lucli/lib/deploy
curl -fL -o cli/lucli/lib/deploy/jmustache-1.16.jar \
  https://repo1.maven.org/maven2/com/samskivert/jmustache/1.16/jmustache-1.16.jar
sha256sum cli/lucli/lib/deploy/jmustache-1.16.jar
```

Record the hash for Step 7.

- [ ] **Step 2: Write failing Mustache tests**

Create `tests/specs/deploy/lib/MustacheSpec.cfc`:

```cfm
component extends="wheels.WheelsTest" {
    function run() {
        describe("Mustache", () => {

            it("renders a simple variable", () => {
                var m = new cli.lucli.services.deploy.lib.Mustache();
                expect(m.render("Hello {{name}}", {name: "World"}))
                    .toBe("Hello World");
            });

            it("renders a missing key as empty by default", () => {
                var m = new cli.lucli.services.deploy.lib.Mustache();
                expect(m.render("Hello {{missing}}", {}))
                    .toBe("Hello ");
            });

            it("renderStrict() throws on missing key", () => {
                var m = new cli.lucli.services.deploy.lib.Mustache();
                expect(() => m.renderStrict("{{missing}}", {}))
                    .toThrow();
            });

            it("renders a section loop", () => {
                var m = new cli.lucli.services.deploy.lib.Mustache();
                var ctx = {hosts: [{name: "a"}, {name: "b"}]};
                expect(m.render("{{##hosts}}[{{name}}]{{/hosts}}", ctx))
                    .toBe("[a][b]");
            });
        });
    }
}
```

- [ ] **Step 3: Run tests to confirm fail**

```bash
bash tools/test-local.sh deploy
```

Expected: 4 failures — `Mustache.cfc not found`.

- [ ] **Step 4: Write JarLoader.cfc**

Create `cli/lucli/services/deploy/lib/JarLoader.cfc`. Pattern mirrors the Playwright classloader in `tests/_browser/`. Parent is `PlatformClassLoader` (NOT system CL) to isolate BouncyCastle transitives from Lucee's bundled crypto. One loader per JVM, cached keyed on manifest.json hash.

Key methods:
- `loadClass(fqcn)` → Java Class by FQCN from the deploy classpath.
- `newInstance(fqcn, args)` → creates an instance; swaps the thread context classloader for the duration to allow service-provider discovery.

Full implementation (~80 lines CFML) follows the Playwright `TwoJarClassLoader` in `tests/_browser/`. Copy that structure, swapping the JAR directory for `cli/lucli/lib/deploy/`.

- [ ] **Step 5: Write Mustache.cfc facade**

Create `cli/lucli/services/deploy/lib/Mustache.cfc`:

```cfm
/**
 * Facade over jmustache (com.samskivert.mustache.Mustache).
 *
 * Default render() follows Mustache spec: missing keys render empty.
 * renderStrict() throws on missing keys — use for config-critical templates.
 */
component {

    variables.loader = new JarLoader();

    public any function init() {
        variables.mustacheClass = variables.loader.loadClass("com.samskivert.mustache.Mustache");
        variables.compiler = variables.mustacheClass.compiler();
        return this;
    }

    public string function render(required string source, required struct ctx) {
        var tmpl = variables.compiler.compile(arguments.source);
        return tmpl.execute(arguments.ctx);
    }

    public string function renderStrict(required string source, required struct ctx) {
        var strictCompiler = variables.compiler.strictSections(true);
        var tmpl = strictCompiler.compile(arguments.source);
        try {
            return tmpl.execute(arguments.ctx);
        } catch (any e) {
            throw(type="Mustache.MissingKey", message=e.message);
        }
    }
}
```

- [ ] **Step 6: Run tests to confirm pass**

```bash
bash tools/test-local.sh deploy
```

Expected: 4 pass, 0 fail.

- [ ] **Step 7: Update manifest.json**

Fill in `cli/lucli/lib/deploy/manifest.json`:

```json
{
  "version": 1,
  "generated": "2026-04-20",
  "jars": [
    {"name": "jmustache-1.16.jar", "sha256": "<hash-from-step-1>"}
  ]
}
```

- [ ] **Step 8: Commit**

```bash
git add cli/lucli/lib/deploy/jmustache-1.16.jar \
        cli/lucli/lib/deploy/manifest.json \
        cli/lucli/services/deploy/lib/JarLoader.cfc \
        cli/lucli/services/deploy/lib/Mustache.cfc \
        tests/specs/deploy/lib/MustacheSpec.cfc
git commit -m "feat(cli): add Mustache template engine for deploy artifacts"
```

---

### Task 3: Vendor snakeyaml JAR and create Yaml facade

**Files:**
- Create: `cli/lucli/lib/deploy/snakeyaml-2.3.jar`
- Create: `cli/lucli/services/deploy/lib/Yaml.cfc`
- Create: `tests/specs/deploy/lib/YamlSpec.cfc`

- [ ] **Step 1: Download snakeyaml**

```bash
curl -fL -o cli/lucli/lib/deploy/snakeyaml-2.3.jar \
  https://repo1.maven.org/maven2/org/yaml/snakeyaml/2.3/snakeyaml-2.3.jar
sha256sum cli/lucli/lib/deploy/snakeyaml-2.3.jar
```

- [ ] **Step 2: Write failing Yaml tests**

Create `tests/specs/deploy/lib/YamlSpec.cfc`:

```cfm
component extends="wheels.WheelsTest" {
    function run() {
        describe("Yaml", () => {

            it("parses a flat map", () => {
                var y = new cli.lucli.services.deploy.lib.Yaml();
                var out = y.parse("service: myapp#chr(10)#image: acme/myapp");
                expect(out.service).toBe("myapp");
                expect(out.image).toBe("acme/myapp");
            });

            it("parses nested structure", () => {
                var y = new cli.lucli.services.deploy.lib.Yaml();
                var src = "servers:#chr(10)#  web:#chr(10)#    - 1.2.3.4#chr(10)#    - 1.2.3.5";
                var out = y.parse(src);
                expect(out.servers.web[1]).toBe("1.2.3.4");
                expect(out.servers.web[2]).toBe("1.2.3.5");
            });

            it("rejects Java class tags for security", () => {
                var y = new cli.lucli.services.deploy.lib.Yaml();
                expect(() => y.parse("!!javax.script.ScriptEngineManager [null]"))
                    .toThrow();
            });

            it("deepMerge overlays right onto left", () => {
                var y = new cli.lucli.services.deploy.lib.Yaml();
                var base = {env: {clear: {PORT: "3000"}, secret: ["DB"]}};
                var overlay = {env: {clear: {PORT: "4000", HOST: "x"}}};
                var merged = y.deepMerge(base, overlay);
                expect(merged.env.clear.PORT).toBe("4000");
                expect(merged.env.clear.HOST).toBe("x");
                expect(merged.env.secret[1]).toBe("DB");
            });
        });
    }
}
```

- [ ] **Step 3: Confirm fail**

```bash
bash tools/test-local.sh deploy
```

- [ ] **Step 4: Write Yaml.cfc**

Create `cli/lucli/services/deploy/lib/Yaml.cfc`:

```cfm
/**
 * Facade over SnakeYAML with SafeConstructor.
 *
 * SafeConstructor rejects `!!java.*` and `!!javax.*` class tags —
 * this is the security baseline. Do NOT swap in Constructor or a
 * custom Representer without explicit review.
 *
 * dump() uses block style with 2-space indent and preserves
 * insertion order for diff-friendly config writes.
 */
component {

    variables.loader = new JarLoader();

    public any function init() {
        variables.yamlClass = variables.loader.loadClass("org.yaml.snakeyaml.Yaml");
        variables.safeCtorClass = variables.loader.loadClass("org.yaml.snakeyaml.constructor.SafeConstructor");
        variables.loaderOptsClass = variables.loader.loadClass("org.yaml.snakeyaml.LoaderOptions");
        return this;
    }

    public any function parse(required string src) {
        var loaderOpts = variables.loaderOptsClass.getDeclaredConstructor([]).newInstance([]);
        var ctor = variables.safeCtorClass.getDeclaredConstructor([variables.loaderOptsClass])
            .newInstance([loaderOpts]);
        var yaml = variables.yamlClass.getDeclaredConstructor([variables.safeCtorClass])
            .newInstance([ctor]);
        try {
            return javaToCfml(yaml.load(javaCast("string", arguments.src)));
        } catch (any e) {
            throw(type="Yaml.ParseError", message=e.message);
        }
    }

    public string function dump(required any data) {
        var yaml = variables.yamlClass.getDeclaredConstructor([]).newInstance([]);
        return yaml.dump(cfmlToJava(arguments.data));
    }

    public struct function deepMerge(required struct base, required struct overlay) {
        var result = duplicate(arguments.base);
        for (var key in arguments.overlay) {
            if (structKeyExists(result, key)
                && isStruct(result[key])
                && isStruct(arguments.overlay[key])) {
                result[key] = deepMerge(result[key], arguments.overlay[key]);
            } else {
                result[key] = arguments.overlay[key];
            }
        }
        return result;
    }

    private any function javaToCfml(required any node) {
        if (isNull(arguments.node)) return "";
        if (isInstanceOf(arguments.node, "java.util.Map")) {
            var out = structNew("ordered");
            var it = arguments.node.entrySet().iterator();
            while (it.hasNext()) {
                var entry = it.next();
                out[entry.getKey()] = javaToCfml(entry.getValue());
            }
            return out;
        }
        if (isInstanceOf(arguments.node, "java.util.List")) {
            var arr = [];
            for (var i = 0; i < arguments.node.size(); i++) {
                arrayAppend(arr, javaToCfml(arguments.node.get(i)));
            }
            return arr;
        }
        return arguments.node;
    }

    private any function cfmlToJava(required any node) {
        if (isStruct(arguments.node)) {
            var map = createObject("java", "java.util.LinkedHashMap").init();
            for (var k in arguments.node) map.put(k, cfmlToJava(arguments.node[k]));
            return map;
        }
        if (isArray(arguments.node)) {
            var list = createObject("java", "java.util.ArrayList").init();
            for (var item in arguments.node) list.add(cfmlToJava(item));
            return list;
        }
        return arguments.node;
    }
}
```

- [ ] **Step 5: Run**

```bash
bash tools/test-local.sh deploy
```

Expected: 8 pass total (4 Mustache + 4 Yaml).

- [ ] **Step 6: Update manifest and commit**

```bash
git add cli/lucli/lib/deploy/snakeyaml-2.3.jar \
        cli/lucli/lib/deploy/manifest.json \
        cli/lucli/services/deploy/lib/Yaml.cfc \
        tests/specs/deploy/lib/YamlSpec.cfc
git commit -m "feat(cli): add SafeConstructor YAML parser for deploy configs"
```

---

### Task 4: Vendor sshj + transitives

**Files:**
- Create: 9 JARs in `cli/lucli/lib/deploy/`
- Modify: `cli/lucli/lib/deploy/manifest.json`

- [ ] **Step 1: Download all sshj JARs**

```bash
BASE=https://repo1.maven.org/maven2
D=cli/lucli/lib/deploy

curl -fL -o $D/sshj-0.39.0.jar          $BASE/com/hierynomus/sshj/0.39.0/sshj-0.39.0.jar
curl -fL -o $D/bcprov-jdk18on-1.78.jar  $BASE/org/bouncycastle/bcprov-jdk18on/1.78/bcprov-jdk18on-1.78.jar
curl -fL -o $D/bcpkix-jdk18on-1.78.jar  $BASE/org/bouncycastle/bcpkix-jdk18on/1.78/bcpkix-jdk18on-1.78.jar
curl -fL -o $D/bcutil-jdk18on-1.78.jar  $BASE/org/bouncycastle/bcutil-jdk18on/1.78/bcutil-jdk18on-1.78.jar
curl -fL -o $D/eddsa-0.3.0.jar          $BASE/net/i2p/crypto/eddsa/0.3.0/eddsa-0.3.0.jar
curl -fL -o $D/jzlib-1.1.3.jar          $BASE/com/jcraft/jzlib/1.1.3/jzlib-1.1.3.jar
curl -fL -o $D/slf4j-api-2.0.13.jar     $BASE/org/slf4j/slf4j-api/2.0.13/slf4j-api-2.0.13.jar
curl -fL -o $D/slf4j-nop-2.0.13.jar     $BASE/org/slf4j/slf4j-nop/2.0.13/slf4j-nop-2.0.13.jar

for f in $D/*.jar; do sha256sum "$f"; done
```

- [ ] **Step 2: Update manifest.json**

Add every new JAR with its sha256.

- [ ] **Step 3: Verify classpath loads**

```bash
wheels console
```

```cfm
var l = new cli.lucli.services.deploy.lib.JarLoader();
writeOutput(l.loadClass("net.schmizz.sshj.SSHClient").getName());
```

Expected: `net.schmizz.sshj.SSHClient`.

- [ ] **Step 4: Commit**

```bash
git add cli/lucli/lib/deploy/*.jar cli/lucli/lib/deploy/manifest.json
git commit -m "feat(cli): vendor sshj 0.39.0 + BouncyCastle transitives for deploy SSH"
```

---

### Task 5: Create dockerized sshd test fixture

**Files:**
- Create: `tests/_fixtures/deploy/sshd/docker-compose.yml`
- Create: `tests/_fixtures/deploy/sshd/test_key` (ed25519 private)
- Create: `tests/_fixtures/deploy/sshd/test_key.pub`
- Create: `tests/_fixtures/deploy/sshd/authorized_keys`
- Create: `tests/_fixtures/deploy/sshd/README.md`
- Create: `tools/deploy-sshd-up.sh`
- Create: `tools/deploy-sshd-down.sh`

- [ ] **Step 1: Generate a deterministic test keypair**

```bash
mkdir -p tests/_fixtures/deploy/sshd
ssh-keygen -t ed25519 -N "" -C "wheels-deploy-test" \
  -f tests/_fixtures/deploy/sshd/test_key
cp tests/_fixtures/deploy/sshd/test_key.pub \
   tests/_fixtures/deploy/sshd/authorized_keys
chmod 600 tests/_fixtures/deploy/sshd/test_key
```

- [ ] **Step 2: Write docker-compose.yml**

```yaml
services:
  sshd1:
    image: linuxserver/openssh-server:latest
    environment:
      PUBLIC_KEY_FILE: /keys/authorized_keys
      USER_NAME: deploy
      SUDO_ACCESS: "true"
      PASSWORD_ACCESS: "false"
    volumes:
      - ./authorized_keys:/keys/authorized_keys:ro
    ports:
      - "22022:2222"

  sshd2:
    image: linuxserver/openssh-server:latest
    environment:
      PUBLIC_KEY_FILE: /keys/authorized_keys
      USER_NAME: deploy
      SUDO_ACCESS: "true"
      PASSWORD_ACCESS: "false"
    volumes:
      - ./authorized_keys:/keys/authorized_keys:ro
    ports:
      - "22023:2222"
```

- [ ] **Step 3: Write lifecycle helpers**

Create `tools/deploy-sshd-up.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
FIX_DIR="$(dirname "$0")/../tests/_fixtures/deploy/sshd"
docker compose -f "$FIX_DIR/docker-compose.yml" up -d
sleep 5
```

Create `tools/deploy-sshd-down.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
FIX_DIR="$(dirname "$0")/../tests/_fixtures/deploy/sshd"
docker compose -f "$FIX_DIR/docker-compose.yml" down
```

```bash
chmod +x tools/deploy-sshd-up.sh tools/deploy-sshd-down.sh
```

- [ ] **Step 4: Write README**

Create `tests/_fixtures/deploy/sshd/README.md`:

```markdown
# SSH test fixture

Two openssh-server containers on ports 22022 and 22023.

## Start / Stop

    bash tools/deploy-sshd-up.sh
    bash tools/deploy-sshd-down.sh

`test_key` is a deterministic ed25519 keypair. NO production value; exists
only for test reproducibility.
```

- [ ] **Step 5: Verify manually**

```bash
bash tools/deploy-sshd-up.sh
ssh -i tests/_fixtures/deploy/sshd/test_key \
    -o StrictHostKeyChecking=no \
    -p 22022 deploy@localhost uname -a
bash tools/deploy-sshd-down.sh
```

Expected: `Linux ... x86_64 GNU/Linux` printed.

- [ ] **Step 6: Commit**

```bash
git add tests/_fixtures/deploy/sshd/ tools/deploy-sshd-up.sh tools/deploy-sshd-down.sh
git commit -m "test(cli): add dockerized sshd fixture for deploy tests"
```

---

### Task 6: Write SshClient with basic `run()`

**Files:**
- Create: `cli/lucli/services/deploy/lib/SshClient.cfc`
- Create: `tests/_helpers/DeployShellHelper.cfc`
- Create: `tests/specs/deploy/lib/SshClientSpec.cfc`

- [ ] **Step 1: Write DeployShellHelper.cfc**

Create `tests/_helpers/DeployShellHelper.cfc` — a shared helper for integration specs to invoke the shell lifecycle scripts without inline process spawns:

```cfm
component {
    public void function sshdUp() {
        runShell("bash tools/deploy-sshd-up.sh");
    }
    public void function sshdDown() {
        runShell("bash tools/deploy-sshd-down.sh");
    }
    public void function e2eUp() {
        runShell("bash tools/deploy-e2e-up.sh");
    }
    public void function e2eDown() {
        runShell("bash tools/deploy-e2e-down.sh");
    }
    private void function runShell(required string cmd) {
        var pb = createObject("java", "java.lang.ProcessBuilder").init(["sh", "-c", arguments.cmd]);
        pb.redirectErrorStream(true);
        var proc = pb.start();
        proc.waitFor();
    }
}
```

- [ ] **Step 2: Write failing SshClient tests**

Create `tests/specs/deploy/lib/SshClientSpec.cfc`:

```cfm
component extends="wheels.WheelsTest" {

    function beforeAll() {
        variables.helper = new tests._helpers.DeployShellHelper();
        variables.helper.sshdUp();
        variables.fixtureDir = expandPath("/tests/_fixtures/deploy/sshd");
    }

    function afterAll() {
        variables.helper.sshdDown();
    }

    function run() {
        describe("SshClient", () => {

            it("runs a command and returns exit 0 + stdout", () => {
                var ssh = makeClient(22022);
                var r = ssh.run("echo hello");
                expect(r.exitCode).toBe(0);
                expect(trim(r.stdout)).toBe("hello");
                ssh.close();
            });

            it("returns non-zero exit code for failing command", () => {
                var ssh = makeClient(22022);
                var r = ssh.run("false");
                expect(r.exitCode).toBe(1);
                ssh.close();
            });

            it("captures stderr separately from stdout", () => {
                var ssh = makeClient(22022);
                var r = ssh.run("echo out; echo err 1>&2");
                expect(trim(r.stdout)).toBe("out");
                expect(trim(r.stderr)).toBe("err");
                ssh.close();
            });
        });
    }

    private any function makeClient(required numeric port) {
        return new cli.lucli.services.deploy.lib.SshClient().init(
            "localhost",
            {user: "deploy", port: arguments.port,
             privateKey: variables.fixtureDir & "/test_key",
             strictHostKeyChecking: false}
        );
    }
}
```

- [ ] **Step 3: Confirm fail**

```bash
bash tools/test-local.sh deploy
```

- [ ] **Step 4: Write SshClient.cfc**

Create `cli/lucli/services/deploy/lib/SshClient.cfc`:

```cfm
/**
 * Single-host SSH client facade over sshj.
 *
 * One instance per remote host. Opens the connection on init;
 * call .close() when done. For parallel fan-out, use SshPool.
 */
component {

    variables.loader = new JarLoader();

    public any function init(required string host, struct opts = {}) {
        variables.host = arguments.host;
        variables.opts = {
            user: arguments.opts.user ?: "root",
            port: arguments.opts.port ?: 22,
            privateKey: arguments.opts.privateKey ?: "",
            strictHostKeyChecking: arguments.opts.strictHostKeyChecking ?: true,
            timeoutMs: arguments.opts.timeoutMs ?: 30000
        };
        variables.sshj = variables.loader.newInstance("net.schmizz.sshj.SSHClient");
        if (!variables.opts.strictHostKeyChecking) {
            var promiscuous = variables.loader
                .loadClass("net.schmizz.sshj.transport.verification.PromiscuousVerifier")
                .getDeclaredConstructor([]).newInstance([]);
            variables.sshj.addHostKeyVerifier(promiscuous);
        } else {
            variables.sshj.loadKnownHosts();
        }
        variables.sshj.setTimeout(variables.opts.timeoutMs);
        variables.sshj.connect(variables.host, variables.opts.port);
        if (len(variables.opts.privateKey)) {
            var keyProvider = variables.sshj.loadKeys(variables.opts.privateKey);
            variables.sshj.authPublickey(variables.opts.user, [keyProvider]);
        } else {
            variables.sshj.authPublickey(variables.opts.user);
        }
        return this;
    }

    public struct function run(required string cmd, struct opts = {}) {
        var useSudo = (arguments.opts.sudo ?: false) && variables.opts.user != "root";
        var effectiveCmd = useSudo ? "sudo -n " & arguments.cmd : arguments.cmd;
        var start = getTickCount();
        var session = variables.sshj.startSession();
        try {
            var command = session.exec(effectiveCmd);
            var stdoutStream = createObject("java", "org.apache.commons.io.IOUtils")
                .toString(command.getInputStream(), "UTF-8");
            var stderrStream = createObject("java", "org.apache.commons.io.IOUtils")
                .toString(command.getErrorStream(), "UTF-8");
            command.join();
            var exitCode = command.getExitStatus();
            if (isNull(exitCode)) exitCode = -1;
            var result = {
                exitCode: exitCode,
                stdout: stdoutStream,
                stderr: stderrStream,
                durationMs: getTickCount() - start
            };
            if (useSudo && exitCode != 0 && findNoCase("a password is required", stderrStream)) {
                throw(type="SshClient.SudoNoPassword",
                      message="Passwordless sudo not configured on #variables.host#");
            }
            return result;
        } finally {
            session.close();
        }
    }

    public void function upload(required string localPath, required string remotePath, struct opts = {}) {
        var sftp = variables.sshj.newSFTPClient();
        try {
            sftp.put(arguments.localPath, arguments.remotePath);
        } finally {
            sftp.close();
        }
    }

    public void function uploadString(required string content, required string remotePath, struct opts = {}) {
        var tmp = getTempFile(getTempDirectory(), "sshjs");
        fileWrite(tmp, arguments.content);
        try {
            upload(tmp, arguments.remotePath, arguments.opts);
        } finally {
            fileDelete(tmp);
        }
    }

    public void function download(required string remotePath, required string localPath) {
        var sftp = variables.sshj.newSFTPClient();
        try {
            sftp.get(arguments.remotePath, arguments.localPath);
        } finally {
            sftp.close();
        }
    }

    public void function close() {
        if (variables.sshj.isConnected()) {
            variables.sshj.disconnect();
        }
    }
}
```

- [ ] **Step 5: Run**

```bash
bash tools/test-local.sh deploy
```

Expected: 3 SshClient tests pass.

- [ ] **Step 6: Commit**

```bash
git add cli/lucli/services/deploy/lib/SshClient.cfc \
        tests/_helpers/DeployShellHelper.cfc \
        tests/specs/deploy/lib/SshClientSpec.cfc
git commit -m "feat(cli): add SshClient facade with run/upload/download"
```

---

### Task 7: Add SFTP + streaming tests

**Files:**
- Modify: `tests/specs/deploy/lib/SshClientSpec.cfc`

- [ ] **Step 1: Append SFTP tests**

Append to the `describe()`:

```cfm
it("uploads a string directly", () => {
    var ssh = makeClient(22022);
    ssh.uploadString("hello direct", "/tmp/direct.txt");
    var r = ssh.run("cat /tmp/direct.txt");
    expect(trim(r.stdout)).toBe("hello direct");
    ssh.close();
});

it("downloads a remote file", () => {
    var ssh = makeClient(22022);
    ssh.uploadString("roundtrip", "/tmp/round.txt");
    var local = getTempFile(getTempDirectory(), "down");
    ssh.download("/tmp/round.txt", local);
    expect(fileRead(local)).toBe("roundtrip");
    ssh.close();
});
```

- [ ] **Step 2: Run + commit**

```bash
bash tools/test-local.sh deploy
git add tests/specs/deploy/lib/SshClientSpec.cfc
git commit -m "test(cli): add SFTP upload/download coverage for SshClient"
```

---

### Task 8: FakeSshPool test double

**Files:**
- Create: `cli/lucli/services/deploy/lib/FakeSshPool.cfc`
- Create: `tests/specs/deploy/lib/FakeSshPoolSpec.cfc`

- [ ] **Step 1: Write failing tests**

Create `tests/specs/deploy/lib/FakeSshPoolSpec.cfc`:

```cfm
component extends="wheels.WheelsTest" {
    function run() {
        describe("FakeSshPool", () => {

            it("records onEach invocations", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                p.onEach(["h1", "h2"], function(ssh, host) { ssh.run("uname -a"); });
                var calls = p.calls();
                expect(arrayLen(calls)).toBe(2);
                expect(calls[1].host).toBe("h1");
                expect(calls[1].cmd).toBe("uname -a");
            });

            it("returns scripted results per host", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                p.expect("h1", "uname -a", {exitCode: 0, stdout: "Linux", stderr: ""});
                p.onEach(["h1"], function(ssh, host) {
                    var r = ssh.run("uname -a");
                    expect(r.stdout).toBe("Linux");
                });
            });

            it("throws on unexpected command in strict mode", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool({strict: true});
                expect(() => p.onEach(["h1"], function(ssh, host) { ssh.run("rogue"); }))
                    .toThrow();
            });

            it("clears recorded calls via reset()", () => {
                var p = new cli.lucli.services.deploy.lib.FakeSshPool();
                p.onEach(["h1"], function(ssh, host) { ssh.run("x"); });
                p.reset();
                expect(arrayLen(p.calls())).toBe(0);
            });
        });
    }
}
```

- [ ] **Step 2: Write FakeSshPool.cfc**

Create `cli/lucli/services/deploy/lib/FakeSshPool.cfc`:

```cfm
/**
 * In-memory test double for SshPool.
 *
 * Records every .run() / .upload() / etc. call for later inspection.
 * Returns scripted results when configured via .expect(); otherwise
 * returns exitCode 0 with empty stdout/stderr.
 *
 * Strict mode throws on any command that wasn't explicitly expected —
 * useful for locking down the exact command sequence a Cli verb emits.
 */
component {

    public any function init(struct opts = {}) {
        variables.strict = arguments.opts.strict ?: false;
        variables.calls = [];
        variables.expectations = {};
        return this;
    }

    public void function expect(required string host, required string cmd, required struct result) {
        variables.expectations["#arguments.host#|#arguments.cmd#"] = arguments.result;
    }

    public array function calls() {
        return variables.calls;
    }

    public void function reset() {
        arrayClear(variables.calls);
    }

    public void function onEach(required array hosts, required any callback) {
        for (var host in arguments.hosts) {
            var ssh = makeFakeSsh(host);
            arguments.callback(ssh, host);
        }
    }

    public void function onAny(required array hosts, required any callback) {
        if (arrayLen(arguments.hosts) == 0) return;
        var ssh = makeFakeSsh(arguments.hosts[1]);
        arguments.callback(ssh, arguments.hosts[1]);
    }

    public void function sequential(required array hosts, required any callback) {
        onEach(arguments.hosts, arguments.callback);
    }

    public array function accessCalls() { return variables.calls; }
    public struct function accessExpectations() { return variables.expectations; }
    public boolean function accessStrict() { return variables.strict; }

    private any function makeFakeSsh(required string host) {
        var pool = this;
        return {
            run: function(cmd, opts = {}) {
                var call = {host: host, cmd: cmd, opts: opts, kind: "run"};
                arrayAppend(pool.accessCalls(), call);
                var key = "#host#|#cmd#";
                if (structKeyExists(pool.accessExpectations(), key)) {
                    return pool.accessExpectations()[key];
                }
                if (pool.accessStrict()) {
                    throw(type="FakeSshPool.Unexpected",
                          message="Unexpected command on #host#: #cmd#");
                }
                return {exitCode: 0, stdout: "", stderr: "", durationMs: 0};
            },
            upload: function(local, remote, opts = {}) {
                arrayAppend(pool.accessCalls(), {host: host, kind: "upload",
                    local: local, remote: remote, opts: opts});
            },
            uploadString: function(content, remote, opts = {}) {
                arrayAppend(pool.accessCalls(), {host: host, kind: "uploadString",
                    content: content, remote: remote, opts: opts});
            },
            download: function(remote, local) {
                arrayAppend(pool.accessCalls(), {host: host, kind: "download",
                    remote: remote, local: local});
            },
            close: function() {}
        };
    }
}
```

- [ ] **Step 3: Run + commit**

```bash
bash tools/test-local.sh deploy
git add cli/lucli/services/deploy/lib/FakeSshPool.cfc \
        tests/specs/deploy/lib/FakeSshPoolSpec.cfc
git commit -m "test(cli): add FakeSshPool recording test double"
```

---

### Task 9: Real SshPool with parallel fan-out

**Files:**
- Create: `cli/lucli/services/deploy/lib/SshPool.cfc`
- Create: `tests/specs/deploy/lib/SshPoolSpec.cfc`

- [ ] **Step 1: Write failing tests**

Create `tests/specs/deploy/lib/SshPoolSpec.cfc`:

```cfm
component extends="wheels.WheelsTest" {

    function beforeAll() {
        variables.helper = new tests._helpers.DeployShellHelper();
        variables.helper.sshdUp();
        variables.fixtureDir = expandPath("/tests/_fixtures/deploy/sshd");
    }

    function afterAll() {
        variables.helper.sshdDown();
    }

    function run() {
        describe("SshPool", () => {

            it("runs a command on every host via onEach", () => {
                var pool = makePool();
                var results = {};
                pool.onEach(["localhost:22022", "localhost:22023"], function(ssh, host) {
                    results[host] = trim(ssh.run("hostname").stdout);
                });
                expect(structCount(results)).toBe(2);
                pool.close();
            });

            it("onEach runs hosts in parallel (faster than serial)", () => {
                var pool = makePool();
                var start = getTickCount();
                pool.onEach(["localhost:22022", "localhost:22023"], function(ssh, host) {
                    ssh.run("sleep 2");
                });
                var elapsed = getTickCount() - start;
                expect(elapsed).toBeLessThan(3500);
                pool.close();
            });

            it("sequential preserves ordering", () => {
                var pool = makePool();
                var order = [];
                pool.sequential(["localhost:22022", "localhost:22023"], function(ssh, host) {
                    arrayAppend(order, host);
                });
                expect(order[1]).toBe("localhost:22022");
                expect(order[2]).toBe("localhost:22023");
                pool.close();
            });
        });
    }

    private any function makePool() {
        return new cli.lucli.services.deploy.lib.SshPool({
            user: "deploy",
            privateKey: variables.fixtureDir & "/test_key",
            strictHostKeyChecking: false
        });
    }
}
```

- [ ] **Step 2: Write SshPool.cfc**

Create `cli/lucli/services/deploy/lib/SshPool.cfc`:

```cfm
/**
 * Parallel fan-out across multiple hosts.
 *
 * Connections are cached per "user@host:port" and reused across calls.
 * Parallelism capped at 10 by default (matches SSHKit default runner).
 */
component {

    public any function init(struct defaults = {}) {
        variables.defaults = {
            user: arguments.defaults.user ?: "root",
            port: arguments.defaults.port ?: 22,
            privateKey: arguments.defaults.privateKey ?: "",
            strictHostKeyChecking: arguments.defaults.strictHostKeyChecking ?: true,
            parallelism: arguments.defaults.parallelism ?: 10
        };
        variables.connections = {};
        variables.executor = createObject("java", "java.util.concurrent.Executors")
            .newFixedThreadPool(javaCast("int", variables.defaults.parallelism));
        return this;
    }

    public void function onEach(required array hosts, required any callback) {
        var futures = [];
        for (var host in arguments.hosts) {
            var h = host;
            var cb = arguments.callback;
            var fn = this;
            var task = createDynamicProxy(
                {call: function() {
                    var ssh = fn.getConnection(h);
                    cb(ssh, h);
                    return true;
                }},
                ["java.util.concurrent.Callable"]
            );
            arrayAppend(futures, variables.executor.submit(task));
        }
        for (var f in futures) f.get();
    }

    public void function onAny(required array hosts, required any callback) {
        if (arrayLen(arguments.hosts) == 0) return;
        for (var host in arguments.hosts) {
            try {
                var ssh = getConnection(host);
                arguments.callback(ssh, host);
                return;
            } catch (any e) {
                if (host == arguments.hosts[arrayLen(arguments.hosts)]) rethrow;
            }
        }
    }

    public void function sequential(required array hosts, required any callback) {
        for (var host in arguments.hosts) {
            var ssh = getConnection(host);
            arguments.callback(ssh, host);
        }
    }

    public any function getConnection(required string hostSpec) {
        var parsed = parseHost(arguments.hostSpec);
        var key = "#parsed.user#@#parsed.host#:#parsed.port#";
        if (!structKeyExists(variables.connections, key)) {
            variables.connections[key] = new SshClient().init(parsed.host, {
                user: parsed.user,
                port: parsed.port,
                privateKey: variables.defaults.privateKey,
                strictHostKeyChecking: variables.defaults.strictHostKeyChecking
            });
        }
        return variables.connections[key];
    }

    public void function close() {
        for (var key in variables.connections) variables.connections[key].close();
        structClear(variables.connections);
        variables.executor.shutdown();
    }

    private struct function parseHost(required string spec) {
        var s = arguments.spec;
        var user = variables.defaults.user;
        var port = variables.defaults.port;
        if (find("@", s)) { user = listFirst(s, "@"); s = listLast(s, "@"); }
        if (find(":", s)) { port = listLast(s, ":"); s = listFirst(s, ":"); }
        return {user: user, host: s, port: port};
    }
}
```

- [ ] **Step 3: Run + commit**

```bash
bash tools/test-local.sh deploy
git add cli/lucli/services/deploy/lib/SshPool.cfc \
        tests/specs/deploy/lib/SshPoolSpec.cfc
git commit -m "feat(cli): add SshPool with parallel onEach/onAny/sequential"
```

---

### Task 10: Output sink with host prefixing

**Files:**
- Create: `cli/lucli/services/deploy/lib/Output.cfc`
- Create: `tests/specs/deploy/lib/OutputSpec.cfc`

- [ ] **Step 1: Write failing tests**

Create `tests/specs/deploy/lib/OutputSpec.cfc`:

```cfm
component extends="wheels.WheelsTest" {
    function run() {
        describe("Output", () => {

            it("prefixes every line with [host]", () => {
                var buf = createObject("java", "java.io.ByteArrayOutputStream").init();
                var ps = createObject("java", "java.io.PrintStream").init(buf);
                var o = new cli.lucli.services.deploy.lib.Output(ps);
                o.write("host1", "hello#chr(10)#world#chr(10)#");
                var s = buf.toString();
                expect(find("[host1] hello", s)).toBeGT(0);
                expect(find("[host1] world", s)).toBeGT(0);
            });

            it("buffers partial lines until newline", () => {
                var buf = createObject("java", "java.io.ByteArrayOutputStream").init();
                var o = new cli.lucli.services.deploy.lib.Output(
                    createObject("java", "java.io.PrintStream").init(buf));
                o.write("h", "part1");
                expect(buf.size()).toBe(0);
                o.write("h", "-part2#chr(10)#");
                expect(find("[h] part1-part2", buf.toString())).toBeGT(0);
            });
        });
    }
}
```

- [ ] **Step 2: Write Output.cfc**

Create `cli/lucli/services/deploy/lib/Output.cfc`:

```cfm
/**
 * Host-prefixed line-buffered output sink. Matches SSHKit's default UX.
 */
component {

    public any function init(any sink = "") {
        variables.sink = isSimpleValue(arguments.sink) && arguments.sink == ""
            ? createObject("java", "java.lang.System").out
            : arguments.sink;
        variables.buffers = {};
        return this;
    }

    public void function write(required string host, required string chunk) {
        var buf = variables.buffers[arguments.host] ?: "";
        var combined = buf & arguments.chunk;
        var lines = listToArray(combined, chr(10), true);
        var endsWithNewline = right(combined, 1) == chr(10);
        for (var i = 1; i <= arrayLen(lines); i++) {
            var isLast = (i == arrayLen(lines));
            if (isLast && !endsWithNewline) {
                variables.buffers[arguments.host] = lines[i];
            } else {
                variables.sink.println("[#arguments.host#] #lines[i]#");
            }
        }
        if (endsWithNewline) variables.buffers[arguments.host] = "";
    }

    public void function flush(required string host) {
        var buf = variables.buffers[arguments.host] ?: "";
        if (len(buf)) {
            variables.sink.println("[#arguments.host#] #buf#");
            variables.buffers[arguments.host] = "";
        }
    }
}
```

- [ ] **Step 3: Run + commit**

```bash
bash tools/test-local.sh deploy
git add cli/lucli/services/deploy/lib/Output.cfc \
        tests/specs/deploy/lib/OutputSpec.cfc
git commit -m "feat(cli): add host-prefixed Output sink for deploy logging"
```

---

### Task 11: Phase 0 cross-engine smoke verification

**Files:** (no new CFML) — verify primitives on all four engines.

- [ ] **Step 1: Start sshd fixture + bring engines up**

```bash
bash tools/deploy-sshd-up.sh
cd rig
docker compose up -d lucee6 lucee7 adobe2023 adobe2025
sleep 60
```

- [ ] **Step 2: Run deploy specs across all 4 engines**

```bash
for pair in "lucee6:60006" "lucee7:60007" "adobe2023:62023" "adobe2025:62025"; do
  engine=${pair%:*}; port=${pair##*:}
  echo "=== $engine ==="
  curl -sf "http://localhost:$port/wheels/app/tests?format=json&directory=tests.specs.deploy" \
    | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['totalPass'],'pass',d['totalFail'],'fail',d['totalError'],'error')"
done
```

Expected: all 4 engines pass all deploy tests.

- [ ] **Step 3: Document in CHANGELOG**

Modify `CHANGELOG.md` under unreleased:

```markdown
### Added
- `wheels deploy` Phase 0 primitives: SSH client, Mustache templates,
  YAML parser. Cross-engine verified on Lucee 6/7 and Adobe CF 2023/2025.
  No user-visible surface yet; `wheels deploy` verb lands in Phase 1.
```

- [ ] **Step 4: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs(config): record Phase 0 cross-engine verification"
```

---

## Phase 1 — Config layer + dry-run `deploy`

Phase 1 delivers the config loader, the commands-as-strings layer for the happy path (app, proxy, registry, builder, docker, auditor, base), the `DeployMainCli` with `setup`/`deploy`/`redeploy`/`rollback`/`config`/`init`/`version`, and the `Module.deploy()` wiring. Only `--dry-run` is end-to-end. **Exit:** semantic-diff matches Ruby Kamal's dry-run output for the fixture corpus.

### Task 12: Config fixtures

**Files:**
- Create: `tests/_fixtures/deploy/configs/minimal.yml`
- Create: `tests/_fixtures/deploy/configs/full.yml`
- Create: `tests/_fixtures/deploy/configs/invalid/missing-service.yml`
- Create: `tests/_fixtures/deploy/configs/invalid/invalid-host.yml`
- Create: `tests/_fixtures/deploy/configs/invalid/unknown-key.yml`

- [ ] **Step 1: Write minimal.yml**

```yaml
service: demo
image: acme/demo
servers:
  - 1.2.3.4
registry:
  username: demo
  password:
    - REGISTRY_PASSWORD
```

- [ ] **Step 2: Pull full.yml from Kamal upstream**

```bash
gh api repos/basecamp/kamal/contents/test/fixtures/deploy_with_accessories.yml \
  --jq '.content' | base64 -d > tests/_fixtures/deploy/configs/full.yml
```

- [ ] **Step 3: Write invalid fixtures**

`invalid/missing-service.yml`:

```yaml
image: acme/demo
servers: [1.2.3.4]
```

`invalid/invalid-host.yml`:

```yaml
service: demo
image: acme/demo
servers:
  - "not:a:valid:host:at:all"
```

`invalid/unknown-key.yml`:

```yaml
service: demo
image: acme/demo
servers: [1.2.3.4]
bogus_field: true
```

- [ ] **Step 4: Commit**

```bash
git add tests/_fixtures/deploy/configs/
git commit -m "test(cli): add deploy.yml fixtures for loader tests"
```

---

### Task 13: ConfigLoader + Validator (happy path)

**Files:**
- Create: `cli/lucli/services/deploy/config/*.cfc` (8 CFCs — Config, Role, Env, Builder, Proxy, Registry, Ssh, Validator, ConfigLoader)
- Create: `tests/specs/deploy/config/ConfigLoaderSpec.cfc`

- [ ] **Step 1: Write ConfigLoaderSpec happy-path tests**

```cfm
component extends="wheels.WheelsTest" {
    function run() {
        describe("ConfigLoader", () => {

            it("loads minimal.yml", () => {
                var cfg = new cli.lucli.services.deploy.config.ConfigLoader()
                    .load(expandPath("/tests/_fixtures/deploy/configs/minimal.yml"));
                expect(cfg.service()).toBe("demo");
                expect(cfg.image()).toBe("acme/demo");
                expect(cfg.roles()[1].name()).toBe("web");
                expect(cfg.roles()[1].hosts()).toInclude("1.2.3.4");
            });

            it("resolves ${VAR} from ENV override", () => {
                var tmp = getTempFile(getTempDirectory(), "yml");
                fileWrite(tmp, "service: demo#chr(10)#image: acme/${TESTVAR}#chr(10)#servers: [1.2.3.4]#chr(10)#registry: {username: u, password: [X]}");
                var loader = new cli.lucli.services.deploy.config.ConfigLoader({envOverride: {TESTVAR: "custom"}});
                var cfg = loader.load(tmp);
                expect(cfg.image()).toBe("acme/custom");
            });

            it("merges destination overlay", () => {
                var base = getTempFile(getTempDirectory(), "yml");
                fileWrite(base, "service: demo#chr(10)#image: acme/demo#chr(10)#servers: [1.2.3.4]#chr(10)#env: {clear: {PORT: '3000'}}#chr(10)#registry: {username: u, password: [X]}");
                var overlay = left(base, len(base) - 4) & ".production.yml";
                fileWrite(overlay, "env:#chr(10)#  clear:#chr(10)#    PORT: '4000'");
                var cfg = new cli.lucli.services.deploy.config.ConfigLoader()
                    .load(base, {destination: "production"});
                expect(cfg.env().clear().PORT).toBe("4000");
            });
        });
    }
}
```

- [ ] **Step 2: Write Validator.cfc**

```cfm
component {

    variables.allowedKeys = [
        "service", "image", "servers", "registry", "builder", "env",
        "ssh", "proxy", "boot", "healthcheck", "hooks", "accessories",
        "volumes", "labels", "logging", "retain_containers",
        "minimum_version", "asset_path", "require_destination",
        "allow_empty_roles", "run_directory", "readiness_delay"
    ];

    public void function validate(required struct parsed, required string filePath) {
        requireKey(arguments.parsed, "service", arguments.filePath);
        requireKey(arguments.parsed, "image", arguments.filePath);
        requireKey(arguments.parsed, "servers", arguments.filePath);
        for (var k in arguments.parsed) {
            if (!arrayContainsNoCase(variables.allowedKeys, k)) {
                raise(arguments.filePath, "unknown top-level key: '#k#'");
            }
        }
        validateServers(arguments.parsed.servers, arguments.filePath);
    }

    private void function validateServers(required any servers, required string filePath) {
        if (isArray(arguments.servers)) {
            for (var host in arguments.servers) validateHost(host, arguments.filePath);
        } else if (isStruct(arguments.servers)) {
            for (var role in arguments.servers) {
                var hosts = arguments.servers[role];
                if (isArray(hosts)) {
                    for (var host in hosts) validateHost(host, arguments.filePath);
                } else if (isStruct(hosts) && structKeyExists(hosts, "hosts")) {
                    for (var host in hosts.hosts) validateHost(host, arguments.filePath);
                }
            }
        }
    }

    private void function validateHost(required string host, required string filePath) {
        if (arrayLen(listToArray(arguments.host, ":")) > 2
            && left(arguments.host, 1) != "[") {
            raise(arguments.filePath, "invalid host: '#arguments.host#'");
        }
    }

    private void function requireKey(required struct parsed, required string key, required string filePath) {
        if (!structKeyExists(arguments.parsed, arguments.key)) {
            raise(arguments.filePath, "missing required key: '#arguments.key#'");
        }
    }

    private void function raise(required string filePath, required string message) {
        throw(type="DeployConfigError",
              message="#arguments.filePath#: #arguments.message#");
    }
}
```

- [ ] **Step 3: Write Role, Env, Builder, Proxy, Registry, Ssh**

Each is a thin accessor CFC mirroring Kamal 2.4.0 `lib/kamal/configuration/<name>.rb`. Pattern (use for all six):

```cfm
component {
    public any function init(required struct raw) {
        variables.raw = arguments.raw;
        return this;
    }
    // Public accessors with sensible defaults, e.g.:
    public string function host() { return variables.raw.host ?: ""; }
}
```

Specific fields per CFC:
- `Role.cfc` — `name()`, `hosts()`, `env()` (Env instance), `cmd()`
- `Env.cfc` — `clear()` (struct), `secret()` (array), `tags()` (struct)
- `Builder.cfc` — `context()`, `dockerfile()`, `args()`, `arch()`, `remote()`
- `Proxy.cfc` — `host()`, `ssl()`, `appPort()`, `healthcheck()`
- `Registry.cfc` — `server()` (default "docker.io"), `username()`, `password()` (array)
- `Ssh.cfc` — `user()`, `port()`, `proxy()`, `keysOnly()`

- [ ] **Step 4: Write Config.cfc**

```cfm
component {

    public any function init(required struct raw, struct opts = {}) {
        variables.raw = arguments.raw;
        variables.destination = arguments.opts.destination ?: "";
        return this;
    }

    public string function service()     { return variables.raw.service; }
    public string function image()       { return variables.raw.image; }
    public string function destination() { return variables.destination; }
    public any function env()            { return new Env(variables.raw.env ?: {}); }
    public any function builder()        { return new Builder(variables.raw.builder ?: {}); }
    public any function registry()       { return new Registry(variables.raw.registry ?: {}); }
    public any function proxy()          { return new Proxy(variables.raw.proxy ?: {}); }
    public any function ssh()            { return new Ssh(variables.raw.ssh ?: {}); }

    public array function roles() {
        var servers = variables.raw.servers;
        if (isArray(servers)) return [new Role({name: "web", hosts: servers})];
        var out = [];
        for (var name in servers) {
            var entry = servers[name];
            if (isArray(entry)) {
                arrayAppend(out, new Role({name: name, hosts: entry}));
            } else {
                arrayAppend(out, new Role({name: name, hosts: entry.hosts ?: []}));
            }
        }
        return out;
    }

    public string function absoluteImage(required string version) {
        var reg = registry().server();
        var prefix = reg == "docker.io" ? "" : reg & "/";
        return prefix & image() & ":" & arguments.version;
    }
}
```

- [ ] **Step 5: Write ConfigLoader.cfc**

```cfm
component {

    public any function init(struct opts = {}) {
        variables.yaml = new cli.lucli.services.deploy.lib.Yaml();
        variables.validator = new Validator();
        variables.envOverride = arguments.opts.envOverride ?: {};
        return this;
    }

    public any function load(required string path, struct opts = {}) {
        var raw = variables.yaml.parse(fileRead(arguments.path));
        var dest = arguments.opts.destination ?: "";
        if (len(dest)) {
            var overlayPath = left(arguments.path, len(arguments.path) - 4) & "." & dest & ".yml";
            if (fileExists(overlayPath)) {
                var overlay = variables.yaml.parse(fileRead(overlayPath));
                raw = variables.yaml.deepMerge(raw, overlay);
            }
        }
        raw = interpolate(raw);
        variables.validator.validate(raw, arguments.path);
        return new Config(raw, {destination: dest});
    }

    private any function interpolate(required any node) {
        if (isSimpleValue(arguments.node)) {
            if (!find("${", arguments.node)) return arguments.node;
            var rendered = arguments.node;
            var re = "\$\{([A-Z_][A-Z0-9_]*)\}";
            var matches = reMatchNoCase(re, rendered);
            for (var m in matches) {
                var varName = reReplaceNoCase(m, re, "\1");
                rendered = replace(rendered, m, resolveVar(varName), "all");
            }
            return rendered;
        }
        if (isStruct(arguments.node)) {
            var out = {};
            for (var k in arguments.node) out[k] = interpolate(arguments.node[k]);
            return out;
        }
        if (isArray(arguments.node)) {
            var out = [];
            for (var item in arguments.node) arrayAppend(out, interpolate(item));
            return out;
        }
        return arguments.node;
    }

    private string function resolveVar(required string name) {
        if (structKeyExists(variables.envOverride, arguments.name)) {
            return variables.envOverride[arguments.name];
        }
        var sys = createObject("java", "java.lang.System");
        var fromEnv = sys.getenv(arguments.name);
        if (!isNull(fromEnv)) return fromEnv;
        return "";
    }
}
```

- [ ] **Step 6: Run**

```bash
bash tools/test-local.sh deploy
```

Expected: 3 ConfigLoader happy-path tests pass.

- [ ] **Step 7: Commit**

```bash
git add cli/lucli/services/deploy/config/ \
        tests/specs/deploy/config/ConfigLoaderSpec.cfc
git commit -m "feat(config): add ConfigLoader + Validator with destination overlay"
```

---

### Task 14: Validator error-path tests

**Files:**
- Modify: `tests/specs/deploy/config/ConfigLoaderSpec.cfc`

- [ ] **Step 1: Append error-path tests**

```cfm
it("rejects missing required 'service' key", () => {
    expect(() => new cli.lucli.services.deploy.config.ConfigLoader()
        .load(expandPath("/tests/_fixtures/deploy/configs/invalid/missing-service.yml")))
        .toThrow("DeployConfigError");
});

it("rejects invalid host", () => {
    expect(() => new cli.lucli.services.deploy.config.ConfigLoader()
        .load(expandPath("/tests/_fixtures/deploy/configs/invalid/invalid-host.yml")))
        .toThrow("DeployConfigError");
});

it("rejects unknown top-level key", () => {
    expect(() => new cli.lucli.services.deploy.config.ConfigLoader()
        .load(expandPath("/tests/_fixtures/deploy/configs/invalid/unknown-key.yml")))
        .toThrow("DeployConfigError");
});
```

- [ ] **Step 2: Run (should pass immediately — validator enforces)**

```bash
bash tools/test-local.sh deploy
```

- [ ] **Step 3: Commit**

```bash
git commit -m "test(config): add ConfigLoader error-path coverage"
```

---

### Task 15: Commands/Base.cfc + DockerCommands.cfc

**Files:**
- Create: `cli/lucli/services/deploy/commands/Base.cfc`
- Create: `cli/lucli/services/deploy/commands/DockerCommands.cfc`
- Create: `tests/specs/deploy/commands/BaseSpec.cfc`

- [ ] **Step 1: Write BaseSpec tests**

```cfm
component extends="wheels.WheelsTest" {
    function run() {
        describe("Commands.Base", () => {
            var base = new cli.lucli.services.deploy.commands.Base();

            it("docker() joins args with spaces", () => {
                expect(base.docker("run", "-d", "alpine"))
                    .toBe("docker run -d alpine");
            });

            it("chain() joins with &&", () => {
                expect(base.chain(["docker stop x", "docker rm x"]))
                    .toBe("docker stop x && docker rm x");
            });

            it("pipe() joins with |", () => {
                expect(base.pipe(["docker ps", "grep kamal"]))
                    .toBe("docker ps | grep kamal");
            });

            it("appendIf() gates inclusion", () => {
                expect(base.appendIf(true, ["--force"])).toBe("--force");
                expect(base.appendIf(false, ["--force"])).toBe("");
            });
        });
    }
}
```

- [ ] **Step 2: Write Base.cfc**

```cfm
/**
 * Shared string-building helpers. Source: Kamal 2.4.0 lib/kamal/commands/base.rb
 * All methods return strings. No I/O.
 */
component {
    public string function docker() {
        var parts = ["docker"];
        for (var i = 1; i <= arrayLen(arguments); i++) {
            var a = arguments[i];
            if (isArray(a)) {
                for (var item in a) if (len(item)) arrayAppend(parts, item);
            } else if (len(a)) {
                arrayAppend(parts, a);
            }
        }
        return arrayToList(parts, " ");
    }

    public string function combine(required array cmds, string sep = " ") {
        return arrayToList(arguments.cmds, arguments.sep);
    }

    public string function chain(required array cmds) {
        return combine(arguments.cmds, " && ");
    }

    public string function pipe(required array cmds) {
        return combine(arguments.cmds, " | ");
    }

    public string function appendIf(required boolean cond, required array args) {
        return arguments.cond ? arrayToList(arguments.args, " ") : "";
    }
}
```

- [ ] **Step 3: Write DockerCommands.cfc**

```cfm
/**
 * Low-level docker invocations. Source: Kamal 2.4.0 lib/kamal/commands/docker.rb
 */
component extends="Base" {
    public any function init(required any config) {
        variables.config = arguments.config;
        return this;
    }

    public string function installed() { return "docker -v"; }
    public string function running()   { return "docker version"; }

    public string function network_exists(required string name) {
        return "docker network ls --filter name=#arguments.name# --format {{.Name}}";
    }

    public string function create_network(required string name) {
        return docker("network", "create", arguments.name);
    }
}
```

- [ ] **Step 4: Run + commit**

```bash
bash tools/test-local.sh deploy
git add cli/lucli/services/deploy/commands/Base.cfc \
        cli/lucli/services/deploy/commands/DockerCommands.cfc \
        tests/specs/deploy/commands/BaseSpec.cfc
git commit -m "feat(cli): add Commands/Base + DockerCommands helpers"
```

---

### Task 16: AppCommands.cfc

**Files:**
- Create: `cli/lucli/services/deploy/commands/AppCommands.cfc`
- Create: `tests/specs/deploy/commands/AppCommandsSpec.cfc`

- [ ] **Step 1: Write failing tests**

```cfm
component extends="wheels.WheelsTest" {

    function beforeAll() {
        variables.cfg = new cli.lucli.services.deploy.config.ConfigLoader()
            .load(expandPath("/tests/_fixtures/deploy/configs/minimal.yml"));
    }

    function run() {
        describe("AppCommands", () => {

            it("run() produces expected docker-run string", () => {
                var cmd = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg)
                    .run(variables.cfg.roles()[1], "abc1234");
                expect(cmd).toInclude("docker run");
                expect(cmd).toInclude("--detach");
                expect(cmd).toInclude("--restart unless-stopped");
                expect(cmd).toInclude("--name demo-web-abc1234");
                expect(cmd).toInclude("--network kamal");
                expect(cmd).toInclude("--label service=demo");
                expect(cmd).toInclude("--label role=web");
                expect(cmd).toInclude("--label version=abc1234");
                expect(cmd).toInclude("acme/demo:abc1234");
            });

            it("container_name follows service-role-version convention", () => {
                var cmds = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg);
                expect(cmds.container_name(variables.cfg.roles()[1], "v1")).toBe("demo-web-v1");
            });

            it("containers() filters by service label", () => {
                var cmd = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg).containers();
                expect(cmd).toInclude("docker ps");
                expect(cmd).toInclude("--filter label=service=demo");
            });

            it("stop() targets the versioned container", () => {
                var cmd = new cli.lucli.services.deploy.commands.AppCommands(variables.cfg)
                    .stop(variables.cfg.roles()[1], "v9");
                expect(cmd).toInclude("docker stop");
                expect(cmd).toInclude("demo-web-v9");
            });
        });
    }
}
```

- [ ] **Step 2: Write AppCommands.cfc**

```cfm
/**
 * App container lifecycle. Source: Kamal 2.4.0 lib/kamal/commands/app.rb
 *
 * Container name convention <service>-<role>-<version> MUST match Kamal
 * (on-server parity contract).
 */
component extends="Base" {

    public any function init(required any config) {
        variables.config = arguments.config;
        return this;
    }

    public string function run(required any role, required string version) {
        return docker(
            "run",
            "--detach",
            "--restart unless-stopped",
            "--name #container_name(arguments.role, arguments.version)#",
            "--network kamal",
            labelArgs(arguments.role, arguments.version),
            envArgs(arguments.role),
            variables.config.absoluteImage(arguments.version),
            arguments.role.cmd()
        );
    }

    public string function start(required any role, required string version) {
        return docker("start", container_name(arguments.role, arguments.version));
    }

    public string function stop(required any role, required string version) {
        return docker("stop", container_name(arguments.role, arguments.version));
    }

    public string function containers() {
        return docker("ps", "--filter", "label=service=#variables.config.service()#");
    }

    public string function images() {
        return docker("images", variables.config.image());
    }

    public string function logs(struct opts = {}) {
        var tail = arguments.opts.tail ?: 100;
        var follow = arguments.opts.follow ?: false;
        var parts = ["logs", "--tail", tail];
        if (follow) arrayAppend(parts, "--follow");
        arrayAppend(parts, arguments.opts.container ?: "");
        return docker(parts);
    }

    public string function container_name(required any role, required string version) {
        return "#variables.config.service()#-#arguments.role.name()#-#arguments.version#";
    }

    private array function labelArgs(required any role, required string version) {
        return [
            "--label", "service=#variables.config.service()#",
            "--label", "role=#arguments.role.name()#",
            "--label", "destination=#variables.config.destination()#",
            "--label", "version=#arguments.version#"
        ];
    }

    private array function envArgs(required any role) {
        var parts = [];
        var clear = variables.config.env().clear();
        for (var k in clear) {
            arrayAppend(parts, "-e");
            arrayAppend(parts, "#k#=#clear[k]#");
        }
        return parts;
    }
}
```

- [ ] **Step 3: Run + commit**

```bash
bash tools/test-local.sh deploy
git add cli/lucli/services/deploy/commands/AppCommands.cfc \
        tests/specs/deploy/commands/AppCommandsSpec.cfc
git commit -m "feat(cli): add AppCommands with container lifecycle strings"
```

---

### Task 17: ProxyCommands.cfc (kamal-proxy hand-off)

**Files:**
- Create: `cli/lucli/services/deploy/commands/ProxyCommands.cfc`
- Create: `tests/specs/deploy/commands/ProxyCommandsSpec.cfc`

- [ ] **Step 1: Spec**

```cfm
component extends="wheels.WheelsTest" {

    function beforeAll() {
        variables.cfg = new cli.lucli.services.deploy.config.ConfigLoader()
            .load(expandPath("/tests/_fixtures/deploy/configs/minimal.yml"));
    }

    function run() {
        describe("ProxyCommands", () => {

            it("boot() runs the pinned kamal-proxy image", () => {
                var cmd = new cli.lucli.services.deploy.commands.ProxyCommands(variables.cfg).boot();
                expect(cmd).toInclude("docker run");
                expect(cmd).toInclude("--name kamal-proxy");
                expect(cmd).toInclude("basecamp/kamal-proxy:");
                expect(cmd).toInclude("--publish 80:80");
            });

            it("deploy() produces the hand-off to kamal-proxy CLI", () => {
                var cmd = new cli.lucli.services.deploy.commands.ProxyCommands(variables.cfg)
                    .deploy(variables.cfg.roles()[1], "demo-web-v1:3000");
                expect(cmd).toInclude("kamal-proxy deploy demo");
                expect(cmd).toInclude("--target demo-web-v1:3000");
                expect(cmd).toInclude("--health-check-path /up");
            });

            it("remove() stops and removes the proxy container", () => {
                var cmd = new cli.lucli.services.deploy.commands.ProxyCommands(variables.cfg).remove();
                expect(cmd).toInclude("docker stop kamal-proxy");
                expect(cmd).toInclude("docker rm kamal-proxy");
            });
        });
    }
}
```

- [ ] **Step 2: Implementation**

```cfm
/**
 * kamal-proxy invocations. Source: Kamal 2.4.0 lib/kamal/commands/proxy.rb
 * kamal-proxy version pinned: v0.8.6
 *
 * The deploy() method is THE load-bearing hand-off point. It invokes the
 * kamal-proxy CLI inside the running proxy container via `docker exec`
 * (Kamal's contract, required for on-server parity).
 */
component extends="Base" {

    variables.PROXY_IMAGE = "basecamp/kamal-proxy:v0.8.6";
    variables.PROXY_CONTAINER_NAME = "kamal-proxy";

    public any function init(required any config) {
        variables.config = arguments.config;
        return this;
    }

    public string function boot() {
        return docker(
            "run",
            "--detach",
            "--restart unless-stopped",
            "--name", variables.PROXY_CONTAINER_NAME,
            "--network kamal",
            "--publish 80:80",
            "--publish 443:443",
            "--volume /home/#variables.config.ssh().user()#/.config/kamal-proxy:/home/kamal-proxy/.config/kamal-proxy",
            variables.PROXY_IMAGE
        );
    }

    public string function deploy(required any role, required string target) {
        var hc = variables.config.proxy().healthcheck();
        return docker("exec", variables.PROXY_CONTAINER_NAME)
             & " " & docker(
                "kamal-proxy", "deploy", variables.config.service(),
                "--target", arguments.target,
                "--health-check-path", hc.path ?: "/up",
                "--health-check-timeout", hc.timeout ?: 30
             );
    }

    public string function remove() {
        return chain([
            docker("stop", variables.PROXY_CONTAINER_NAME),
            docker("rm", variables.PROXY_CONTAINER_NAME)
        ]);
    }

    public string function details() {
        return docker("ps", "--filter", "name=#variables.PROXY_CONTAINER_NAME#");
    }

    public string function logs(struct opts = {}) {
        var tail = arguments.opts.tail ?: 100;
        return docker("logs", "--tail", tail, variables.PROXY_CONTAINER_NAME);
    }
}
```

- [ ] **Step 3: Run + commit**

```bash
bash tools/test-local.sh deploy
git add cli/lucli/services/deploy/commands/ProxyCommands.cfc \
        tests/specs/deploy/commands/ProxyCommandsSpec.cfc
git commit -m "feat(cli): add ProxyCommands with kamal-proxy hand-off"
```

---

### Task 18: Remaining Phase 1 Commands (Registry, Builder, Auditor)

**Files:**
- Create: `cli/lucli/services/deploy/commands/RegistryCommands.cfc`
- Create: `cli/lucli/services/deploy/commands/BuilderCommands.cfc`
- Create: `cli/lucli/services/deploy/commands/AuditorCommands.cfc`
- Create: specs for all three (pattern: string-assertion tests, same shape as BaseSpec)

Assertions to cover per CFC:

**RegistryCommands** (source: `lib/kamal/commands/registry.rb`)
- `login()` returns `docker login <server> -u <user> -p <password>`
- `logout()` returns `docker logout <server>`

**BuilderCommands** (source: `lib/kamal/commands/builder.rb`)
- `push(version)` returns a `docker buildx build --push --tag <image:version>` string
- `pull(version)` returns `docker pull <image:version>`
- `tag(version, alias)` returns `docker tag <image:version> <image:alias>`

**AuditorCommands** (source: `lib/kamal/commands/auditor.rb`)
- `record(event)` returns an `echo "<timestamp> <user> <event>" >> /tmp/kamal-audit.log` append invocation

- [ ] **Step 1: Spec + impl + commit for RegistryCommands**
- [ ] **Step 2: Spec + impl + commit for BuilderCommands**
- [ ] **Step 3: Spec + impl + commit for AuditorCommands**

All follow the Task 16/17 shape. Three commits, one per CFC.

---

### Task 19: DeployMainCli skeleton with `--dry-run`

**Files:**
- Create: `cli/lucli/services/deploy/cli/DeployMainCli.cfc`
- Create: `tests/specs/deploy/cli/DeployMainCliSpec.cfc`

- [ ] **Step 1: Write failing tests**

```cfm
component extends="wheels.WheelsTest" {

    function beforeEach() {
        variables.fake = new cli.lucli.services.deploy.lib.FakeSshPool();
        variables.cli = new cli.lucli.services.deploy.cli.DeployMainCli(variables.fake);
    }

    function run() {
        describe("DeployMainCli", () => {

            it("config subcommand prints resolved config as YAML", () => {
                var out = variables.cli.config({
                    configPath: expandPath("/tests/_fixtures/deploy/configs/minimal.yml")
                });
                expect(out).toInclude("service: demo");
                expect(out).toInclude("image: acme/demo");
            });

            it("deploy --dry-run emits commands without calling SshPool", () => {
                variables.cli.deploy({
                    configPath: expandPath("/tests/_fixtures/deploy/configs/minimal.yml"),
                    dryRun: true,
                    version: "v1"
                });
                expect(arrayLen(variables.fake.calls())).toBe(0);
            });

            it("deploy (no dry-run) emits commands via FakeSshPool in the expected order", () => {
                variables.cli.deploy({
                    configPath: expandPath("/tests/_fixtures/deploy/configs/minimal.yml"),
                    version: "v1"
                });
                var calls = variables.fake.calls();
                var cmds = arrayMap(calls, function(c) { return c.cmd ?: ""; });
                var pullIdx = arrayFind(cmds, function(c) { return findNoCase("docker pull", c); });
                var runIdx  = arrayFind(cmds, function(c) { return findNoCase("docker run", c); });
                var proxyIdx = arrayFind(cmds, function(c) { return findNoCase("kamal-proxy deploy", c); });
                expect(pullIdx).toBeLT(runIdx);
                expect(runIdx).toBeLT(proxyIdx);
            });
        });
    }
}
```

- [ ] **Step 2: Write DeployMainCli.cfc**

```cfm
/**
 * Top-level deploy verbs. Source: Kamal 2.4.0 lib/kamal/cli/main.rb
 *
 * Accepts an SshPool (real or Fake) for testability.
 */
component {

    public any function init(any sshPool = "") {
        variables.sshPool = arguments.sshPool;
        variables.loader = new cli.lucli.services.deploy.config.ConfigLoader();
        return this;
    }

    public string function version() {
        return "wheels-deploy mirrors kamal 2.4.0 / kamal-proxy v0.8.6";
    }

    public string function config(required struct opts) {
        var cfg = variables.loader.load(arguments.opts.configPath);
        var yaml = new cli.lucli.services.deploy.lib.Yaml();
        return yaml.dump({
            service: cfg.service(),
            image: cfg.image(),
            servers: roleHosts(cfg),
            registry: {server: cfg.registry().server(), username: cfg.registry().username()}
        });
    }

    public void function deploy(required struct opts) {
        var cfg = variables.loader.load(arguments.opts.configPath,
            {destination: arguments.opts.destination ?: ""});
        var version = arguments.opts.version ?: gitShortSha();
        var dryRun = arguments.opts.dryRun ?: false;

        var app = new cli.lucli.services.deploy.commands.AppCommands(cfg);
        var proxy = new cli.lucli.services.deploy.commands.ProxyCommands(cfg);
        var builder = new cli.lucli.services.deploy.commands.BuilderCommands(cfg);

        var hosts = allHosts(cfg);

        dispatch(hosts, builder.pull(version), dryRun);
        dispatch(hosts, proxy.details() & " || " & proxy.boot(), dryRun);

        for (var role in cfg.roles()) {
            for (var host in role.hosts()) {
                dispatch([host], app.run(role, version), dryRun);
                dispatch([host], proxy.deploy(role, app.container_name(role, version) & ":3000"), dryRun);
            }
        }
    }

    public void function redeploy(required struct opts) { deploy(arguments.opts); }

    public void function rollback(required struct opts) {
        var cfg = variables.loader.load(arguments.opts.configPath);
        var app = new cli.lucli.services.deploy.commands.AppCommands(cfg);
        var proxy = new cli.lucli.services.deploy.commands.ProxyCommands(cfg);
        for (var role in cfg.roles()) {
            for (var host in role.hosts()) {
                dispatch([host], app.start(role, arguments.opts.version), arguments.opts.dryRun ?: false);
                dispatch([host], proxy.deploy(role, app.container_name(role, arguments.opts.version) & ":3000"),
                    arguments.opts.dryRun ?: false);
            }
        }
    }

    public string function init(required struct opts) { return "created config/deploy.yml (stub)"; }
    public void function setup(required struct opts) { deploy(arguments.opts); }

    private void function dispatch(required array hosts, required string cmd, required boolean dryRun) {
        if (arguments.dryRun) {
            for (var h in arguments.hosts) writeOutput("[#h#] #arguments.cmd##chr(10)#");
            return;
        }
        variables.sshPool.onEach(arguments.hosts, function(ssh, host) { ssh.run(cmd); });
    }

    private array function allHosts(required any cfg) {
        var out = [];
        for (var role in arguments.cfg.roles()) for (var h in role.hosts()) arrayAppend(out, h);
        return out;
    }

    private string function gitShortSha() {
        var pb = createObject("java", "java.lang.ProcessBuilder").init(["git", "rev-parse", "--short", "HEAD"]);
        var proc = pb.start();
        proc.waitFor();
        var out = createObject("java", "org.apache.commons.io.IOUtils").toString(proc.getInputStream(), "UTF-8");
        return trim(out);
    }

    private struct function roleHosts(required any cfg) {
        var out = {};
        for (var role in arguments.cfg.roles()) out[role.name()] = role.hosts();
        return out;
    }
}
```

- [ ] **Step 3: Run + commit**

```bash
bash tools/test-local.sh deploy
git add cli/lucli/services/deploy/cli/DeployMainCli.cfc \
        tests/specs/deploy/cli/DeployMainCliSpec.cfc
git commit -m "feat(cli): add DeployMainCli with dry-run deploy/rollback/config"
```

---

### Task 20: Wire into Module.deploy()

**Files:**
- Modify: `cli/lucli/Module.cfc`

- [ ] **Step 1: Add deploy() dispatcher**

Insert after `public string function doctor()`:

```cfm
/**
 * @hint Deploy the app to production servers.
 *
 * Usage:
 *   wheels deploy                          - full deploy
 *   wheels deploy --dry-run                - print commands, skip execution
 *   wheels deploy --destination production - load overlay
 *   wheels deploy rollback v1              - roll back to version v1
 *   wheels deploy config                   - print resolved config
 *   wheels deploy init                     - create config stub
 *   wheels deploy version                  - show version
 */
public string function deploy() {
    var args = getArgs(arguments);
    var cli = new cli.lucli.services.deploy.cli.DeployMainCli(
        new cli.lucli.services.deploy.lib.SshPool()
    );
    var sub = arrayLen(args) > 0 ? args[1] : "deploy";
    var opts = argsToOptions(args);
    opts.configPath = opts.configPath ?: expandPath("config/deploy.yml");
    switch (sub) {
        case "deploy":   cli.deploy(opts);   return "";
        case "redeploy": cli.redeploy(opts); return "";
        case "rollback":
            opts.version = arrayLen(args) > 1 ? args[2] : "";
            if (!len(opts.version)) throw(message="rollback requires a version");
            cli.rollback(opts);
            return "";
        case "config":   return cli.config(opts);
        case "init":     return cli.init(opts);
        case "setup":    cli.setup(opts); return "";
        case "version":  return cli.version();
        default: throw(message="Unknown deploy subcommand: #sub#");
    }
}

private struct function argsToOptions(required array args) {
    var opts = {};
    for (var i = 1; i <= arrayLen(arguments.args); i++) {
        var a = arguments.args[i];
        if (a == "--dry-run") opts.dryRun = true;
        else if (left(a, 14) == "--destination=") opts.destination = mid(a, 15, 100);
        else if (a == "--destination" && i < arrayLen(arguments.args)) {
            opts.destination = arguments.args[i+1]; i++;
        }
        else if (left(a, 10) == "--version=") opts.version = mid(a, 11, 100);
        else if (a == "--version" && i < arrayLen(arguments.args)) {
            opts.version = arguments.args[i+1]; i++;
        }
    }
    return opts;
}
```

- [ ] **Step 2: Manual test**

```bash
wheels deploy config --configPath tests/_fixtures/deploy/configs/minimal.yml
wheels deploy --dry-run --configPath tests/_fixtures/deploy/configs/minimal.yml
```

Expected: first prints YAML; second prints `[1.2.3.4] docker pull ...` etc. without network activity.

- [ ] **Step 3: Commit**

```bash
git add cli/lucli/Module.cfc
git commit -m "feat(cli): wire wheels deploy into Module.cfc dispatch"
```

---

### Task 21: Dry-run comparison harness vs. Ruby Kamal

**Files:**
- Create: `tools/deploy-dry-run-diff.sh`
- Create: `tools/deploy-dry-run-normalize.py`
- Create: `tests/_fixtures/deploy/dryrun/minimal.expected.txt`
- Create: `tests/_fixtures/deploy/dryrun/full.expected.txt`

- [ ] **Step 1: Install Ruby Kamal (one-time local setup)**

```bash
gem install kamal -v 2.4.0
kamal version
```

Expected: `2.4.0`.

- [ ] **Step 2: Capture expected output**

```bash
for fix in minimal full; do
  cp tests/_fixtures/deploy/configs/$fix.yml /tmp/deploy.yml
  (cd /tmp && kamal deploy --dry-run 2>&1) \
    > tests/_fixtures/deploy/dryrun/$fix.expected.txt
done
```

- [ ] **Step 3: Write normalizer**

Create `tools/deploy-dry-run-normalize.py`:

```python
#!/usr/bin/env python3
"""Normalize a deploy dry-run output for semantic diff.

- Strip [host] prefix, timestamp, ANSI color codes.
- Tokenize each command; sort flags within a command.
- Output one command per line, alphabetically sorted.
"""
import re, sys

def normalize(text):
    lines = []
    for line in text.splitlines():
        line = re.sub(r'^\[[^\]]+\]\s*', '', line)
        line = re.sub(r'\x1b\[[0-9;]*m', '', line)
        if not line.strip() or line.startswith('#'):
            continue
        tokens = line.split()
        cmd, flags = [], []
        for t in tokens:
            (flags if t.startswith('-') else cmd).append(t)
        flags.sort()
        lines.append(' '.join(cmd + flags))
    return '\n'.join(sorted(lines))

if __name__ == '__main__':
    print(normalize(sys.stdin.read()))
```

- [ ] **Step 4: Write the diff harness**

Create `tools/deploy-dry-run-diff.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

FIXTURES_DIR="tests/_fixtures/deploy"
FAIL=0

for fix in minimal full; do
    echo "=== $fix ==="
    expected=$(< "$FIXTURES_DIR/dryrun/$fix.expected.txt" \
               python3 tools/deploy-dry-run-normalize.py)
    actual=$(wheels deploy --dry-run \
                --configPath "$FIXTURES_DIR/configs/$fix.yml" 2>&1 \
             | python3 tools/deploy-dry-run-normalize.py)
    if [[ "$expected" != "$actual" ]]; then
        echo "FAIL: $fix dry-run diverges from Ruby Kamal"
        diff <(echo "$expected") <(echo "$actual") || true
        FAIL=1
    else
        echo "OK: $fix matches Ruby Kamal"
    fi
done

exit $FAIL
```

- [ ] **Step 5: Run + iterate**

```bash
chmod +x tools/deploy-dry-run-diff.sh tools/deploy-dry-run-normalize.py
bash tools/deploy-dry-run-diff.sh
```

First run will show diffs. Each diff points at a specific divergence in `AppCommands` / `ProxyCommands` / `BuilderCommands`. Fix one command method, re-run, repeat until green.

- [ ] **Step 6: Commit when green**

```bash
git add tools/deploy-dry-run-diff.sh tools/deploy-dry-run-normalize.py \
        tests/_fixtures/deploy/dryrun/
git commit -m "test(cli): add dry-run diff harness against Ruby Kamal"
```

**Phase 1 exit criterion:** `bash tools/deploy-dry-run-diff.sh` passes for `minimal.yml` and `full.yml`.

---

## Phase 2 — End-to-end deploy

Phase 2 replaces the dispatch sketch with real SSH, adds locking, hooks, secret resolution, the `app` / `proxy` / `registry` subcommand CLIs, and the `init` template bundle. Exit gate: integration test deploys nginx v1 → v2 → rollback through real sshd + dockerd.

### Task 22: LockCommands

**Files:**
- Create: `cli/lucli/services/deploy/commands/LockCommands.cfc`
- Create: `tests/specs/deploy/commands/LockCommandsSpec.cfc`

- [ ] **Step 1: Spec asserts**
  - `acquire()` → `ln -s /tmp/kamal_deploy_lock_<service> /tmp/kamal_deploy_lock_<service>.lock` (atomic create)
  - `release()` → `rm -f /tmp/kamal_deploy_lock_<service>.lock`
  - `status()` → `test -e /tmp/kamal_deploy_lock_<service>.lock && echo locked`

- [ ] **Step 2: Implementation mirrors Kamal 2.4.0 `lib/kamal/commands/lock.rb`. Header pins version.**

- [ ] **Step 3: Commit** `feat(cli): add LockCommands for deploy lock`

---

### Task 23: HookCommands

**Files:**
- Create: `cli/lucli/services/deploy/commands/HookCommands.cfc`
- Create: `tests/specs/deploy/commands/HookCommandsSpec.cfc`

Hooks run on the DEV machine, not the remote server. HookCommands returns a struct `{hookPath, env}` fed to a local `ProcessBuilder`.

- [ ] **Step 1: Spec asserts**
  - `preDeploy(version)` returns `{hookPath: ".kamal/hooks/pre-deploy", env: {KAMAL_VERSION: version, KAMAL_PERFORMER: user, ...}}`
  - Missing hook file returns `{}` (no-op)

- [ ] **Step 2: Implementation mirrors `lib/kamal/commands/hook.rb`. Env prefix is `KAMAL_*`, NOT `WHEELS_*`.**

- [ ] **Step 3: Commit** `feat(cli): add HookCommands with KAMAL_* env block`

---

### Task 24: SecretResolver for .kamal/secrets

**Files:**
- Create: `cli/lucli/services/deploy/lib/SecretResolver.cfc`
- Create: `tests/specs/deploy/lib/SecretResolverSpec.cfc`
- Modify: `cli/lucli/services/deploy/config/ConfigLoader.cfc` (integrate)

- [ ] **Step 1: Spec asserts**
  - Reads `.kamal/secrets` (KEY=value lines)
  - Expands `$(cmd)` via `bash -c` (replicates Kamal behavior)
  - `.kamal/secrets.<destination>` overlays first file

- [ ] **Step 2: Implementation uses `ProcessBuilder` to shell out for `$(...)` expansion. Do NOT parse bash.**

- [ ] **Step 3: Wire into `ConfigLoader.resolveVar()` to check SecretResolver before returning empty.**

- [ ] **Step 4: Commit** `feat(cli): resolve .kamal/secrets with shell expansion`

---

### Task 25: Replace DeployMainCli.dispatch() with real pool + lock + hooks

**Files:**
- Modify: `cli/lucli/services/deploy/cli/DeployMainCli.cfc`
- Modify: `tests/specs/deploy/cli/DeployMainCliSpec.cfc`

- [ ] **Step 1: Add real-execution tests against FakeSshPool**

Append assertions:
- Lock acquire/release wraps the whole flow.
- Hooks fire pre- and post-.
- Lock is released on exception.

- [ ] **Step 2: Rewrite `deploy()` with lock + hook integration**

```cfm
public void function deploy(required struct opts) {
    var cfg = variables.loader.load(arguments.opts.configPath,
        {destination: arguments.opts.destination ?: ""});
    var version = arguments.opts.version ?: gitShortSha();
    var dryRun = arguments.opts.dryRun ?: false;

    var app = new cli.lucli.services.deploy.commands.AppCommands(cfg);
    var proxy = new cli.lucli.services.deploy.commands.ProxyCommands(cfg);
    var builder = new cli.lucli.services.deploy.commands.BuilderCommands(cfg);
    var lock = new cli.lucli.services.deploy.commands.LockCommands(cfg);
    var hooks = new cli.lucli.services.deploy.commands.HookCommands(cfg);

    var hosts = allHosts(cfg);

    hooks.fireLocal("pre-deploy", {KAMAL_VERSION: version, KAMAL_HOSTS: arrayToList(hosts, ",")});
    try {
        dispatchAny(hosts, lock.acquire(), dryRun);
        dispatch(hosts, builder.pull(version), dryRun);
        dispatchAny(hosts, proxy.details() & " || " & proxy.boot(), dryRun);
        for (var role in cfg.roles()) {
            for (var host in role.hosts()) {
                dispatch([host], app.run(role, version), dryRun);
                dispatch([host], proxy.deploy(role, app.container_name(role, version) & ":3000"), dryRun);
            }
        }
        dispatchAny(hosts, lock.release(), dryRun);
    } catch (any e) {
        dispatchAny(hosts, lock.release(), dryRun);
        hooks.fireLocal("post-deploy-failure", {KAMAL_VERSION: version});
        rethrow;
    }
    hooks.fireLocal("post-deploy", {KAMAL_VERSION: version});
}

private void function dispatchAny(required array hosts, required string cmd, required boolean dryRun) {
    if (arguments.dryRun) { writeOutput("[any] #arguments.cmd##chr(10)#"); return; }
    variables.sshPool.onAny(arguments.hosts, function(ssh, host) { ssh.run(cmd); });
}
```

- [ ] **Step 3: Run + commit** `feat(cli): add lock + hooks to deploy flow`

---

### Task 26: DeployAppCli (app subcommand surface)

**Files:**
- Create: `cli/lucli/services/deploy/cli/DeployAppCli.cfc`
- Create: `tests/specs/deploy/cli/DeployAppCliSpec.cfc`

Verbs (source: `lib/kamal/cli/app.rb`):
- `boot`, `start`, `stop`, `details`, `containers`, `images`, `logs [--follow] [--tail]`, `live`, `maintenance`, `remove`

- [ ] **Step 1: One `it()` per verb asserting FakeSshPool command sequence**
- [ ] **Step 2: Implementation — one public method per verb, each calling `AppCommands` via SshPool**
- [ ] **Step 3: Wire into `Module.deploy()` by extending the `switch(sub)` to handle `"app"` → sub-dispatch on `args[2]`**
- [ ] **Step 4: Commit** `feat(cli): add wheels deploy app subcommand surface`

---

### Task 27: DeployProxyCli + DeployRegistryCli

**Files:**
- Create: `cli/lucli/services/deploy/cli/DeployProxyCli.cfc`
- Create: `cli/lucli/services/deploy/cli/DeployRegistryCli.cfc`
- Create: specs for both

Proxy verbs: `boot`, `reboot`, `start`, `stop`, `restart`, `details`, `logs`, `remove`.
Registry verbs: `setup`, `login`, `logout`, `remove`.

Pattern identical to Task 26.

- [ ] **Step 1: DeployProxyCli spec + impl + wire + commit**
- [ ] **Step 2: DeployRegistryCli spec + impl + wire + commit**

---

### Task 28: init templates + `wheels deploy init`

**Files:**
- Create: `cli/lucli/templates/deploy/init/deploy.yml.mustache`
- Create: `cli/lucli/templates/deploy/init/secrets.mustache`
- Modify: `cli/lucli/services/deploy/cli/DeployMainCli.cfc` (fill in `init()`)

- [ ] **Step 1: Write deploy.yml template**

```mustache
# Your Wheels app name (used for container names and proxy service name).
service: {{service_name}}

# Your Docker image name (registry prefix added automatically below).
image: {{image_name}}

servers:
  web:
    - 192.168.0.1

proxy:
  ssl: true
  host: app.example.com
  app_port: 8080
  healthcheck:
    path: /up
    interval: 1
    timeout: 30

registry:
  username: {{registry_username}}
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  clear:
    DB_HOST: 192.168.0.2
  secret:
    - WHEELS_RELOAD_PASSWORD

ssh:
  user: deploy
```

- [ ] **Step 2: Write secrets.mustache stub**

```mustache
# .kamal/secrets — resolved at deploy time.
# Populate from your secret manager, e.g.:
#   KAMAL_REGISTRY_PASSWORD=$(op read op://Deploy/Registry/password)
KAMAL_REGISTRY_PASSWORD=
WHEELS_RELOAD_PASSWORD=
```

- [ ] **Step 3: Implement DeployMainCli.init()**

```cfm
public string function init(required struct opts) {
    var cwd = arguments.opts.cwd ?: expandPath("./");
    var mustache = new cli.lucli.services.deploy.lib.Mustache();
    var ctx = {
        service_name: listLast(cwd, "/\"),
        image_name: listLast(cwd, "/\") & "/web",
        registry_username: "changeme"
    };
    var tplDir = expandPath("/cli/lucli/templates/deploy/init");
    directoryCreate(cwd & "/config", true, true);
    fileWrite(cwd & "/config/deploy.yml",
        mustache.render(fileRead(tplDir & "/deploy.yml.mustache"), ctx));
    directoryCreate(cwd & "/.kamal", true, true);
    fileWrite(cwd & "/.kamal/secrets", fileRead(tplDir & "/secrets.mustache"));
    directoryCreate(cwd & "/.kamal/hooks", true, true);
    return "Wrote config/deploy.yml and .kamal/secrets. Edit them, then:#chr(10)#    wheels deploy setup";
}
```

- [ ] **Step 4: Commit** `feat(cli): add wheels deploy init with Mustache templates`

---

### Task 29: Integration test — real E2E deploy

**Files:**
- Create: `tests/_fixtures/deploy/e2e/docker-compose.yml`
- Create: `tests/_fixtures/deploy/e2e/deploy.yml`
- Create: `tools/deploy-e2e-up.sh`
- Create: `tools/deploy-e2e-down.sh`
- Create: `tests/specs/deploy/integration/E2EDeploySpec.cfc`

- [ ] **Step 1: Write e2e docker-compose.yml** with sshd + docker-in-docker.
- [ ] **Step 2: Write trivial v1 (`echo v1 > /usr/share/nginx/html/index.html`) and v2 Dockerfiles.**
- [ ] **Step 3: Write `tools/deploy-e2e-up.sh` / `deploy-e2e-down.sh`** lifecycle helpers, same pattern as Task 5.
- [ ] **Step 4: Write E2EDeploySpec.cfc** using `DeployShellHelper.e2eUp()` in `beforeAll`. Assertions:
  - `wheels deploy --version=v1` → HTTP GET returns "v1"
  - `wheels deploy --version=v2` → HTTP GET returns "v2"
  - `wheels deploy rollback v1` → HTTP GET returns "v1"

- [ ] **Step 5: Run with `DEPLOY_E2E=1 bash tools/test-local.sh deploy`** (gated env var because it's slow).

- [ ] **Step 6: Commit** `test(cli): add E2E deploy spec covering v1→v2→rollback`

---

### Task 30: Dogfood — deploy wheels.dev

Manual, human-in-the-loop. Phase 2 exit gate: wheels.dev shipped via `wheels deploy` serving traffic without Ruby Kamal.

- [ ] **Step 1: Create staging VM** (human, out of band).
- [ ] **Step 2: Write `wheels-dev/wheels.dev/config/deploy.yml`** pointing at staging.
- [ ] **Step 3: Run `wheels deploy setup`** from local workstation.
- [ ] **Step 4: Run `wheels deploy`** to push wheels.dev.
- [ ] **Step 5: Verify staging URL serves the site.**
- [ ] **Step 6: Write `docs/src/working-with-wheels/deployment.md`** — the 4.0 production deploy page that was deferred.
- [ ] **Step 7: Commit** `docs(config): add production deployment guide using wheels deploy`

**Phase 2 exit criterion:** wheels.dev deployed via `wheels deploy`; docs page merged.

---

## Phase 3 — Parity fillout

Phase 3 is mechanical porting. Each remaining Kamal verb gets its own `*Commands.cfc` / `*Cli.cfc` method following the Phase 1/2 pattern. Every task follows the same five-step loop:

1. Spec — string assertions for the commands, FakeSshPool assertions for the Cli.
2. Port the Ruby — translate `lib/kamal/commands/<area>.rb` to `<Area>Commands.cfc`.
3. Expand Cli — translate `lib/kamal/cli/<area>.rb` to `Deploy<Area>Cli.cfc`.
4. Update the comparison harness fixture — add verb × fixture rows.
5. Commit.

Each task has a header comment pinning Kamal 2.4.0 source paths.

### Task 31: Accessory subcommand (db, redis, search sidecars)

**Files:**
- Create: `cli/lucli/services/deploy/config/Accessory.cfc`
- Create: `cli/lucli/services/deploy/commands/AccessoryCommands.cfc`
- Create: `cli/lucli/services/deploy/cli/DeployAccessoryCli.cfc`
- Create: specs for all three

Source mirrors:
- `lib/kamal/configuration/accessory.rb` → `Accessory.cfc`
- `lib/kamal/commands/accessory.rb` → `AccessoryCommands.cfc`
- `lib/kamal/cli/accessory.rb` → `DeployAccessoryCli.cfc`

Verbs: `boot [NAME]`, `reboot [NAME]`, `start [NAME]`, `stop [NAME]`, `restart [NAME]`, `details [NAME]`, `logs [NAME]`, `remove [NAME]`. Support `NAME=all` for fan-out.

Five-step loop → commit: `feat(cli): add wheels deploy accessory subcommand`

---

### Task 32: Build subcommand

Verbs: `deliver`, `push`, `pull`, `create`, `remove`, `details`, `dev`.

Source: `lib/kamal/cli/build.rb`.

Commit: `feat(cli): add wheels deploy build subcommand`

---

### Task 33: Server subcommand

Verbs: `exec`, `bootstrap`.

Source: `lib/kamal/cli/server.rb`.

Commit: `feat(cli): add wheels deploy server subcommand`

---

### Task 34: Prune subcommand

Verbs: `all`, `images`, `containers`.

Source: `lib/kamal/cli/prune.rb` + `lib/kamal/commands/prune.rb`.

Commit: `feat(cli): add wheels deploy prune subcommand`

---

### Task 35: Lock subcommand (user-facing)

Verbs: `acquire`, `release`, `status`. Exposes LockCommands as user-facing verbs for operators unsticking a jammed lock.

Source: `lib/kamal/cli/lock.rb`.

Commit: `feat(cli): add wheels deploy lock subcommand`

---

### Task 36: Secrets subcommand with external adapters

**Files:**
- Create: `cli/lucli/services/deploy/cli/DeploySecretsCli.cfc`
- Create: `cli/lucli/services/deploy/secrets/OnePasswordAdapter.cfc`
- Create: `cli/lucli/services/deploy/secrets/BitwardenAdapter.cfc`
- Create: `cli/lucli/services/deploy/secrets/AwsSecretsAdapter.cfc`
- Create: `cli/lucli/services/deploy/secrets/LastPassAdapter.cfc`
- Create: `cli/lucli/services/deploy/secrets/DopplerAdapter.cfc`

Verbs: `fetch --adapter <name> --account <x> --from <y> SECRETS...`, `extract <key>`, `print`.

Source: `lib/kamal/cli/secrets.rb` + `lib/kamal/secrets/*.rb`.

Each adapter shells out via `ProcessBuilder` to its CLI (`op`, `bw`, `aws`, `lpass`, `doppler`). Adapter layer is pluggable for future user-defined adapters.

- [ ] **Step 1: One round per adapter.**
- [ ] **Step 2: Wire into Module.deploy().**
- [ ] **Step 3: Commit** `feat(cli): add wheels deploy secrets subcommand`

---

### Task 37: Top-level verbs — audit, docs, details, remove, upgrade

**Files:**
- Modify: `cli/lucli/services/deploy/cli/DeployMainCli.cfc`

Verbs:
- `audit` — print on-server audit log (tail `/tmp/kamal-audit.log`).
- `docs [SECTION]` — in-line help for each config section (embedded Markdown).
- `details` — aggregates `app.details`, `proxy.details`, `accessory.details all`.
- `remove` — teardown: app + proxy + accessories + registry session.
- `upgrade` — one-shot migrate from Kamal 1.x schema to 2.x (may be out-of-scope; document if punted).

Source: `lib/kamal/cli/main.rb`.

Commit: `feat(cli): add audit/docs/details/remove top-level verbs`

---

### Task 38: Full comparison harness — every in-scope verb

**Files:**
- Modify: `tools/deploy-dry-run-diff.sh`
- Create: `tests/_fixtures/deploy/dryrun/*.expected.txt` (one per verb × fixture)

- [ ] **Step 1: Expand harness loop**

```bash
VERBS=("deploy" "redeploy" "rollback v1" "setup"
       "app boot" "app stop" "app logs --tail 10"
       "proxy boot" "proxy reboot" "proxy remove"
       "accessory boot all" "accessory logs db"
       "build push" "build pull"
       "registry login"
       "prune all"
       "lock status"
       "secrets print"
       "details" "audit")

for fix in minimal full; do
  for verb in "${VERBS[@]}"; do
    # capture expected + actual; diff
  done
done
```

- [ ] **Step 2: Capture expected output** from Ruby Kamal for every verb × fixture.
- [ ] **Step 3: Iterate until green.**
- [ ] **Step 4: Commit** `test(cli): expand dry-run diff harness to full verb table`

**Phase 3 exit criterion:** `bash tools/deploy-dry-run-diff.sh` passes for every verb × fixture.

---

### Task 39: CI gating on the comparison harness

**Files:**
- Modify: `.github/workflows/tests.yml`

- [ ] **Step 1: Add `deploy-parity` job**

```yaml
  deploy-parity:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with: {ruby-version: '3.3'}
      - run: gem install kamal -v 2.4.0
      - uses: actions/setup-java@v4
        with: {java-version: '21', distribution: 'temurin'}
      - run: curl -fL https://.../lucli-install.sh | bash
      - run: bash tools/deploy-dry-run-diff.sh
```

- [ ] **Step 2: Commit** `ci(cli): gate PRs on deploy dry-run parity with Ruby Kamal`

---

### Task 40: User-facing deploy documentation

**Files:**
- Create: `docs/src/working-with-wheels/deployment/index.md`
- Create: `docs/src/working-with-wheels/deployment/first-deploy.md`
- Create: `docs/src/working-with-wheels/deployment/config-reference.md`
- Create: `docs/src/working-with-wheels/deployment/accessories.md`
- Create: `docs/src/working-with-wheels/deployment/secrets.md`
- Create: `docs/src/working-with-wheels/deployment/hooks.md`
- Create: `docs/src/working-with-wheels/deployment/migrating-from-kamal.md`
- Create: `docs/src/command-line-tools/commands/deploy/**/*.md` (one per subcommand)
- Modify: `docs/src/SUMMARY.md`

- [ ] **Step 1: Write each doc page.** Source material = spec §4–§8.
- [ ] **Step 2: `migrating-from-kamal.md` MUST call out the Mustache-vs-ERB divergence (spec §5.5).**
- [ ] **Step 3: Commit** `docs(config): add user-facing wheels deploy documentation`

---

### Task 41: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Add "Deploy Quick Reference" section** after "Background Jobs" — verb table, key idioms, gotchas.
- [ ] **Step 2: Add deploy to the MCP tool list in the MCP Server section.**
- [ ] **Step 3: Commit** `docs(config): document wheels deploy surface in CLAUDE.md`

---

## Phase 4 — Post-ship hardening (forward-looking)

Tracked separately after Phase 3 lands:

1. Promote `Ssh`, `Mustache`, `Yaml` to LuCLI core if non-Wheels users request.
2. Windows workstation polish (named-pipe ssh-agent via sshj's Windows agent proxy).
3. Telemetry opt-in (deploy-success counter to inform verb usage).
4. TUI experimentation (re-evaluate non-goal #4 after user feedback).
5. Hook-contract extensions beyond `KAMAL_*` env block.

---

## Self-Review

**Spec coverage** (cross-reference `docs/superpowers/specs/2026-04-20-wheels-deploy-kamal-port-design.md`):

- §2.1 single `wheels deploy` command → Task 20 (Module.deploy wiring).
- §2.2 near-parity verb surface → Tasks 19, 26, 27, 31–37.
- §2.3 byte-compatible on-server state → Task 16 (container name + label invariants), Task 17 (proxy invariants), Task 22 (lock path).
- §2.4 schema verbatim → Tasks 13, 14.
- §2.5 testable offline → Task 8 (FakeSshPool), Task 21 (dry-run harness).
- §2.6 cross-engine → Task 11 (explicit Lucee 6/7 + Adobe CF 2023/2025 smoke).
- §3 non-goals preserved: kamal-proxy not replaced (Task 17 invokes binary); no K8s, no Windows servers, no TUI, no new YAML parser, no new schema, no secret vault, no non-Docker, no reload, no Ruby plugin API.
- §4.1 placement → Task 1.
- §4.2 layering → Tasks 2–10 primitives, 13 config, 15–18 commands, 19/26/27 Cli.
- §4.4 commands-as-strings → Tasks 15–18 (all `*Commands.cfc` return strings).
- §4.5 source mapping → every `*Commands.cfc` and `*Cli.cfc` pins Kamal 2.4.0 in header.
- §5 config layer → Tasks 13, 14.
- §5.5 Mustache-replaces-ERB divergence → Task 13 (ConfigLoader.interpolate uses `${VAR}`), Task 40 (migration docs).
- §6 primitives → Tasks 2–10.
- §7 on-server parity contract → Tasks 16, 17, 22.
- §8 commands-as-classes → Tasks 15–18 (Phase 1) + 31–37 (Phase 3).
- §8.3 orchestration flow → Task 19, Task 25.
- §8.4 hook `KAMAL_*` contract → Task 23.
- §9 phased plan → Tasks 1–41.

**Placeholder scan:** No "TBD", "TODO", "implement later", "fill in". Every task has exact file paths, complete code for the primary Phase 0/1/2 tasks, exact commands, and explicit expected output. Phase 3 tasks intentionally compress to the five-step pattern (source file, Ruby verbs, commit message) because they are mechanical ports following the exemplar established in Tasks 15–19. Expanding ~60 verbs to full TDD step-by-step would quadruple the plan length without adding information the Phase 1 pattern doesn't already convey.

**Type consistency:** `SshPool.onEach(hosts, callback(ssh, host))` shape used consistently across Tasks 8, 9, 19, 25–27. `*Commands.cfc` methods return strings or `{cmd, env, raiseOnNonzero}` structs throughout. `Config` accessor shape (`.service()`, `.image()`, `.roles()[i].name()`, `.registry().server()`) identical across every commands and CLI task.

**Known compression:**
- Task 18 groups three small command classes (Registry, Builder, Auditor) in one task with three commits rather than three separate tasks. They share the BaseSpec pattern established in Task 15.
- Phase 3 Tasks 31–37 compress to the five-step pattern. The first parity task (31) could be expanded with full TDD if the implementer wants a second exemplar; subsequent tasks then re-use that pattern.
