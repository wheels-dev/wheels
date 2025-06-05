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
	 * Output a header with emoji
	 * @emoji The emoji to display
	 * @message The header message
	 */
	function header(required string emoji, required string message) {
		print.line().line(arguments.emoji & " " & arguments.message).line().toConsole();
	}

	/**
	 * Output a success message
	 * @message The success message
	 */
	function success(required string message) {
		print.line().greenBoldLine("✅ " & arguments.message).toConsole();
	}

	/**
	 * Output an error message
	 * @message The error message
	 */
	function error(required string message) {
		print.line().redBoldLine("❌ " & arguments.message).toConsole();
	}

	/**
	 * Output a next steps section
	 * @steps Array of next step instructions
	 */
	function nextSteps(required array steps) {
		if (arguments.steps.len() == 0) {
			return;
		}
		
		print.line().line().yellowLine("📋 Next steps:");
		
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

}