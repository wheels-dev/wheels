component extends="Model" {

	function config() {
		table("c_o_r_e_authors");

		scope(name = "withLastNameDjurner", where = "lastname = 'Djurner'");
		scope(name = "orderedByFirstName", order = "firstname ASC");
		scope(name = "firstThree", maxRows = 3);
		scope(name = "byLastName", handler = "scopeByLastName");
		scope(name = "captureLastName", handler = "scopeCaptureLastName");
	}

	private struct function scopeByLastName(required string lastName) {
		return {where: "lastname = '#arguments.lastName#'"};
	}

	private struct function scopeCaptureLastName(required string lastName) {
		request.capturedScopeHandlerArg = arguments.lastName;
		return {where: "lastname = '#arguments.lastName#'"};
	}

}
