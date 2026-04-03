/**
 * Contract for application lifecycle event handlers.
 *
 * The default implementation lives in `wheels.events.EventMethods` and defines
 * all its methods directly on the component (no mixin pattern). This is one of
 * only two components that CAN use `implements=` for compile-time enforcement.
 *
 * The `$` prefix on these methods is a Wheels naming convention meaning
 * "framework-internal" — it is NOT a CFML access modifier. These methods ARE
 * the actual event dispatch contract.
 *
 * [section: Events]
 * [category: Interface]
 */
interface {

	/**
	 * Handle an uncaught exception during request processing.
	 *
	 * @exception The CFML exception struct.
	 * @eventName Name of the lifecycle event where the error occurred.
	 * @return The error response content (HTML or other format).
	 */
	public string function $runOnError(required exception, required eventName);

	/**
	 * Run at the start of each request (maps to onRequestStart).
	 *
	 * @targetPage The requested template path.
	 */
	public void function $runOnRequestStart(required targetPage);

	/**
	 * Run at the end of each request (maps to onRequestEnd).
	 *
	 * @targetpage The requested template path.
	 */
	public void function $runOnRequestEnd(required targetpage);

	/**
	 * Run when a new session starts (maps to onSessionStart).
	 */
	public void function $runOnSessionStart();

	/**
	 * Run when a session ends (maps to onSessionEnd).
	 *
	 * @sessionScope The ending session's scope.
	 * @applicationScope The application scope.
	 */
	public void function $runOnSessionEnd(required sessionScope, required applicationScope);

	/**
	 * Run when a requested template is not found (maps to onMissingTemplate).
	 *
	 * @targetpage The missing template path.
	 */
	public void function $runOnMissingTemplate(required targetpage);

	/**
	 * Return the current request format (e.g., "html", "json", "xml").
	 *
	 * @return The format string.
	 */
	public string function $getRequestFormat();

}
