/**
 * Consumer<Dialog> target for Playwright's page.onDialog handler.
 *
 * Lucee 7 tightened `createDynamicProxy` to require a Component (CFC)
 * instance as the first argument — passing a struct with inline closures
 * fails with "Can't cast Complex Object Type Struct to String" as Lucee
 * tries the overload that accepts a CFC path string. This CFC is that
 * proxy target, parameterized with the caller's `state` and `action`
 * structs so the handler logic stays in BrowserClient.
 */
component {

	public any function init(required struct state, required struct action) {
		variables.state = arguments.state;
		variables.action = arguments.action;
		return this;
	}

	/**
	 * Called by Playwright when a dialog surfaces on the page. Matches
	 * java.util.function.Consumer#accept(Object).
	 */
	public void function accept(required any dialog) {
		variables.state.lastMessage = arguments.dialog.message();
		variables.state.handled = true;
		if (variables.action.type == "accept") {
			if (Len(variables.action.text)) {
				arguments.dialog.accept(variables.action.text);
			} else {
				arguments.dialog.accept();
			}
		} else {
			arguments.dialog.dismiss();
		}
	}

}
