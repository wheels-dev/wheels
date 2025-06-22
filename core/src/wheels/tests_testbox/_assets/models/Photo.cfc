component extends="Model" {

	function config() {
		property(name = "DESCRIPTION1", column = "description");
		belongsTo(name = "gallery", modelName = "gallery", foreignKey = "id");
		beforeValidation("beforeValidationCallbackThatSetsProperty,beforeValidationCallbackThatIncreasesVariable");
		beforeCreate("beforeCreateCallbackThatIncreasesVariable");
		beforeSave("beforeSaveCallbackThatIncreasesVariable");
		afterCreate("afterCreateCallbackThatIncreasesVariable");
		beforeSave("afterSaveCallbackThatIncreasesVariable");
		validatesPresenceOf("filename");
		/* The evaluated `condition` will throw an exception if callbacks aren't executed properly when this object is a nested property */
		validate(
			method = "validateBeforeValidationRunsProperlyAsNestedAssociation",
			condition = "this.beforeValidationCallbackRegistered"
		);
	}

	private void function afterCreateCallbackThatIncreasesVariable() {
		if (not StructKeyExists(this, "afterCreateCallbackCount")) {
			this.afterCreateCallbackCount = 0;
		}
		this.afterCreateCallbackCount++;
	}

	private void function afterSaveCallbackThatIncreasesVariable() {
		if (not StructKeyExists(this, "afterSaveCallbackCount")) {
			this.afterSaveCallbackCount = 0;
		}
		this.afterSaveCallbackCount++;
	}

	private void function beforeCreateCallbackThatIncreasesVariable() {
		if (not StructKeyExists(this, "beforeCreateCallbackCount")) {
			this.beforeCreateCallbackCount = 0;
		}
		this.beforeCreateCallbackCount++;
	}

	private void function beforeSaveCallbackThatIncreasesVariable() {
		if (not StructKeyExists(this, "beforeSaveCallbackCount")) {
			this.beforeSaveCallbackCount = 0;
		}
		this.beforeSaveCallbackCount++;
	}

	private void function beforeValidationCallbackThatSetsProperty() {
		this.beforeValidationCallbackRegistered = true;
	}

	private void function beforeValidationCallbackThatIncreasesVariable() {
		if (NOT StructKeyExists(this, "beforeValidationCallbackCount")) {
			this.beforeValidationCallbackCount = 0;
		}
		this.beforeValidationCallbackCount++;
	}

	private void function validateBeforeValidationRunsProperlyAsNestedAssociation() {
	}

}
