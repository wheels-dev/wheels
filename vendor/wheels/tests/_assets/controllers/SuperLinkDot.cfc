component extends="wheels.Controller" {

	// #3933 probe: delegate a view-helper override to the framework original via super.<name>().
	public string function linkTo() {
		return "wrapped:" & super.linkTo(argumentCollection = arguments);
	}

}
