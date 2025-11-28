component {

	property name="print" inject="PrintBuffer";
	
	/**
	 * Initialize the Detail Output Service
	 */
	function init() {
		variables.actionPadding = 12;
		variables.indentSize = 2;
		return this;
	}

	/**
	 * Output a create action
	 * @path The file path being created
	 * @indent Whether to indent this as a sub-action
	 */
	function create(required string path, boolean indent = false) {
		outputAction("create", arguments.path, "green", arguments.indent);
	}

	/**
	 * Output an update action
	 * @path The file path being updated
	 * @indent Whether to indent this as a sub-action
	 */
	function update(required string path, boolean indent = false) {
		outputAction("update", arguments.path, "yellow", arguments.indent);
	}

	/**
	 * Output a remove action
	 * @path The file path being removed
	 * @indent Whether to indent this as a sub-action
	 */
	function remove(required string path, boolean indent = false) {
		outputAction("remove", arguments.path, "red", arguments.indent);
	}

	/**
	 * Output an invoke action
	 * @generator The generator being invoked
	 * @indent Whether to indent this as a sub-action
	 */
	function invoke(required string generator, boolean indent = false) {
		outputAction("invoke", arguments.generator, "yellow", arguments.indent);
	}

	/**
	 * Output a skip action
	 * @path The file path being skipped
	 * @indent Whether to indent this as a sub-action
	 */
	function skip(required string path, boolean indent = false) {
		outputAction("skip", arguments.path, "cyan", arguments.indent);
	}

	/**
	 * Output a conflict action
	 * @path The file path with conflict
	 * @indent Whether to indent this as a sub-action
	 */
	function conflict(required string path, boolean indent = false) {
		outputAction("conflict", arguments.path, "red", arguments.indent);
	}

	/**
	 * Output an identical action
	 * @path The file path that is identical
	 * @indent Whether to indent this as a sub-action
	 */
	function identical(required string path, boolean indent = false) {
		outputAction("identical", arguments.path, "cyan", arguments.indent);
	}

	/**
	 * Output a route action
	 * @route The route being added
	 * @indent Whether to indent this as a sub-action
	 */
	function route(required string route, boolean indent = false) {
		outputAction("route", arguments.route, "green", arguments.indent);
	}

	/**
	 * Output a migrate action
	 * @migration The migration being run
	 * @indent Whether to indent this as a sub-action
	 */
	function migrate(required string migration, boolean indent = false) {
		outputAction("migrate", arguments.migration, "green", arguments.indent);
	}

	/**
	 * Output a generic action with Rails-style formatting
	 * @action The action being performed
	 * @target The target of the action
	 * @color The color for the action
	 * @indent Whether to indent this as a sub-action
	 */
	function outputAction(
		required string action,
		required string target,
		string color = "green",
		boolean indent = false
	) {
		var padding = arguments.indent ? variables.actionPadding + variables.indentSize : variables.actionPadding;
		var actionText = rJustify(arguments.action, padding);
		
		switch(arguments.color) {
			case "green":
				print.greenText(actionText);
				break;
			case "yellow":
				print.yellowText(actionText);
				break;
			case "red":
				print.redText(actionText);
				break;
			case "cyan":
				print.cyanText(actionText);
				break;
			default:
				print.text(actionText);
		}
		
		print.line("  " & arguments.target).toConsole();
	}

	/**
	 * Output a section header with double lines (realtime)
	 * @title The section title
	 * @width The width of the header (default: 50)
	 */
	function header(required string title, numeric width = 50) {
		print.line(repeatString("=", arguments.width)).toConsole();
		print.boldLine(centerString(arguments.title, arguments.width)).toConsole();
		print.line(repeatString("=", arguments.width)).toConsole();
		print.line().toConsole();
		return this;
	}

	/**
	 * Output a subsection header with single line (realtime)
	 * @title The subsection title
	 * @width The width of the header (default: 50)
	 */
	function subHeader(required string title, numeric width = 50) {
		print.boldLine(arguments.title).toConsole();
		print.line(repeatString("-", arguments.width)).toConsole();
		return this;
	}

	/**
	 * Output a success message
	 * @message The success message
	 */
	function success(required string message) {
		print.line().greenBoldLine(arguments.message).toConsole();
	}

	/**
	 * Output an error message
	 * @message The error message
	 */
	function error(required string message) {
		print.line().redBoldLine(arguments.message).toConsole();
	}


	/**
	 * Output [SUCCESS] status indicator
	 */
	function statusSuccess(required string message) {
		print.greenLine("[SUCCESS]: " & arguments.message).toConsole();
		return this;
	}

	/**
	 * Output [FAILED] status indicator
	 */
	function statusFailed(required string message) {
		print.redLine("[FAILED]: " & arguments.message).toConsole();
		return this;
	}

	/**
	 * Output [WARNING] status indicator
	 */
	function statusWarning(required string message) {
		print.yellowLine("[WARNING]: " & arguments.message).toConsole();
		return this;
	}

	/**
	 * Output [INFO] status indicator
	 */
	function statusInfo(required string message) {
		print.cyanLine("[INFO]: " & arguments.message).toConsole();
		return this;
	}

	/**
	 * Output [FIXED] status indicator
	 */
	function statusFixed(required string message) {
		print.blueLine("[FIXED]: " & arguments.message).toConsole();
		return this;
	}

	/**
	 * Output a next steps section
	 * @steps Array of next step instructions
	 */
	function nextSteps(required array steps) {
		if (arguments.steps.len() == 0) {
			return;
		}
		
		print.line().line().yellowLine("Next steps:");
		
		for (var i = 1; i <= arguments.steps.len(); i++) {
			print.line("   " & i & ". " & arguments.steps[i]);
		}
		
		print.line().toConsole();
	}

	/**
	 * Output a blank line
	 */
	function line() {
		print.line().toConsole();
		return this;
	}

	/**
	 * Get the print buffer for custom operations
	 */
	function getPrint() {
		return variables.print;
	}

	/**
	 * Output a generic message
	 * @message The message to output
	 * @indent Whether to indent this message
	 */
	function output(required string message, boolean indent = false) {
		var indentText = arguments.indent ? repeatString(" ", variables.indentSize) : "";
		print.line(indentText & arguments.message).toConsole();
		return this;
	}

	/**
	 * Output a separator line
	 */
	function separator() {
		print.line().toConsole();
		return this;
	}

	/**
	 * Output a code block
	 * @code The code to display
	 * @language The language for syntax highlighting (optional)
	 */
	function code(required string code, string language = "") {
		print.line().line(arguments.code).line().toConsole();
		return this;
	}

	/**
	 * Output a divider line (realtime)
	 * @char The character to repeat (default: -)
	 * @length The length of the divider (default: 50)
	 */
	function divider(string char = "-", numeric length = 50) {
		print.line(repeatString(arguments.char, arguments.length)).toConsole();
		return this;
	}

	/**
	 * Output a metric line with label and value (realtime)
	 * @label The metric label
	 * @value The metric value
	 * @padding Total padding for alignment (default: 25)
	 */
	function metric(required string label, required any value, numeric padding = 25) {
		var paddedLabel = lJustify(arguments.label & ":", arguments.padding);
		print.line(paddedLabel & " " & arguments.value).toConsole();
		return this;
	}

	/**
	 * Center a string within a given width
	 */
	private function centerString(required string text, required numeric width) {
		var textLen = len(arguments.text);
		if (textLen >= arguments.width) {
			return arguments.text;
		}
		var padding = int((arguments.width - textLen) / 2);
		return repeatString(" ", padding) & arguments.text;
	}

}