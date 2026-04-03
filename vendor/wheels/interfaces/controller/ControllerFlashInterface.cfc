/**
 * Contract for controller flash message storage (session-based one-time messages).
 *
 * The default implementation lives in `wheels.controller.flash` and is mixed
 * into Controller instances at runtime. Compliance is verified by runtime reflection tests.
 *
 * Flash messages persist for exactly one request (typically across a redirect).
 *
 * [section: Controller]
 * [category: Interface]
 */
interface {

	/**
	 * Return the flash value for the given key.
	 *
	 * @key The flash key to retrieve.
	 * @return The stored value, or an empty string if not found.
	 */
	public any function flash(string key);

	/**
	 * Insert one or more key/value pairs into the flash.
	 * Pass keys as named arguments: `flashInsert(success="Record saved")`.
	 */
	public void function flashInsert();

	/**
	 * Clear all flash messages.
	 */
	public void function flashClear();

	/**
	 * Return the number of flash messages currently stored.
	 */
	public numeric function flashCount();

	/**
	 * Delete a specific flash key and return its value.
	 *
	 * @key The flash key to delete.
	 * @return The value that was stored under the key.
	 */
	public any function flashDelete(required string key);

	/**
	 * Return true if the flash is empty.
	 */
	public boolean function flashIsEmpty();

	/**
	 * Keep flash messages for one additional request (prevent auto-clear).
	 *
	 * @key Specific key to keep, or blank for all keys.
	 */
	public void function flashKeep(string key);

	/**
	 * Return true if the given key exists in the flash.
	 *
	 * @key The flash key to check.
	 */
	public boolean function flashKeyExists(string key);

}
