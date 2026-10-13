---
title: 'From RocketUnit to WheelsTest, and why your suite is faster again'
slug: from-2x-to-41-rocketunit-to-wheelstest
publishedAt: '2026-10-13T21:00:00.000Z'
updatedAt: '2026-10-03T04:31:29.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - upgrade
  - testing
  - migration
categories:
  - Tutorials
excerpt: >-
  Part 7 of "From 2.x to 4.x: the field guide" converts the example app's User
  model tests from RocketUnit to a WheelsTest BDD spec, with both suites
  running side by side on 4.1.2. It shows the one-time wheels.Test deprecation
  warning (removal planned for 5.0), why the RocketUnit base class must keep
  extending wheels.Test until the last file is converted, running one spec
  with wheels test --filter=UserSpec now that #3759 is fixed, and
  --test-timeout. It ends with honest timings: the example suite is dominated
  by bcrypt, so a model-instantiation micro-benchmark compares 3.0, 4.0.5 and
  4.1.2 instead, with links to the full #3213 performance story.
coverImage: null
announcement:
  discussionUrl: 'https://github.com/wheels-dev/wheels/discussions/4588'
  title: "From 2.x to 4.x, part 7: from RocketUnit to WheelsTest"
  body: |
    New post: **[From RocketUnit to WheelsTest, and why your suite is faster again](https://blog.wheels.dev/posts/from-2x-to-41-rocketunit-to-wheelstest/)** — converting a model's RocketUnit tests to a WheelsTest BDD spec with both suites side by side on 4.1.2, the one-time deprecation warning, and why the suite gets faster. This is the last post in the series.
---

Wheels 4 still runs your RocketUnit tests, but `wheels.Test` is deprecated, and its removal is planned for Wheels 5.0. [Pass 2](https://blog.wheels.dev/blog/from-2x-to-41-pass-2-upgrade-check) converted one file in the example app. This post converts the User model tests, runs that one spec from the CLI, and checks how fast the suite is now.

## What 4.1.2 does with RocketUnit tests

The old base class still loads. The first time a RocketUnit test runs, Wheels writes a deprecation warning to `wheels.log`:

```
[Wheels] Deprecation: wheels.Test (RocketUnit) is deprecated and will be removed in Wheels 5.0. Migrate test components to extend="wheels.WheelsTest" and use the BDD syntax (describe/it/expect). See: https://guides.wheels.dev/v4-0-0/testing/
```

Both kinds of test run side by side in the same app. The legacy runner looks for RocketUnit tests in `tests/RocketUnit/`, where pass 1 moved them, and runs them at `/wheels/tests/app` (add `?format=json` for JSON). WheelsTest specs go in `tests/specs/` and run with `wheels test`. On our branch that's 34 RocketUnit tests and 22 specs, all passing. So you can migrate one file at a time.

One rule while you do: **leave `tests/RocketUnit/Test.cfc` extending `wheels.Test` until its last subclass is converted.** `wheels doctor` and `wheels upgrade check` both suggest changing it to `wheels.WheelsTest`. We tried that with 34 RocketUnit tests still inheriting from it, and the whole RocketUnit run failed:

```
The method $runTest does not exist.
```

The `wheels.Testbox` alias is deprecated too, with the same 5.0 target. New specs extend `wheels.WheelsTest` directly.

## Converting the User tests

`tests/RocketUnit/functions/models/User.cfc` held 12 tests. Here are two of them before (excerpt):

```cfm
component extends="tests.RocketUnit.Test" {

	function setup(){
		super.setup();
		m=model("user").new();
	}

	function test_validation_fails(){
		params= {
			"firstname": "Joe",
			"password": "validPassword123!",
			"passwordConfirmation": "validPassword123!"
		};
		m.setProperties(params);
		v = m.valid();
		err = m.allErrors();
		assert("arrayLen(err) EQ 4");
		assert("v EQ false");
	}

	function test_generateRandomPassword(){
		r=m.generateRandomPassword();
		assert("len(r) EQ 12");
	}
}
```

And after, as `tests/specs/models/UserSpec.cfc` (trimmed: the file groups its 12 specs in nested `describe()` blocks):

```cfm
component extends="wheels.WheelsTest" {

	function run() {
		describe("User", () => {

			beforeEach(() => {
				request.isTestingMode = true;
				request.mockSession = {};
				variables.user = model("user").new();
			});

			afterEach(() => {
				StructDelete(request, "isTestingMode");
				StructDelete(request, "mockSession");
			});

			it("reports four errors when lastname, email and terms are missing", () => {
				user.setProperties({
					"firstname" = "Joe",
					"password" = "validPassword123!",
					"passwordConfirmation" = "validPassword123!"
				});
				expect(user.valid()).toBeFalse();
				expect(user.allErrors()).toHaveLength(4);
			});

			it("generates a 12-character random password", () => {
				expect(user.generateRandomPassword()).toHaveLength(12);
			});
		});
	}
}
```

The mapping follows section 8 of the [3.x to 4.0 guide](https://guides.wheels.dev/v4-1-0/upgrading/3x-to-4x/):

- `extends="tests.RocketUnit.Test"` becomes `extends="wheels.WheelsTest"`, and the tests move into `run()`.
- `setup()` and `teardown()` become `beforeEach()` and `afterEach()` inside `describe()`.
- Each `test_x()` method becomes an `it("...")` block.
- Each `assert("...")` string becomes an `expect()` matcher: `toBeTrue`, `toBeFalse`, `toHaveLength`, `toHaveKey`, `notToBeEmpty`. The [testing guide](https://guides.wheels.dev/v4-1-0/testing/) warns that `toEqual`, `toBeTruthy` and `toBeFalsy` don't exist.

**Watch for setup you inherited.** The app's RocketUnit base class set `request.isTestingMode` and a mock session in its own `setup()`, and the app's auth helpers read them. A WheelsTest spec doesn't inherit any of that, so the `beforeEach()` above sets those keys itself. Check your RocketUnit base class for this kind of setup before you convert.

To check that the spec can fail, we changed `toHaveLength(12)` to `13`:

```
11 passed, 1 failed, 0 error(s) (2.68s)

  FAIL: generates a 12-character random password
    The expected length [13] is different than the actual length [12]
```

## Running one spec

[@bennadel](https://github.com/bennadel) reported in [#3759](https://github.com/wheels-dev/wheels/issues/3759) that `wheels test --filter=FooSpec` and `--directory=tests.specs.x.FooSpec` ran zero specs, printed a green `0 passed` and exited 0. That was on CLI 4.0.6. Since 4.1.0, a run that finds no test bundles exits non-zero. 4.1.2 runs the single spec file. On our branch:

```
$ wheels test --filter=UserSpec
Running app tests (exampleApp_test)...
Scope: tests.specs.models.UserSpec
12 passed (2.68s)
```

A bare name is looked up by file name anywhere under `tests/specs/`. A dotted path such as `--filter=tests.specs.models.UserSpec` works too, and `--filter=models` still runs a folder (22 specs here). A name with no match now fails with no green line:

```
$ wheels test --filter=NoSuchSpec
...
0 passed, but no test bundles ran for this scope (0.00s)
```

If two files share the name, the run stops and asks which one you mean. We added a throwaway `tests/specs/controllers/UserSpec.cfc` to check:

```
'UserSpec' matches 2 spec files: tests.specs.controllers.UserSpec, tests.specs.models.UserSpec. Re-run with the dotted path of the one you mean, e.g. --filter=tests.specs.controllers.UserSpec
```

## Giving a long suite more time

`wheels test` waits 900 seconds for the suite by default. To change that from the terminal, use `--test-timeout=<seconds>` (4.1.1, [#3678](https://github.com/wheels-dev/wheels/issues/3678)) or set `WHEELS_TEST_TIMEOUT`. Don't use `--timeout` for this: on LuCLI runtimes without a fix, the runtime takes that flag itself, and the test command never sees it. With an absurd one-second budget (output trimmed):

```
$ wheels test --test-timeout=1
Test run timed out after 1s waiting for the suite to finish.
The specs may have passed — the CLI stopped waiting, the runner did not stop running.
That run is still executing on the server; a re-run waits for it to finish first.
Give it longer:  wheels test --test-timeout=2
```

## Is the suite faster?

[@chapmandu](https://github.com/chapmandu) reported in [#3213](https://github.com/wheels-dev/wheels/issues/3213) that his RocketUnit suite took 274 s on Wheels 2.5 and 1,599 s on 4.0.3. The root cause was the cost of creating each model object. [2.5x faster, the long way](https://blog.wheels.dev/blog/how-we-made-model-instantiation-2-5x-faster) tells the story, and [Performance Notes for 2.x Upgraders](https://guides.wheels.dev/v4-1-0/upgrading/performance-notes/) lists the fixes:

- 4.0.6 builds the mixin plan once per application ([#3213](https://github.com/wheels-dev/wheels/issues/3213)).
- 4.1.0 makes model instances inherit the model API and creates them with a direct constructor ([#3462](https://github.com/wheels-dev/wheels/pull/3462), [#3464](https://github.com/wheels-dev/wheels/pull/3464)).
- 4.1.1 narrows flash locking ([#3656](https://github.com/wheels-dev/wheels/pull/3656), by [@zspitzer](https://github.com/zspitzer)).

**The example app's suite is too small to show any of this.** Its time is mostly bcrypt. `hashPassword()` deliberately runs bcrypt at cost 12, so the 12 User tests take about 2.7 s on both 3.0 and 4.1.2, while the other 34 RocketUnit tests take about 60 ms in total on 4.1.2. The suite-level numbers mostly reflect password hashing, so we don't publish them as a framework comparison.

So we timed the cost #3213 was about. We added a throwaway RocketUnit test that calls `model("permission").new()` 2,000 times, and runs `findAll(returnAs="objects")` on the 37-row permissions table 200 times. We ran it on 3.0.0+33, 4.0.5 and 4.1.2, all on Lucee 7 with SQLite on the same Mac. For 4.0.5 we used a scratch copy of the app with `vendor/wheels` and the `public/` template swapped. Each figure is the median of five warm runs:

| Wheels | 2,000 × `new()` | 200 × `findAll()` as objects |
|---|---|---|
| 3.0.0+33 | 1,529 ms | 5,792 ms |
| 4.0.5 | 1,107 ms | 4,352 ms |
| 4.1.2 | 414 ms | 1,666 ms |

On this workload, 4.1.2 is about 2.6 times as fast as 4.0.5 and 3.5 to 3.7 times as fast as 3.0. We couldn't time 2.x on this machine: CFWheels 2.2 has no SQLite adapter, and we didn't build a Lucee 5 and MySQL setup for it. So for 2.5 against 4.0.3, the numbers are the ones reported in #3213.

## If you're migrating

1. Upgrade to 4.1.2 or later first, so the test commands behave as described here.
2. Convert one RocketUnit file at a time to a `tests/specs/` spec, and copy any setup the RocketUnit base class did into `beforeEach()`.
3. Run each converted spec on its own with `wheels test --filter=<Spec>`, and break one expectation once to see it fail.
4. Keep `wheels.Test` on the RocketUnit base class until the last subclass is gone.
5. Use `--test-timeout` or `WHEELS_TEST_TIMEOUT` for long suites, not `--timeout`.

**Previous:** [replacing your 2.x plugins](https://blog.wheels.dev/blog/from-2x-to-41-replacing-plugins). **Next in the series:** a clean 4.x install on Adobe CF 2025 and IIS, without CommandBox.

