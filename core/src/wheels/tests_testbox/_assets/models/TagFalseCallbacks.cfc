component extends="Model" {

	function config() {
		table("tags");
		afterSave("callbackThatReturnsFalse");
		afterDelete("callbackThatReturnsFalse");
	}

	function callbackThatReturnsFalse() {
		return false;
	}

}
