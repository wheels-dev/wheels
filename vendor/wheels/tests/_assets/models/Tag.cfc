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

	// Records then throws, used as an afterRollback to prove a throwing rollback
	// callback on the exception path does not mask the original exception (#3934 R2).
	function recordRollbackThenThrow() {
		if (!StructKeyExists(request, "$acLog")) {
			request.$acLog = [];
		}
		ArrayAppend(request.$acLog, "rollback-boom:" & (this.name ?: ""));
		Throw(type = "Wheels.TestAfterRollbackBoom", message = "afterRollback callback boom");
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

	// Records the MySQL session isolation level seen inside the transaction (#4059).
	function txnRecordIsolation() {
		request.$isolationSeen = QueryExecute(
			"SELECT @@transaction_isolation AS iso",
			[],
			{datasource = application.wo.get("dataSourceName")}
		).iso;
		return true;
	}

	// Savepoint-unit fixtures (#3958). A unit runs via
	// invokeWithTransaction(transaction="savepoint") inside an outer transaction.
	function txnUnitCreateThenFalse() {
		model("tag").create(name = "sp-unit");
		return false;
	}

	function txnUnitCreateOk() {
		model("tag").create(name = "sp-unit-ok");
		return true;
	}

	function txnUnitCreateThenThrow() {
		model("tag").create(name = "sp-unit-throw");
		Throw(type = "Wheels.TestSavepointBoom", message = "savepoint unit write then throw");
	}

	function txnOuterThenFailingUnit() {
		model("tag").create(name = "sp-outer1");
		invokeWithTransaction(method = "txnUnitCreateThenFalse", transaction = "savepoint");
		model("tag").create(name = "sp-outer2");
		return true;
	}

	// The unit is the first database work in the outer transaction (the Lucee case).
	function txnFailingUnitFirst() {
		invokeWithTransaction(method = "txnUnitCreateThenFalse", transaction = "savepoint");
		model("tag").create(name = "sp-after");
		return true;
	}

	function txnOuterCatchesThrowingUnit() {
		model("tag").create(name = "sp-outer1");
		try {
			invokeWithTransaction(method = "txnUnitCreateThenThrow", transaction = "savepoint");
		} catch (Wheels.TestSavepointBoom e) {
			request.$spCaught = true;
		}
		return true;
	}

	function txnSiblingUnits() {
		invokeWithTransaction(method = "txnUnitCreateThenFalse", transaction = "savepoint");
		invokeWithTransaction(method = "txnUnitCreateOk", transaction = "savepoint");
		return true;
	}

	function txnUnitWithFailingInnerUnit() {
		model("tag").create(name = "sp-level1");
		invokeWithTransaction(method = "txnUnitCreateThenFalse", transaction = "savepoint");
		return true;
	}

	function txnNestedUnits() {
		invokeWithTransaction(method = "txnUnitWithFailingInnerUnit", transaction = "savepoint");
		return true;
	}

	// transaction="savepoint" passed straight through a CRUD method.
	function txnOuterWithSavepointCreate() {
		model("tag").create(name = "sp-crud", transaction = "savepoint");
		return true;
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
