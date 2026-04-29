# Fresh-VM Batch D — DI Singleton Bug + Auth Wiring

> **For agentic workers:** REQUIRED SUB-SKILLs in execution order:
> 1. superpowers:systematic-debugging (Phase 1–2 — reproduce, diagnose)
> 2. superpowers:test-driven-development (Phase 3–5 — every fix has a failing test first)
> 3. superpowers:subagent-driven-development (recommended) OR superpowers:executing-plans for the orchestration
>
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Find and fix the framework bug where, in a real Wheels app, `injector().map(X).to(Y).asSingleton()` plus `service(X)` returns different instances across requests for `wheels.auth.Authenticator`, making chapter 6b of the tutorial unfollowable. Also improve the silent-failure mode when no auth strategies are registered.

**Architecture.** Five-phase reproduce → diagnose → fix → defend → regress workflow.

- **Phase 1 (reproduce):** Write a failing integration test that captures the tutorial's setup and demonstrates the bug at the lowest level. We can't fix what we can't repro, and a unit test at [`vendor/wheels/tests/specs/di/InjectorSpec.cfc:25-30`](../../vendor/wheels/tests/specs/di/InjectorSpec.cfc) already proves `asSingleton()` works in isolation — so the bug is in lifecycle interaction, not in the Injector class itself.
- **Phase 2 (diagnose):** Apply systematic debugging to identify the root cause. Three ranked hypotheses below.
- **Phase 3 (fix):** Apply the smallest fix that addresses the root cause. Verify the failing integration test now passes.
- **Phase 4 (defend):** Improve `Authenticator.authenticate()` error messages so the next time strategies aren't registered, the failure is loud and diagnostic instead of silent.
- **Phase 5 (regress):** Add a permanent regression test (Phase 1's test promoted to the suite) plus an InjectorSpec test that locks down the singleton-across-reloads contract.

**Tech Stack:** CFML/Lucee, WheelsTest BDD, [LuCLI local test harness](../../tools/test-local.sh). For full-app reproduction, `wheels new` + `wheels start` against a temp dir.

**Source finding:** [#9 in the 2026-04-29 fresh-VM triage](./2026-04-29-fresh-vm-onboarding-findings.md). Original journal entry preserved in the originating session.

---

## Hypothesis space (Phase 2 will narrow this down)

The Injector's `asSingleton()` works at the unit-test level. The bug must be in how the Injector interacts with the request lifecycle. Three candidates, ranked:

### H1 (most likely): Plugin/package reload on every request re-applies bindings, and `$findLastMappingKey()` flags the wrong key

In development mode, [`vendor/wheels/events/EventMethods.cfc:178-185`](../../vendor/wheels/events/EventMethods.cfc) calls `$loadPlugins()` and `$loadPackages()` on every request because `application.wheels.cachePlugins` is false. Both call ServiceProvider `register()` ([`Global.cfc:2889`](../../vendor/wheels/Global.cfc), [`Global.cfc:2982`](../../vendor/wheels/Global.cfc)) with the existing `application.wheelsdi`.

ServiceProviders typically do `container.map("X").to("Y").asSingleton()`. The `asSingleton()` implementation ([`Injector.cfc:84-90`](../../vendor/wheels/Injector.cfc)):

```cfm
public Injector function asSingleton() {
    local.lastKey = $findLastMappingKey();
    if (len(local.lastKey)) {
        variables.singletonFlags[local.lastKey] = true;
    }
    return this;
}

private string function $findLastMappingKey() {
    local.lastKey = "";
    for (local.key in variables.mappings) {
        local.lastKey = local.key;
    }
    return local.lastKey;
}
```

`$findLastMappingKey()` walks the entire `variables.mappings` struct and returns the last key encountered. **Struct iteration order is not guaranteed in CFML** — Lucee 5/6 differ from Adobe CF differ from Lucee 7. If `$findLastMappingKey()` returns a key other than the one just added, `asSingleton()` flags the wrong mapping. The ACTUAL `authenticator` mapping never gets `singletonFlags["authenticator"] = true`, so `getInstance("authenticator")` skips the cache check and creates a fresh component on every call.

**Why this fits the symptoms:** the "different instance per call" claim is exactly what happens when the singleton flag is missing. This would also explain why the unit test passes (in isolation, only ONE mapping exists, so `$findLastMappingKey()` always returns it).

### H2 (possible): `onApplicationStart` re-firing mid-request resets `application.wheelsdi`

[`Application.cfc:169-171`](../../public/Application.cfc) re-runs `onApplicationStart()` if `application.wheels.eventPath` is missing. `onApplicationStart()` does `new wheels.Injector("wheels.Bindings")`, which overwrites `application.wheelsdi` and resets the singleton cache.

**Why this fits:** explains "different instance per call" if `application.wheels` gets cleared between requests for some reason.

**Why this might not fit:** the user reported the bug repeated even within a single request after registering in `onRequestStart`. Re-firing onApplicationStart should be a once-per-request issue at most.

### H3 (less likely): `config/services.cfm` is being re-included mid-request

If services.cfm is included again somewhere we haven't found, the user's `injector().map().to().asSingleton()` would re-execute, but it should be idempotent (overwrites with the same path, sets flag again). Only an issue if combined with H1's `$findLastMappingKey` problem.

We test these in order in Phase 2.

---

## Task 1: Repro — failing integration test for the bug

**Files:**
- Create: `vendor/wheels/tests/specs/di/InjectorLifecycleSpec.cfc`

This test reproduces the bug **without** spinning up a full HTTP server. We simulate the relevant lifecycle steps in a single test process: build an Injector, register `authenticator` + `sessionStrategy` as singletons, register a strategy on the resolved authenticator, then re-trigger the parts of the request lifecycle that could reset state, and verify the singleton survives.

- [ ] **Step 1: Write the failing spec**

```cfm
// vendor/wheels/tests/specs/di/InjectorLifecycleSpec.cfc
component extends="wheels.WheelsTest" {

    function run() {

        describe("Injector lifecycle — singleton survival", () => {

            beforeEach(() => {
                di = new wheels.Injector(binderPath="wheels.tests._assets.di.TestBindings");
            });

            it("auth Authenticator + SessionStrategy survive ServiceProvider re-registration (H1)", () => {
                // Step A: First registration — what config/services.cfm does
                di.map("authenticator").to("wheels.auth.Authenticator").asSingleton();
                di.map("sessionStrategy").to("wheels.auth.SessionStrategy").asSingleton();

                // Step B: Resolve and register a strategy — what app/events/onapplicationstart.cfm does
                var auth = di.getInstance("authenticator");
                var sessionStrategy = di.getInstance("sessionStrategy");
                auth.registerStrategy(name="session", strategy=sessionStrategy);

                expect(auth.getStrategyNames()).toBe(["session"]);

                // Step C: Simulate plugin/package reload — what $loadPlugins/$loadPackages does
                // on every dev-mode request. ServiceProviders call .map().to().asSingleton() again.
                di.map("authenticator").to("wheels.auth.Authenticator").asSingleton();
                di.map("sessionStrategy").to("wheels.auth.SessionStrategy").asSingleton();

                // Step D: Resolve again — must return the SAME authenticator with strategies intact
                var authAgain = di.getInstance("authenticator");
                expect(authAgain).toBe(auth);
                expect(authAgain.getStrategyNames()).toBe(["session"]);
            });

            it("singleton flag survives a third-party mapping registered between (H1, focused)", () => {
                // Hypothesis H1: $findLastMappingKey returns the wrong key when a
                // service provider adds an unrelated mapping after the user's.
                di.map("authenticator").to("wheels.auth.Authenticator").asSingleton();

                // A plugin's ServiceProvider registers an unrelated service AFTER ours.
                di.map("loggerService").to("wheels.tests._assets.di.SimpleService").asSingleton();

                // Now the user's authenticator should still be a singleton.
                expect(di.isSingleton("authenticator")).toBeTrue();
                expect(di.isSingleton("loggerService")).toBeTrue();

                var first = di.getInstance("authenticator");
                var second = di.getInstance("authenticator");
                expect(first).toBe(second);
            });

        });

    }

}
```

- [ ] **Step 2: Run the spec — at least one of the two cases must fail**

```bash
bash tools/test-local.sh di
```

Expected: at least one of the two `it` blocks fails. The first case is the broad reproduction; the second is the focused H1 test.

If **both pass**, hypotheses H1/H3 are wrong — proceed to H2 instrumentation in Task 2.5.

If **the second case fails**, H1 is confirmed — proceed to Task 3 (H1 fix) directly.

If **the first case fails but the second passes**, the issue is more subtle than H1 — proceed to Task 2.5 (full-app reproduction).

- [ ] **Step 3: Commit the failing test**

```bash
git add vendor/wheels/tests/specs/di/InjectorLifecycleSpec.cfc
git commit -m "test(di): add lifecycle-survival specs (failing) for singleton + auth bug"
```

We commit the failing test deliberately. Phase 5 promotes it to a passing regression test once the fix lands. Until then, it's a tracked regression marker.

---

## Task 2 (Hypothesis 1 path): Confirm `$findLastMappingKey()` is the bug

This task fires only if Task 1 Step 2 confirmed H1.

**Files:**
- Read: `vendor/wheels/Injector.cfc:84-90, 268-277`

- [ ] **Step 1: Inspect Lucee struct-iteration order for `variables.mappings`**

Add temporary diagnostic logging to `$findLastMappingKey()`:

```cfm
private string function $findLastMappingKey() {
    local.lastKey = "";
    local.allKeys = [];
    for (local.key in variables.mappings) {
        local.lastKey = local.key;
        ArrayAppend(local.allKeys, local.key);
    }
    WriteLog(file="wheels", type="information",
        text="$findLastMappingKey -> #local.lastKey# (iteration order: #ArrayToList(local.allKeys)#)");
    return local.lastKey;
}
```

Re-run Task 1 Step 2 and inspect `~/.wheels/servers/<name>/wheels.log` (or wherever Wheels writes its log). Capture three things:
1. The reported "last key" each time `$findLastMappingKey` runs.
2. The full iteration order each time.
3. Whether the iteration order matches insertion order or differs across calls.

- [ ] **Step 2: Confirm the diagnosis**

If iteration order varies — or doesn't match insertion order — H1 is fully confirmed: `$findLastMappingKey` is unreliable, and `asSingleton()` is flagging the wrong mapping intermittently.

- [ ] **Step 3: Remove the diagnostic logging**

```bash
git checkout vendor/wheels/Injector.cfc
```

(Or revert just the WriteLog/ArrayAppend additions manually.)

- [ ] **Step 4: No commit yet — diagnosis only**

Move on to Task 3.

---

## Task 2.5 (Hypothesis 2/3 path): Full-app reproduction

This task fires if Task 1's specs both passed (H1 ruled out at the unit level).

**Files:**
- Read: `public/Application.cfc:108-171`, `vendor/wheels/events/onapplicationstart.cfc:295-302, 360-367`

- [ ] **Step 1: Scaffold a fresh app + tutorial 6b setup**

```bash
TMP=$(mktemp -d) && cd "$TMP"
WHEELS_FRAMEWORK_PATH=/Users/peter/GitHub/wheels-dev/wheels/vendor/wheels wheels new di-bug-repro --no-open-browser
cd di-bug-repro

# config/services.cfm
cat > config/services.cfm <<'CFM'
<cfscript>
var di = injector();
di.map("authenticator").to("wheels.auth.Authenticator").asSingleton();
di.map("sessionStrategy").to("wheels.auth.SessionStrategy").asSingleton();
</cfscript>
CFM

# app/events/onapplicationstart.cfm — register strategy + log the instance hash
cat > app/events/onapplicationstart.cfm <<'CFM'
<cfscript>
var auth = application.wo.service("authenticator");
var sessionStrategy = application.wo.service("sessionStrategy");
if (!auth.hasStrategy("session")) {
    auth.registerStrategy(name="session", strategy=sessionStrategy);
}
WriteLog(file="wheels", type="information",
    text="onApplicationStart authenticator hash=#GetHashCode(auth)# strategies=#SerializeJSON(auth.getStrategyNames())#");
</cfscript>
CFM

# app/events/onrequeststart.cfm — log the instance hash
cat > app/events/onrequeststart.cfm <<'CFM'
<cfscript>
if (StructKeyExists(application, "wo")) {
    var auth = application.wo.service("authenticator");
    WriteLog(file="wheels", type="information",
        text="onRequestStart authenticator hash=#GetHashCode(auth)# strategies=#SerializeJSON(auth.getStrategyNames())#");
}
</cfscript>
CFM

wheels start --port=8765
sleep 5
curl -s http://localhost:8765/ > /dev/null
curl -s http://localhost:8765/ > /dev/null
sleep 1
wheels stop
echo "---LOG---"
cat ~/.wheels/servers/di-bug-repro/wheels.log | grep "authenticator hash"
```

`GetHashCode()` is Lucee-specific (returns Java's `.hashCode()`). On Adobe CF, substitute `getMetaData(auth).hashCode()`.

- [ ] **Step 2: Interpret the log output**

Three possible patterns:

- **Same hash, same strategies on every line:** Bug NOT reproduced. The original fresh-VM finding may have had additional context (specific plugin, specific package) we haven't captured. Pause and consult the user before proceeding.
- **Different hashes:** Singleton broken. Compare which lines have which hashes — does it change between `onApplicationStart` and `onRequestStart`? Or only after the second request? That tells us whether `application.wheelsdi` is being recreated between requests (H2) or per-request (something else).
- **Same hash but empty strategies on later lines:** Singleton works at the instance level, but something is calling `clear` or replacing `variables.strategies` on the Authenticator. Search for `variables.strategies =` in `vendor/wheels/auth/`.

- [ ] **Step 3: Clean up the temp app**

```bash
cd /Users/peter/GitHub/wheels-dev/wheels/.claude/worktrees/romantic-kapitsa-e40cc1
rm -rf "$TMP"
```

- [ ] **Step 4: Decide the fix path**

Use the log evidence from Step 2 to pick the right fix task:
- H1 confirmed (different hashes correlated with `$loadPlugins` calls): Task 3.
- H2 confirmed (Application.cfc `onApplicationStart` re-firing): Task 3.5.
- Neither: stop, file new finding, consult user.

---

## Task 3 (H1 fix): Track the current mapping explicitly in `asSingleton()` / `asRequestScoped()`

**Files:**
- Modify: `vendor/wheels/Injector.cfc:71-102`

**Context:** the bug is that `$findLastMappingKey()` walks `variables.mappings` and returns whatever key is encountered last during iteration — which CFML doesn't guarantee is the key just added. The fix replaces it with explicit tracking: `to()` stores the just-completed name, and `asSingleton()` / `asRequestScoped()` use that stored name directly.

- [ ] **Step 1: Write the failing test (extends Task 1's spec)**

Append to `vendor/wheels/tests/specs/di/InjectorLifecycleSpec.cfc`:

```cfm
it("asSingleton flags the just-mapped key, not whichever key iterates last (H1)", () => {
    di.map("first").to("wheels.tests._assets.di.SimpleService");
    di.map("second").to("wheels.tests._assets.di.SimpleService").asSingleton();
    di.map("third").to("wheels.tests._assets.di.SimpleService");

    expect(di.isSingleton("first")).toBeFalse();
    expect(di.isSingleton("second")).toBeTrue();
    expect(di.isSingleton("third")).toBeFalse();
});
```

- [ ] **Step 2: Run the test to confirm it fails**

```bash
bash tools/test-local.sh di
```

Expected: at least one assertion fails on iteration-order-dependent CFML engines.

- [ ] **Step 3: Apply the fix**

In `vendor/wheels/Injector.cfc`, modify the constructor's `variables` initialization (lines 22-35) to add a `lastMappedName` slot:

```cfm
// Track the most recently completed mapping name (for asSingleton / asRequestScoped).
variables.lastMappedName = "";
```

Modify `to()` (line 71-78) to record `lastMappedName`:

```cfm
public Injector function to(required string componentPath) {
    if (!len(variables.currentMapping)) {
        throw(type="Wheels.Injector", message="to() called without a preceding map() call.");
    }
    variables.mappings[variables.currentMapping] = arguments.componentPath;
    variables.lastMappedName = variables.currentMapping;
    variables.currentMapping = "";
    return this;
}
```

Modify `asSingleton()` (line 84-90) to use the tracked name:

```cfm
public Injector function asSingleton() {
    if (len(variables.lastMappedName)) {
        variables.singletonFlags[variables.lastMappedName] = true;
    }
    return this;
}
```

Modify `asRequestScoped()` (line 96-102) the same way:

```cfm
public Injector function asRequestScoped() {
    if (len(variables.lastMappedName)) {
        variables.requestScopedFlags[variables.lastMappedName] = true;
    }
    return this;
}
```

Delete the now-unused `$findLastMappingKey()` private method (lines 268-277). Update the comment at line 28-29 to remove the reference if it mentions "last key found by iteration."

- [ ] **Step 4: Run the test to verify it passes**

```bash
bash tools/test-local.sh di
```

Expected: all `InjectorLifecycleSpec` and `InjectorSpec` cases pass.

- [ ] **Step 5: Run the full test suite to verify no regressions**

```bash
bash tools/test-local.sh
```

Expected: same number of passes as `develop`'s baseline (or one more if a previously-flaky test stabilizes).

- [ ] **Step 6: Commit**

```bash
git add vendor/wheels/Injector.cfc vendor/wheels/tests/specs/di/InjectorLifecycleSpec.cfc
git commit -m "fix(di): track lastMappedName explicitly in asSingleton/asRequestScoped

Previously \$findLastMappingKey() walked variables.mappings and returned
whichever key iterated last — CFML doesn't guarantee struct iteration
order. When ServiceProviders register additional bindings after the
user's mapping (which happens on every dev-mode request via
\$loadPlugins/\$loadPackages), asSingleton() could flag the wrong
mapping, leaving the user's intended singleton without its flag. The
result: service('authenticator') returned a fresh component on every
call, and registered auth strategies were silently lost.

Fix: have to() record the just-completed mapping name in a dedicated
slot, and have asSingleton/asRequestScoped consult that slot directly.

Closes finding #9 in
docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md"
```

---

## Task 3.5 (H2 fix): Guard `Application.cfc::onApplicationStart()` against re-firing

This task fires only if Task 2.5 confirmed H2.

**Files:**
- Modify: `public/Application.cfc:108-117`

- [ ] **Step 1: Write the failing test**

Add to `vendor/wheels/tests/specs/di/InjectorLifecycleSpec.cfc`:

```cfm
it("application.wheelsdi survives a re-call of Application.cfc::onApplicationStart (H2)", () => {
    // Simulate the path Application.cfc takes on the first request after a
    // partial-state event: it sees application.wheels missing eventPath and
    // re-fires onApplicationStart, which builds a new Injector. We want
    // this NOT to wipe an already-good wheelsdi when the application is
    // already initialized.
    var di1 = new wheels.Injector(binderPath="wheels.tests._assets.di.TestBindings");
    di1.map("svc").to("wheels.tests._assets.di.SimpleService").asSingleton();
    var first = di1.getInstance("svc");

    // The fix should make this a no-op for an already-initialized container,
    // OR the fix should be to not call onApplicationStart again. Either way,
    // the singleton-cached instance must survive.
    var di2 = new wheels.Injector(binderPath="wheels.tests._assets.di.TestBindings");
    expect(application.wheelsdi).toBe(di2); // current behavior — overwrites

    // After the fix, the test changes to expect the cached instance survives:
    // expect(di2.getInstance("svc")).toBe(first);
});
```

- [ ] **Step 2: Apply the fix**

In `public/Application.cfc`, modify `onApplicationStart()` (line 108-117):

```cfm
function onApplicationStart() {
    application.env = duplicate(this.env);

    // Guard: only build a new Injector if one isn't already initialized.
    // Re-entrance from onRequestStart's eventPath check used to silently
    // discard the existing container's singleton cache.
    if (!StructKeyExists(application, "wheelsdi")) {
        injector = new wheels.Injector("wheels.Bindings");
    } else {
        injector = application.wheelsdi;
    }

    /* wheels/global object */
    application.wo = injector.getInstance("global");
    initArgs.path="wheels";
    initArgs.filename="onapplicationstart";
    application.wheelsdi.getInstance(name = "wheels.events.onapplicationstart", initArguments = initArgs).$init(this);
}
```

This is the surgical fix. A more aggressive option is to guard the `eventPath` re-entrance in `onRequestStart` itself, but that risks breaking the Wheels reload contract.

- [ ] **Step 3-6: Run, verify, commit (same shape as Task 3 Steps 4-6)**

Commit message:

```
fix(events): preserve application.wheelsdi across onApplicationStart re-entrance

Application.cfc's onRequestStart re-fires onApplicationStart when
application.wheels.eventPath is missing — a partial-state recovery
path. That re-fire created a fresh Injector via 'new wheels.Injector(...)',
which overwrote application.wheelsdi and silently discarded the
existing container's singleton cache. Registered auth strategies (and
any other singleton state) were lost.

Fix: skip the new Injector instantiation when one is already wired up,
reusing application.wheelsdi instead.

Closes finding #9 in
docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md
```

---

## Task 4: Improve `Authenticator.authenticate()` no-strategies error message

**Files:**
- Modify: `vendor/wheels/auth/Authenticator.cfc:55-65`
- Modify: `vendor/wheels/tests/specs/auth/AuthenticatorSpec.cfc` (if it exists; create if not)

**Context:** Today, `Authenticator.authenticate()` returns `"No authentication strategy supports this request"` when zero strategies are registered. That message is indistinguishable from the same message returned when strategies *are* registered but none claim the request. The fresh-VM run lost ~30 minutes to this ambiguity.

- [ ] **Step 1: Find or create the auth spec**

```bash
find vendor/wheels/tests/specs -name "Authenticator*" -type f
```

If no `AuthenticatorSpec.cfc` exists, create it. If it does, append to its `describe("Authenticator", ...)` block.

- [ ] **Step 2: Write the failing test**

```cfm
it("returns a diagnostic error when zero strategies are registered", () => {
    var auth = new wheels.auth.Authenticator();
    var result = auth.authenticate({headers: {}, params: {}});
    expect(result.success).toBeFalse();
    expect(result.error).toContain("No authentication strategies registered");
    expect(result.error).toContain("registerStrategy");
});

it("returns the existing 'no strategy supports' message when strategies are registered but none claim the request", () => {
    var auth = new wheels.auth.Authenticator();
    auth.registerStrategy(name="session", strategy=new wheels.auth.SessionStrategy());

    // Build a request that SessionStrategy.supports() rejects.
    var requestThatNoStrategySupports = {
        headers: {},
        params: {},
        cgi: {request_method: "OPTIONS"},
        $hasNoSession: true
    };
    var result = auth.authenticate(requestThatNoStrategySupports);
    expect(result.success).toBeFalse();
    // The exact message should not be the new diagnostic — it should be the
    // existing "no strategy supports this request" line.
    expect(result.error).toBe("No authentication strategy supports this request");
});
```

The second test pins down the existing behavior so we don't accidentally collapse the two cases into one.

- [ ] **Step 3: Run the spec, confirm test 1 fails and test 2 passes**

```bash
bash tools/test-local.sh
```

(Filter to the auth spec if the script supports it; otherwise run the full suite.)

- [ ] **Step 4: Apply the fix**

In `vendor/wheels/auth/Authenticator.cfc`, modify `authenticate()` (lines 55-93). Add a registration-count check before `$buildStrategyOrder`:

```cfm
public struct function authenticate(required struct request) {
    // Diagnostic check: zero registered strategies is almost always a wiring bug.
    if (ArrayLen(variables.strategies) == 0) {
        return $authResult(
            success = false,
            error = "No authentication strategies registered. Did onApplicationStart run? "
                  & "Verify registerStrategy() is being called on the same Authenticator instance "
                  & "returned by service('authenticator'), and that asSingleton() is set in services.cfm.",
            statusCode = 401
        );
    }

    // Determine which strategies to try and in what order
    local.toTry = $buildStrategyOrder(arguments.request);

    if (ArrayLen(local.toTry) == 0) {
        return $authResult(
            success = false,
            error = "No authentication strategy supports this request",
            statusCode = 401
        );
    }

    // ... existing code unchanged ...
}
```

- [ ] **Step 5: Run the spec, confirm both tests pass**

- [ ] **Step 6: Commit**

```bash
git add vendor/wheels/auth/Authenticator.cfc vendor/wheels/tests/specs/auth/AuthenticatorSpec.cfc
git commit -m "feat(auth): diagnostic error when authenticate() called with no strategies

Previously, calling Authenticator.authenticate() with zero registered
strategies returned the same 'No authentication strategy supports this
request' as when strategies are registered but none claim the request.
A user following Wheels guides chapter 6b who hit the DI singleton bug
saw this generic message and assumed their session had expired.

Distinguish the two cases. Zero-strategies returns a message that
points at the wiring (onApplicationStart, asSingleton, services.cfm).
Strategies-but-none-claim keeps the original message.

Closes the second half of finding #9 in
docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md"
```

---

## Task 5: Promote the lifecycle test to a permanent regression suite

**Files:**
- Already exists: `vendor/wheels/tests/specs/di/InjectorLifecycleSpec.cfc`

- [ ] **Step 1: Verify the spec is now stable**

After Tasks 3 (or 3.5) and 4 land, all the cases in `InjectorLifecycleSpec.cfc` should pass deterministically.

```bash
# Run 5 times in a row to catch any iteration-order flakes
for i in 1 2 3 4 5; do bash tools/test-local.sh di; done
```

Expected: 5 consecutive passes.

- [ ] **Step 2: If H1 was the cause, add a struct-iteration smoke test to InjectorSpec**

Append to `vendor/wheels/tests/specs/di/InjectorSpec.cfc` inside the `Core API` `describe`:

```cfm
it("asSingleton flag survives subsequent unrelated mappings (regression: ##2331-adjacent)", () => {
    // Regression: ServiceProviders calling map().to().asSingleton() on a
    // late-mapped service used to clobber the singleton flag of an earlier
    // user mapping because $findLastMappingKey walked struct keys in
    // engine-dependent iteration order.
    di.map("userAuthenticator").to("wheels.tests._assets.di.SimpleService").asSingleton();
    di.map("pluginLogger").to("wheels.tests._assets.di.SimpleService").asSingleton();
    di.map("pluginCache").to("wheels.tests._assets.di.SimpleService").asSingleton();

    expect(di.isSingleton("userAuthenticator")).toBeTrue();
    expect(di.isSingleton("pluginLogger")).toBeTrue();
    expect(di.isSingleton("pluginCache")).toBeTrue();

    // Cross-check: resolving twice returns the same instance.
    expect(di.getInstance("userAuthenticator")).toBe(di.getInstance("userAuthenticator"));
});
```

- [ ] **Step 3: Run the suite**

```bash
bash tools/test-local.sh di
```

- [ ] **Step 4: Commit**

```bash
git add vendor/wheels/tests/specs/di/InjectorSpec.cfc
git commit -m "test(di): regression smoke for asSingleton-survives-later-mappings

Pins down the contract that broke chapter 6b of Wheels guides: an
earlier mapping's singleton flag must survive subsequent unrelated
.map().to().asSingleton() calls. ServiceProviders register on every
dev-mode request, so this contract has to hold across reloads."
```

---

## Task 6: Update triage doc + open PR

**Files:**
- Modify: `docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md`

- [ ] **Step 1: Mark finding #9 as shipped, with the commit SHAs**

```diff
-### [ ] 9. `wheels.auth.SessionStrategy` cannot be wired up — `asSingleton()` does not return a singleton
+### [x] 9. `wheels.auth.SessionStrategy` cannot be wired up — **shipped in batch D** (commits `<sha-fix>`, `<sha-error-msg>`, `<sha-regression>`)
```

- [ ] **Step 2: Add a "Batch D" row to the Shipped table**

```markdown
### Batch D — Auth + DI blocker (2026-04-XX)

Per [batch D plan](./2026-04-29-fresh-vm-batch-d-di-singleton.md).

| # | Item | Commit | Repo |
|---|------|--------|------|
| 9 (DI fix) | asSingleton tracks lastMappedName explicitly | `<sha>` | wheels |
| 9 (error msg) | Diagnostic error when no strategies registered | `<sha>` | wheels |
| 9 (regression) | InjectorLifecycleSpec + iteration-order smoke | `<sha>` | wheels |
```

- [ ] **Step 3: Update the triage's downstream cross-references**

Both April 19 #6 ("auth convenience helper") and #7 ("services.cfm load behavior") were noted as blocked by finding #9. Update those entries in `docs/superpowers/plans/2026-04-19-framework-gaps-from-guides-phase-1.md` to remove the blocker note (or delete and replace with "unblocked by 2026-04-29 batch D").

- [ ] **Step 4: Commit the doc updates**

```bash
git add docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md \
        docs/superpowers/plans/2026-04-19-framework-gaps-from-guides-phase-1.md
git commit -m "docs(superpowers): mark batch D items shipped + unblock April 19 #6, #7"
```

- [ ] **Step 5: Push the branch and open the PR**

```bash
git push -u origin HEAD
gh pr create --base develop --title "fix(di): asSingleton survives ServiceProvider re-registration" --body "$(cat <<'EOF'
## Summary
- Track the most recently mapped name explicitly in the Injector so `asSingleton()` and `asRequestScoped()` flag the right binding regardless of CFML struct iteration order. Closes the framework bug behind [Wheels guides chapter 6b](https://guides.wheels.dev/v4-0-0-snapshot/start-here/tutorial/06-authentication/) being unfollowable.
- Replace the silent "No authentication strategy supports this request" message with a diagnostic error when zero strategies are registered, pointing the reader at `onApplicationStart` / `asSingleton` / `services.cfm`.
- Add `InjectorLifecycleSpec` plus a regression smoke in `InjectorSpec` that lock down the singleton-survives-later-mappings contract.

Closes finding #9 in `docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md`. Unblocks April 19 #6 (auth convenience helper) and #7 (services.cfm load behavior).

## Test plan
- [ ] `bash tools/test-local.sh di` passes 5/5 consecutive runs
- [ ] `bash tools/test-local.sh` full suite stable
- [ ] Manual: scaffold a fresh app, follow [chapter 6b](https://guides.wheels.dev/v4-0-0-snapshot/start-here/tutorial/06-authentication/) verbatim, confirm session login + logout work end-to-end
- [ ] Manual: confirm the new no-strategies error appears when services.cfm is wired but onApplicationStart fails to register a strategy

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 6: Report the PR URL and the commit SHAs to backfill the triage table**

---

## Out of scope

These deliberately stay out of batch D and remain in the triage:

- **April 19 #6 (auth convenience helper)**: now unblocked by this batch, but the helper itself is a separate piece of work.
- **April 19 #7 (services.cfm load behavior documentation)**: doc work that depends on this batch landing.
- **Tutorial chapter 6b verbatim verification**: should be added to the doc-site verify-docs harness once the fix is merged. Out of scope here; track as a follow-up.
- **Performance audit of `$loadPlugins`/`$loadPackages` running on every dev-mode request**: this batch fixes the correctness bug they expose, not the performance cost of running them. Separate concern.

---

## Open questions

- **Does the bug only occur when plugins or packages are present?** A bare `wheels new` app with no `vendor/wheels-*` packages may not call `$invokeServiceProviderRegister` at all — the fresh-VM repro had no packages installed. If H1 is right, we should still be able to reproduce by adding any plugin or package. If we can't, there's a fourth hypothesis we haven't named.
- **Is the bug present on Adobe CF as well as Lucee 7?** CFML struct iteration order differs across engines. Run Task 1's spec against `adobe2025` via the Docker matrix to confirm.
- **Does the user's specific install have something we're missing?** The triage mentions `~/.wheels/` was non-empty before the fresh-VM run. If the bug only repros with a stale module cache, the fix shape changes.
