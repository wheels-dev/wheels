/**
 * Contract for view form helpers, including HTML5 field types.
 *
 * The default implementation lives in `wheels.view.formsplain`, `formsobject`,
 * `formstag`, and `formshtml5` and is mixed into view context at runtime.
 * Compliance is verified by runtime reflection tests.
 *
 * Includes both object-bound helpers (tied to a model instance) and
 * tag-based helpers (standalone, no model binding).
 *
 * [section: View]
 * [category: Interface]
 */
interface {

	/**
	 * Open an HTML form tag with the appropriate action URL.
	 *
	 * @method HTTP method (default: "post").
	 * @multipart Whether to set enctype for file uploads.
	 * @route Named route for the action URL.
	 * @controller Target controller.
	 * @action Target action.
	 * @key Primary key value for the route.
	 * @params Additional URL parameters.
	 * @anchor URL fragment.
	 * @onlyPath Relative path or full URL.
	 * @host Override host.
	 * @protocol Override protocol.
	 * @port Override port.
	 * @prepend HTML to prepend before the tag.
	 * @append HTML to append after the tag.
	 * @encode Whether to encode attribute values.
	 */
	public string function startFormTag(
		string method,
		boolean multipart,
		string route,
		string controller,
		string action,
		any key,
		any params,
		string anchor,
		boolean onlyPath,
		string host,
		string protocol,
		numeric port,
		string prepend,
		string append,
		boolean encode
	);

	/**
	 * Close an HTML form tag.
	 *
	 * @prepend HTML to prepend.
	 * @append HTML to append.
	 * @encode Encode attribute values.
	 */
	public string function endFormTag(string prepend, string append, boolean encode);

	/**
	 * Render an object-bound text input field.
	 *
	 * @objectName Variable name of the model object.
	 * @property Model property to bind to.
	 * @label Label text.
	 * @labelPlacement Where to place the label: "before", "after", "aroundLeft", "aroundRight".
	 * @prepend HTML before the field.
	 * @append HTML after the field.
	 * @prependToLabel HTML before the label.
	 * @appendToLabel HTML after the label.
	 * @errorElement HTML element for error messages.
	 * @errorClass CSS class for the error element.
	 * @encode Encode attribute values.
	 */
	public string function textField(
		string objectName,
		string property,
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		string errorElement,
		string errorClass,
		boolean encode
	);

	/**
	 * Render a standalone text input field (no model binding).
	 */
	public string function textFieldTag(
		string name,
		string value,
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		boolean encode
	);

	/** Render an object-bound password input. */
	public string function passwordField(string objectName, string property, string label, boolean encode);

	/** Render an object-bound hidden input. */
	public string function hiddenField(string objectName, string property, boolean encode);

	/** Render an object-bound textarea. */
	public string function textArea(string objectName, string property, string label, boolean encode);

	/** Render an object-bound select dropdown. */
	public string function select(string objectName, string property, any options, any includeBlank, string label, boolean encode);

	/** Render an object-bound checkbox. */
	public string function checkBox(string objectName, string property, string checkedValue, string uncheckedValue, string label, boolean encode);

	/** Render an object-bound radio button. */
	public string function radioButton(string objectName, string property, string tagValue, string label, boolean encode);

	/** Render a submit button. */
	public string function submitTag(string value, string image, string prepend, string append, boolean encode);

	/** Render a button element. */
	public string function buttonTag(string content, string type, string value, string image, string prepend, string append, boolean encode);

	/* ── HTML5 Field Helpers ─────────────────────────────────── */

	/** Render an object-bound email input (type="email"). */
	public string function emailField(string objectName, string property, string label, boolean encode);

	/** Render a standalone email input. */
	public string function emailFieldTag(string name, string value, string label, boolean encode);

	/** Render an object-bound URL input (type="url"). */
	public string function urlField(string objectName, string property, string label, boolean encode);

	/** Render a standalone URL input. */
	public string function urlFieldTag(string name, string value, string label, boolean encode);

	/** Render an object-bound number input (type="number"). */
	public string function numberField(string objectName, string property, string label, any min, any max, any step, boolean encode);

	/** Render a standalone number input. */
	public string function numberFieldTag(string name, string value, string label, any min, any max, any step, boolean encode);

	/** Render an object-bound telephone input (type="tel"). */
	public string function telField(string objectName, string property, string label, boolean encode);

	/** Render an object-bound date input (type="date"). */
	public string function dateField(string objectName, string property, string label, boolean encode);

	/** Render an object-bound color picker input (type="color"). */
	public string function colorField(string objectName, string property, string label, boolean encode);

	/** Render an object-bound range slider (type="range"). */
	public string function rangeField(string objectName, string property, string label, any min, any max, boolean encode);

	/** Render an object-bound search input (type="search"). */
	public string function searchField(string objectName, string property, string label, boolean encode);

}
