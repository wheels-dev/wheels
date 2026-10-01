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

	// afterCommit/afterRollback recording helpers (v4.2.0). Fire only when
	// registered by a spec, so default tests are unaffected. Append to a
	// request-scope log so nested / multi-instance / ordering can be asserted,
	// and also stamp the instance so single-instance specs can read it back.
	function recordAfterCommit() {
		if (!StructKeyExists(request, "$acLog")) {
			request.$acLog = [];
		}
		ArrayAppend(request.$acLog, "commit:" & (this.name ?: ""));
		this.afterCommitFired = true;
	}

	function recordAfterRollback() {
		if (!StructKeyExists(request, "$acLog")) {
			request.$acLog = [];
		}
		ArrayAppend(request.$acLog, "rollback:" & (this.name ?: ""));
		this.afterRollbackFired = true;
	}

	function callbackThatThrows() {
		Throw(type = "Wheels.TestAfterCommitBoom", message = "afterCommit callback boom");
	}

	function secondAfterCommit() {
		if (!StructKeyExists(request, "$acLog")) {
			request.$acLog = [];
		}
		ArrayAppend(request.$acLog, "commit2:" & (this.name ?: ""));
	}

	// Transaction-block fixtures (invoked via invokeWithTransaction) for the
	// nested / nested-inner-failure specs. Each returns a boolean, as the
	// transaction wrapper requires.
	function txnCreateTwoTags() {
		model("tag").create(name = "txncb-nest1");
		model("tag").create(name = "txncb-nest2");
		return true;
	}

	function txnCreateValidThenInvalid() {
		model("tag").create(name = "txncb-valid");
		// The invalid create returns false (no persist, never enqueues) but we
		// still report success, so the OUTER transaction commits.
		model("tag").create(name = "");
		return true;
	}

	function txnCreateThenThrow() {
		model("tag").create(name = "txncb-beforethrow");
		Throw(type = "Wheels.TestNestedBoom", message = "nested write then throw");
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
