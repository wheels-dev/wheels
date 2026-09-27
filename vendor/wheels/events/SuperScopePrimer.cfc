/**
 * An empty `wheels.Global` subclass that `onapplicationstart.$init()` creates
 * once, before any `application.wo` call, to work around an Adobe ColdFusion
 * engine bug (2023 and 2025; Lucee and BoxLang are unaffected) (#3730).
 *
 * The bug: an included (mixin) UDF is running on object A and creates a
 * subclass instance B, and B's pseudo-constructor copies that same UDF onto
 * B's `this`. The first time this happens in a JVM, Adobe's UDF epilogue pops
 * a super scope that its prologue never pushed. The result is an
 * EmptyStackException (or NullPointerException) at
 * `NeoPageContext.popSuperScope`. In Wheels, `application.wo` (a plain
 * `wheels.Global`) runs the `global/objects.cfm` mixin `$createObjectFromRoot`
 * to create `wheels.Public`. Global's pseudo-constructor
 * (`$promoteIncludedGlobalsToThis()`) then copies `$createObjectFromRoot`
 * onto the new object. Public is the first Global subclass the JVM creates,
 * so the first request after every cold start failed at that call.
 *
 * Creating any Global subclass outside a mixin call initializes the engine
 * state, and the mismatch never occurs again in that JVM. This component
 * exists only for that. It must declare nothing of its own: its
 * pseudo-constructor is Global's, which is what primes every Global mixin.
 */
component extends="wheels.Global" output="false" {
}
