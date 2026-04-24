component {

	public FakeRegistry function init(
		array packages = [],
		string throwType = "",
		string throwMessage = ""
	) {
		variables.packages = arguments.packages;
		variables.throwType = arguments.throwType;
		variables.throwMessage = arguments.throwMessage;
		return this;
	}

	public array function listAll() {
		if (Len(variables.throwType)) {
			Throw(type = variables.throwType, message = variables.throwMessage);
		}
		return variables.packages;
	}
}
