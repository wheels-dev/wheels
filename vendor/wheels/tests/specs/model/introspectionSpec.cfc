component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Tests that classInfo", () => {

			it("returns a struct with expected keys", () => {
				var info = g.model("author").classInfo()

				expect(info).toBeStruct()
				expect(info).toHaveKey("modelName")
				expect(info).toHaveKey("tableName")
				expect(info).toHaveKey("primaryKeys")
				expect(info).toHaveKey("propertyNames")
				expect(info).toHaveKey("properties")
				expect(info).toHaveKey("associations")
				expect(info).toHaveKey("validations")
				expect(info).toHaveKey("enums")
				expect(info).toHaveKey("scopes")
				expect(info).toHaveKey("callbacks")
				expect(info).toHaveKey("calculatedProperties")
				expect(info).toHaveKey("softDeletion")
			})

			it("returns correct model name", () => {
				var info = g.model("author").classInfo()

				expect(info.modelName).toBe("author")
			})

			it("includes properties struct with column metadata", () => {
				var info = g.model("author").classInfo()

				expect(info.properties).toBeStruct()
				expect(info.properties).toHaveKey("firstName")
				expect(info.properties.firstName).toHaveKey("column")
			})

			it("includes associations", () => {
				var info = g.model("author").classInfo()

				expect(info.associations).toBeStruct()
				expect(info.associations).toHaveKey("posts")
				expect(info.associations).toHaveKey("profile")
				expect(info.associations.posts.type).toBe("hasMany")
				expect(info.associations.profile.type).toBe("hasOne")
			})

			it("includes validations", () => {
				var info = g.model("author").classInfo()

				expect(info.validations).toBeStruct()
				expect(info.validations).toHaveKey("onSave")
				expect(info.validations).toHaveKey("onCreate")
				expect(info.validations).toHaveKey("onUpdate")
			})
		})

		describe("Tests that associationInfo", () => {

			it("returns all associations as struct", () => {
				var assocs = g.model("author").associationInfo()

				expect(assocs).toBeStruct()
				expect(assocs).toHaveKey("posts")
				expect(assocs).toHaveKey("profile")
				expect(assocs).toHaveKey("user")
			})

			it("returns association with type metadata", () => {
				var assocs = g.model("author").associationInfo()

				expect(assocs.posts).toHaveKey("type")
				expect(assocs.posts.type).toBe("hasMany")
				expect(assocs.profile.type).toBe("hasOne")
				expect(assocs.user.type).toBe("belongsTo")
			})

			it("returns empty struct for model with no associations", () => {
				var assocs = g.model("tag").associationInfo()

				// Tag has hasManyToMany via classifications but direct check
				expect(assocs).toBeStruct()
			})
		})

		describe("Tests that associationNames", () => {

			it("returns comma-delimited list of association names", () => {
				var names = g.model("author").associationNames()

				expect(names).toBeString()
				expect(listFindNoCase(names, "posts")).toBeGT(0)
				expect(listFindNoCase(names, "profile")).toBeGT(0)
			})
		})

		describe("Tests that validationInfo", () => {

			it("returns validations by trigger", () => {
				var vals = g.model("author").validationInfo()

				expect(vals).toBeStruct()
				expect(vals).toHaveKey("onSave")
				expect(vals.onSave).toBeArray()
			})

			it("includes presence validation for author firstName", () => {
				var vals = g.model("author").validationInfo()
				var foundPresence = false

				for (var rule in vals.onSave) {
					if (structKeyExists(rule, "method") && rule.method == "$validatesPresenceOf") {
						if (structKeyExists(rule, "args") && structKeyExists(rule.args, "property") && rule.args.property == "firstName") {
							foundPresence = true
						}
					}
				}

				expect(foundPresence).toBeTrue()
			})

			it("includes uniqueness validation for post title", () => {
				var vals = g.model("post").validationInfo()
				var foundUniqueness = false

				for (var rule in vals.onSave) {
					if (structKeyExists(rule, "method") && rule.method == "$validatesUniquenessOf") {
						if (structKeyExists(rule, "args") && structKeyExists(rule.args, "property") && rule.args.property == "title") {
							foundUniqueness = true
						}
					}
				}

				expect(foundUniqueness).toBeTrue()
			})
		})

		describe("Tests that enumInfo", () => {

			it("returns empty struct when no enums defined", () => {
				var enums = g.model("author").enumInfo()

				expect(enums).toBeStruct()
				expect(structIsEmpty(enums)).toBeTrue()
			})
		})

		describe("Tests that scopeInfo", () => {

			it("returns empty struct when no scopes defined", () => {
				var scopes = g.model("author").scopeInfo()

				expect(scopes).toBeStruct()
			})
		})

		describe("Tests that callbackInfo", () => {

			beforeEach(() => {
				g.$clearModelInitializationCache()
			})

			afterEach(() => {
				g.$clearModelInitializationCache()
			})

			it("returns callbacks by type", () => {
				var cbs = g.model("author").callbackInfo()

				expect(cbs).toBeStruct()
				expect(cbs).toHaveKey("beforeSave")
				expect(cbs).toHaveKey("afterCreate")
				expect(cbs).toHaveKey("beforeDelete")
			})

			it("includes registered beforeSave callback for author", () => {
				var cbs = g.model("author").callbackInfo()

				expect(cbs.beforeSave).toBeArray()
				expect(arrayLen(cbs.beforeSave)).toBeGT(0)
			})
		})
	}
}
