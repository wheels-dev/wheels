- Web test runner isolation: `/wheels/core/tests` and `/wheels/app/tests` (and
  TestClient / browser requests that send `X-Wheels-Test-Context` or the
  `WHEELS_TEST_CONTEXT` cookie) now bind a separate CFML application name
  (`<this.name>_wheelsTest`) when `Application.cfc` includes
  `vendor/wheels/events/testcontext.cfm` after `config/app.cfm`. The live
  `application.wheels` is no longer swapped for the duration of a run, so
  concurrent normal requests keep production config. The snippet ships in
  `wheels new` and the demo app; existing apps keep the [#3373](https://github.com/wheels-dev/wheels/pull/3373)
  named-lock swap on the live scope until they add the include
  (refs [#3374](https://github.com/wheels-dev/wheels/issues/3374)).
