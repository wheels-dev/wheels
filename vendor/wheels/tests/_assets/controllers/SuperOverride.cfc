component extends="wheels.Controller" {

	/**
	 * Overrides a framework view helper the way the "Overriding Core Methods" guide
	 * describes, then delegates to the framework original via the `super<name>`
	 * convention. Before issue #3325 `superLinkTo` was never registered in
	 * controller/view context, so this threw at render time.
	 */
	public string function linkTo() {
		return "wrapped:" & superLinkTo(argumentCollection = arguments);
	}

}
