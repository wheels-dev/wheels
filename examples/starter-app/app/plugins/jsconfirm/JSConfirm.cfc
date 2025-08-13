component mixin="controller" {

	public any function init() {
		this.version = "2.0";
		return this;
	}

	/**
	 * Override core linkTo(), call it and then act on the result.
	 */
	public string function linkTo() {
		local.confirm = $jsConfirmArgs(args=arguments);
		local.rv = core.linkTo(argumentCollection=arguments);
		local.rv = $jsConfirmAdd(name="a", rv=local.rv, confirm=local.confirm);
		return local.rv;
	}

	/**
	 * Override core buttonTo(), call it and then act on the result.
	 */
	public string function buttonTo() {
		local.confirm = $jsConfirmArgs(args=arguments);
		local.rv = core.buttonTo(argumentCollection=arguments);
		local.rv = $jsConfirmAdd(name="input", rv=local.rv, confirm=local.confirm);
		return local.rv;
	}

	/**
	 * Delete the "confirm" argument from the arguments struct so it doesn't get passed along to linkTo() / buttonTo().
	 * This works because the arguments struct is passed in by reference.
	 * Also return the "confirm" argument as a blank string, or what was passed in to it originally.
	 */
	public string function $jsConfirmArgs(required struct args) {
		local.rv = "";
		if (StructKeyExists(args, "confirm")) {
			local.rv = args.confirm;
			StructDelete(args, "confirm");
		}
		return local.rv;
	}

	/**
	 * Add the attribute (e.g., "onsubmit", "onclick") to the string, or append to existing attribute value.
	 */
	public string function $jsConfirmAdd(required string name, required string rv, required string confirm) {
		if (Len(arguments.confirm)) {
			local.js = "return confirm('#JSStringFormat(arguments.confirm)#');";
			local.check = " onclick=""";
			
			// For forms we need to make sure we select the input with type="submit"
			// Because we may have other inputs there, such as the hidden "_method" one.
			if (arguments.name == "input") {
				local.startPos = REFind("<" & arguments.name & " [^>]*type=""submit""", arguments.rv);
			} else {
				local.startPos = Find("<" & arguments.name & " ", arguments.rv);				
			}

			local.checkPos = Find(local.check, arguments.rv, local.startPos);
			if (local.checkPos) {
				// An attribute value already exists we set the string to be added to just the JavaScript.
				// Also set the positition to insert at to be where the ending double quote is found.
				local.attribute = local.js;
				local.pos = Find("""", arguments.rv, local.checkPos + Len(local.check));
			} else {
				// No existing attribute exists so we can add the entire attribute and not just the JavaScript part.
				// Set the position to insert at to be before the ending tag.
				local.attribute = local.check & local.js & """";
				local.pos = Find(">", arguments.rv, local.startPos);
			}
			local.rv = Insert(local.attribute, arguments.rv, local.pos - 1);
		} else {
			local.rv = arguments.rv;
		}
		return local.rv;
	}

}