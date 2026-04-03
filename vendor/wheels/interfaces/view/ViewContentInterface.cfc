/**
 * Contract for view content, layout, and partial inclusion helpers.
 *
 * The default implementation lives in `wheels.view.content` and is mixed
 * into view context at runtime. Compliance is verified by runtime reflection tests.
 *
 * [section: View]
 * [category: Interface]
 */
interface {

	/**
	 * Store content for a named section to be yielded in the layout.
	 *
	 * @position Content position: "first", "last", or a numeric index.
	 * @overwrite Whether to replace existing content: "true", "false", or "all".
	 */
	public void function contentFor(any position, any overwrite);

	/**
	 * Return the main layout content (the rendered view body).
	 */
	public string function contentForLayout();

	/**
	 * Return content stored for a named section, or a default value.
	 *
	 * @name Section name.
	 * @defaultValue Fallback if no content was stored.
	 */
	public string function includeContent(string name, string defaultValue);

	/**
	 * Render a partial template, optionally looping over a query or array.
	 *
	 * @partial Path to the partial (e.g., "comments/comment").
	 * @group Column name to group query rows by (renders partial per group).
	 * @cache Minutes to cache the rendered output.
	 * @layout Layout to wrap each partial rendering.
	 * @spacer HTML inserted between each partial rendering.
	 * @dataFunction Function name that provides data to the partial.
	 */
	public string function includePartial(
		string partial,
		string group,
		any cache,
		any layout,
		string spacer,
		any dataFunction
	);

	/**
	 * Render a layout template.
	 *
	 * @name Layout name or path.
	 */
	public string function includeLayout(string name);

	/**
	 * Cycle through a list of values on each call (e.g., alternating row colors).
	 *
	 * @values Comma-delimited list of values to cycle through.
	 * @name Named cycle (allows multiple independent cycles).
	 */
	public string function cycle(string values, string name);

	/**
	 * Reset a named cycle back to the beginning.
	 *
	 * @name The cycle name to reset.
	 */
	public void function resetCycle(string name);

}
