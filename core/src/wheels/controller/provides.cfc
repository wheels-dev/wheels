component {
	/**
	 * Defines formats that the controller will respond with upon request.
	 * The format can be requested through a URL variable called `format`, by appending the `format` name to the end of a URL as an extension (when URL rewriting is enabled), or in the request header.
	 *
	 * [section: Controller]
	 * [category: Configuration Functions]
	 *
	 * @formats Formats to instruct the controller to provide. Valid values are `html` (the default), `xml`, `json`, `csv`, `pdf`, and `xls`.
	 */
	public void function provides(string formats = "") {
		$combineArguments(args = arguments, combine = "formats,format", required = true);
		arguments.formats = $listClean(arguments.formats);
		local.possibleFormats = StructKeyList($get("formats"));
		local.formatsArray = ListToArray(arguments.formats);
		local.iEnd = ArrayLen(local.formatsArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = local.formatsArray[local.i];
			if ($get("showErrorInformation") && !ListFindNoCase(local.possibleFormats, local.item)) {
				Throw(
					type = "Wheels.InvalidFormat",
					message = "An invalid format of `#local.item#` has been specified.
					The possible values are #local.possibleFormats#."
				);
			}
		}
		variables.$class.formats.default = ListAppend(variables.$class.formats.default, arguments.formats);
	}

	/**
	 * Use this in an individual controller action to define which formats the action will respond with.
	 * This can be used to define provides behavior in individual actions or to override a global setting set with `provides` in the controller's `config()`.
	 *
	 * [section: Controller]
	 * [category: Provides Functions]
	 *
	 * @formats [see:provides].
	 * @action Name of action, defaults to current.
	 */
	public void function onlyProvides(string formats = "", string action = variables.params.action) {
		$combineArguments(args = arguments, combine = "formats,format", required = true);
		arguments.formats = $listClean(arguments.formats);
		local.possibleFormats = StructKeyList($get("formats"));
		local.formatsArray = ListToArray(arguments.formats);
		local.iEnd = ArrayLen(local.formatsArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = local.formatsArray[local.i];
			if ($get("showErrorInformation") && !ListFindNoCase(local.possibleFormats, local.item)) {
				Throw(
					type = "Wheels.InvalidFormat",
					message = "An invalid format of `#local.item#` has been specified. The possible values are #local.possibleFormats#."
				);
			}
		}
		variables.$class.formats.actions[arguments.action] = arguments.formats;
	}
}
