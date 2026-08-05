- Web test runner (`/wheels/core/tests` and `/wheels/app/tests`): the swap→run→restore window that
  temporarily replaces the live `application.wheels` config with test configuration is now serialized
  under an exclusive named lock, and the restore runs in a `finally` block. Overlapping test requests
  can no longer clobber each other's `application.$$$wheels` backup and leave test config live until
  the next `reload=true`, and an erroring suite now restores the original config too. ParallelRunner
  partition sub-requests detect the already-applied swap and skip both the swap and the shared lock,
  so parallel test mode does not deadlock. Note: this serializes test-vs-test only — a normal request
  concurrent with a test run still sees swapped config; true isolation is deferred to a
  separate-application-context design (refs [#3025](https://github.com/wheels-dev/wheels/issues/3025)).
  Also removes the orphaned legacy RocketUnit runner twin `vendor/wheels/rocketunit_tests/Test.cfc`
  (nothing loads it; the active legacy chain via `wheels.Test` is unchanged).
