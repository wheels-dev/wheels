/**
 * DEPRECATED: Use wheels.WheelsTest instead.
 *
 * `wheels.Testbox` is a pure alias of `wheels.WheelsTest`, retained for
 * backward compatibility with specs written before the 4.0 rename. It adds
 * no behavior. Deprecated since 4.0; removal target: 5.0.
 *
 * `wheels upgrade check` flags `extends="wheels.Testbox"` (and the legacy
 * `wheels.Test`) under "Old test base class" — migrate to wheels.WheelsTest
 * before 5.0.
 */
component extends="wheels.WheelsTest" {
}
