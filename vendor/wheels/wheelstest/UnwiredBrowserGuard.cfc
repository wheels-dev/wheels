/**
 * Sentinel installed at `this.browser` before browserDescribe() wires a real
 * BrowserClient. Any DSL method call (visitUrl, click, assertSee, ...) raises
 * Wheels.BrowserTest.NotWired with a message that names the actual cause —
 * the spec is using plain describe() inside a BrowserTest subclass — instead
 * of the original misleading "function [X] does not exist in the String".
 *
 * Carries a flag `this.$isUnwiredBrowserGuard = true` so callers that need to
 * distinguish the guard from a real BrowserClient can use structKeyExists()
 * without invoking onMissingMethod.
 */
component {

    this.$isUnwiredBrowserGuard = true;

    public any function onMissingMethod(
        required string missingMethodName,
        required struct missingMethodArguments
    ) {
        throw(
            type="Wheels.BrowserTest.NotWired",
            message="this.browser is not wired. BrowserTest specs must use browserDescribe() blocks instead of describe() — the framework only populates this.browser inside browserDescribe() callbacks.",
            detail="Attempted to call this.browser." & arguments.missingMethodName & "() outside a browserDescribe() block. Change describe(...) to browserDescribe(...) so the browser context is set up per `it` block, or do not access this.browser from this block."
        );
    }
}
