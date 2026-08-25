component {

	public MidLoopPublishBuffer function init() {
		variables.items = ["a", "b"];
		variables.published = false;
		variables.cleared = false;
		return this;
	}

	public numeric function size() {
		return ArrayLen(variables.items);
	}

	public any function get(required numeric idx) {
		local.value = variables.items[arguments.idx + 1];
		$publishMidLoop();
		return local.value;
	}

	public any function remove(required numeric idx) {
		local.value = variables.items[arguments.idx + 1];
		ArrayDeleteAt(variables.items, arguments.idx + 1);
		$publishMidLoop();
		return local.value;
	}

	public void function clear() {
		variables.cleared = true;
		variables.items = [];
	}

	public boolean function wasCleared() {
		return variables.cleared;
	}

	private void function $publishMidLoop() {
		if (!variables.published) {
			variables.published = true;
			ArrayAppend(variables.items, "c");
		}
	}

}
