component extends="Model" {

	function config() {
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
