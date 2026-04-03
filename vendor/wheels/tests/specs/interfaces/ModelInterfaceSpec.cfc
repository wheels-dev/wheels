component extends="wheels.WheelsTest" {

	function run() {

		describe("Model Interface Contracts", () => {

			beforeEach(() => {
				// Get a model instance — all mixin methods are already integrated
				userModel = model("user");
			});

			describe("ModelFinderInterface", () => {

				it("exposes all required finder methods", () => {
					var methods = [
						"findAll", "findOne", "findByKey", "findFirst", "findLastOne",
						"findAllKeys", "findEach", "findInBatches", "count", "exists", "reload",
						"average", "maximum", "minimum", "sum"
					];
					for (var m in methods) {
						expect(structKeyExists(userModel, m)).toBeTrue("Model missing: #m#()");
					}
				});

				it("findAll has correct parameter names", () => {
					var expected = [
						"where", "order", "group", "select", "distinct", "include",
						"maxRows", "page", "perPage", "count", "handle", "cache",
						"reload", "parameterize", "returnAs", "returnIncluded",
						"callbacks", "includeSoftDeletes", "useIndex", "dataSource"
					];
					assertParamsPresent(userModel, "findAll", expected);
				});

				it("findOne has correct parameter names", () => {
					var expected = [
						"where", "order", "select", "include", "handle", "cache",
						"reload", "parameterize", "returnAs", "includeSoftDeletes",
						"useIndex", "dataSource"
					];
					assertParamsPresent(userModel, "findOne", expected);
				});

				it("findByKey has correct parameter names", () => {
					var expected = [
						"key", "select", "include", "handle", "cache", "reload",
						"parameterize", "returnAs", "callbacks", "includeSoftDeletes",
						"dataSource"
					];
					assertParamsPresent(userModel, "findByKey", expected);
				});

				it("count has correct parameter names", () => {
					var expected = [
						"where", "include", "parameterize", "includeSoftDeletes", "group"
					];
					assertParamsPresent(userModel, "count", expected);
				});

				it("average has correct parameter names", () => {
					var expected = [
						"property", "where", "include", "distinct", "parameterize",
						"ifNull", "includeSoftDeletes", "group"
					];
					assertParamsPresent(userModel, "average", expected);
				});

				it("maximum has correct parameter names", () => {
					var expected = [
						"property", "where", "include", "parameterize",
						"ifNull", "includeSoftDeletes", "group"
					];
					assertParamsPresent(userModel, "maximum", expected);
				});

				it("minimum has correct parameter names", () => {
					var expected = [
						"property", "where", "include", "parameterize",
						"ifNull", "includeSoftDeletes", "group"
					];
					assertParamsPresent(userModel, "minimum", expected);
				});

				it("sum has correct parameter names", () => {
					var expected = [
						"property", "where", "include", "distinct", "parameterize",
						"ifNull", "includeSoftDeletes", "group"
					];
					assertParamsPresent(userModel, "sum", expected);
				});

			});

			describe("ModelPersistenceInterface", () => {

				it("exposes all required persistence methods", () => {
					var methods = [
						"new", "create", "save", "update", "updateAll", "updateByKey",
						"updateOne", "updateProperty", "delete", "deleteAll",
						"deleteByKey", "deleteOne"
					];
					for (var m in methods) {
						expect(structKeyExists(userModel, m)).toBeTrue("Model missing: #m#()");
					}
				});

				it("save has correct parameter names", () => {
					var expected = [
						"parameterize", "reload", "validate", "transaction",
						"callbacks"
					];
					assertParamsPresent(userModel, "save", expected);
				});

			});

			describe("ModelValidationInterface", () => {

				it("exposes all required validation methods", () => {
					var methods = [
						"automaticValidations", "validate", "validateOnCreate",
						"validateOnUpdate", "validatesPresenceOf", "validatesUniquenessOf",
						"validatesLengthOf", "validatesFormatOf",
						"validatesNumericalityOf", "validatesInclusionOf",
						"validatesExclusionOf", "validatesConfirmationOf", "valid"
					];
					for (var m in methods) {
						expect(structKeyExists(userModel, m)).toBeTrue("Model missing: #m#()");
					}
				});

			});

			describe("ModelCallbackInterface", () => {

				it("exposes all required callback registration methods", () => {
					var methods = [
						"beforeValidation", "afterValidation",
						"beforeValidationOnCreate", "afterValidationOnCreate",
						"beforeValidationOnUpdate", "afterValidationOnUpdate",
						"beforeCreate", "afterCreate", "beforeUpdate", "afterUpdate",
						"beforeSave", "afterSave", "beforeDelete", "afterDelete",
						"afterNew", "afterFind", "afterInitialization"
					];
					for (var m in methods) {
						expect(structKeyExists(userModel, m)).toBeTrue("Model missing: #m#()");
					}
				});

			});

			describe("ModelAssociationInterface", () => {

				it("exposes hasMany, hasOne, belongsTo", () => {
					var methods = ["hasMany", "hasOne", "belongsTo"];
					for (var m in methods) {
						expect(structKeyExists(userModel, m)).toBeTrue("Model missing: #m#()");
					}
				});

				it("hasMany has correct parameter names", () => {
					var expected = [
						"name", "modelName", "foreignKey", "joinKey",
						"joinType", "dependent", "shortcut", "through"
					];
					assertParamsPresent(userModel, "hasMany", expected);
				});

			});

			describe("ModelPropertyInterface", () => {

				it("exposes all required property methods", () => {
					var methods = [
						"tableName", "setPrimaryKey", "table", "properties",
						"setProperties", "isNew", "isPersisted", "key",
						"columnNames", "primaryKeys", "primaryKey",
						"scope", "enum"
					];
					for (var m in methods) {
						expect(structKeyExists(userModel, m)).toBeTrue("Model missing: #m#()");
					}
				});

				it("scope has correct parameter names", () => {
					var expected = [
						"name", "where", "order", "select", "include", "maxRows", "handler"
					];
					assertParamsPresent(userModel, "scope", expected);
				});

				it("enum has correct parameter names", () => {
					var expected = ["property", "values"];
					assertParamsPresent(userModel, "enum", expected);
				});

			});

			describe("ModelErrorInterface", () => {

				it("exposes all required error methods", () => {
					var methods = [
						"addError", "addErrorToBase", "allErrors", "clearErrors",
						"errorCount", "errorsOn", "errorsOnBase", "hasErrors"
					];
					for (var m in methods) {
						expect(structKeyExists(userModel, m)).toBeTrue("Model missing: #m#()");
					}
				});

				it("addError has correct parameter names", () => {
					var expected = ["property", "message", "name"];
					assertParamsPresent(userModel, "addError", expected);
				});

				it("allErrors has correct parameter names", () => {
					var expected = ["includeAssociations", "seenErrors"];
					assertParamsPresent(userModel, "allErrors", expected);
				});

				it("errorCount has correct parameter names", () => {
					var expected = ["property", "name"];
					assertParamsPresent(userModel, "errorCount", expected);
				});

				it("errorsOn has correct parameter names", () => {
					var expected = ["property", "name"];
					assertParamsPresent(userModel, "errorsOn", expected);
				});

			});

		});

	}

	/**
	 * Helper: assert that a method on the given object has all the expected parameter names.
	 */
	private void function assertParamsPresent(required any obj, required string methodName, required array expectedParams) {
		var fn = arguments.obj[arguments.methodName];
		var meta = getMetaData(fn);
		var actualParams = [];
		if (structKeyExists(meta, "parameters")) {
			for (var p in meta.parameters) {
				arrayAppend(actualParams, p.name);
			}
		}
		for (var expected in arguments.expectedParams) {
			expect(arrayFindNoCase(actualParams, expected) > 0).toBeTrue(
				"#arguments.methodName#() missing parameter: #expected# (has: #arrayToList(actualParams)#)"
			);
		}
	}

}
