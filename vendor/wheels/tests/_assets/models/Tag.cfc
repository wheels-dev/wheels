component extends="Model" {

	function config() {
		table("c_o_r_e_tags");
		belongsTo(name = "parent", modelName = "tag", foreignKey = "parentid", joinType = "outer");
		hasMany(name = "children", modelName = "tag", foreignKey = "parentid");
		hasMany(name = "classifications");
		beforeSave("callbackThatReturnsTrue");
		property(name = "name", label = "Tag name");
		property(name = "virtual", label = "Virtual property");
	}

	function callbackThatIncreasesVariable() {
		if (!StructKeyExists(this, "callbackCount")) {
			this.callbackCount = 0;
		}
		this.callbackCount++;
	}

	function callbackThatReturnsFalse() {
		return false;
	}

	function callbackThatReturnsTrue() {
		return true;
	}

	function callbackThatReturnsNothing() {
	}

	function callbackThatSetsProperty() {
		this.setByCallback = true;
	}

	// Writes a row then returns a NON-boolean value (invalid for invokeWithTransaction).
	// The non-boolean return must roll the write back BEFORE the post-transaction
	// boolean check throws — never commit-then-error (#3944). A defined non-boolean
	// (string) is the real trigger: a void return leaves rv undefined, which the
	// inner catch already rolls back, so it would not exercise this path.
	function txnNonBooleanThatWrites() {
		model("tag").create(name = "zrr-void", transaction = "none");
		return "not-a-boolean";
	}

	function firstCallback() {
		if (!StructKeyExists(this, "orderTest")) {
			this.orderTest = "";
		}
		this.orderTest = ListAppend(this.orderTest, "first");
	}

	function secondCallback() {
		if (!StructKeyExists(this, "orderTest")) {
			this.orderTest = "";
		}
		this.orderTest = ListAppend(this.orderTest, "second");
		return false;
	}

}
