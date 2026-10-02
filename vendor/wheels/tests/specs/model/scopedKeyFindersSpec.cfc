/**
 * A primary-key lookup narrows whatever WHERE it is given (a scope chain, a
 * query builder or a direct `where` argument) instead of replacing it, so a
 * key outside that set is not found. Covers findByKey, exists(key=),
 * updateByKey and deleteByKey, with static and handler scopes and composite
 * keys.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Primary-key lookups inside a scope", () => {

			beforeEach(() => {
				variables.insideId = g.model("AuthorScoped").findOne(where = "lastName = 'Djurner'", returnAs = "query").id;
				variables.outsideId = g.model("AuthorScoped").findOne(where = "lastName = 'Petruzzi'", returnAs = "query").id;
			})

			it("findByKey through a static scope does not return a record outside the scope", () => {
				expect(g.model("AuthorScoped").withLastNameDjurner().findByKey(variables.outsideId)).toBeFalse();
			})

			it("findByKey through a static scope still returns a record inside the scope", () => {
				var found = g.model("AuthorScoped").withLastNameDjurner().findByKey(variables.insideId);
				expect(IsObject(found)).toBeTrue();
				expect(found.lastName).toBe("Djurner");
			})

			it("findByKey through a handler scope does not return a record outside the scope", () => {
				expect(g.model("AuthorScoped").byLastName("Djurner").findByKey(variables.outsideId)).toBeFalse();
			})

			it("findByKey with a where argument does not return a record outside it", () => {
				expect(g.model("AuthorScoped").findByKey(key = variables.outsideId, where = "lastName = 'Djurner'")).toBeFalse();
				expect(IsObject(g.model("AuthorScoped").findByKey(key = variables.insideId, where = "lastName = 'Djurner'"))).toBeTrue();
			})

			it("findByKey without a where argument is unchanged", () => {
				expect(IsObject(g.model("AuthorScoped").findByKey(variables.outsideId))).toBeTrue();
			})

			it("exists(key=) through a scope is false for a key outside it and true inside it", () => {
				expect(g.model("AuthorScoped").withLastNameDjurner().exists(key = variables.outsideId)).toBeFalse();
				expect(g.model("AuthorScoped").withLastNameDjurner().exists(key = variables.insideId)).toBeTrue();
			})

			it("exists(key=) through a scope behaves the same when error information is hidden", () => {
				var state = {saved = application.wheels.showErrorInformation, outside = "", inside = ""};
				application.wheels.showErrorInformation = false;
				try {
					state.outside = g.model("AuthorScoped").withLastNameDjurner().exists(key = variables.outsideId);
					state.inside = g.model("AuthorScoped").withLastNameDjurner().exists(key = variables.insideId);
				} finally {
					application.wheels.showErrorInformation = state.saved;
				}
				expect(state.outside).toBeFalse();
				expect(state.inside).toBeTrue();
			})

			it("exists(key=) through the query builder is false for a key outside its where", () => {
				expect(g.model("AuthorScoped").where("lastName", "Djurner").exists(key = variables.outsideId)).toBeFalse();
				expect(g.model("AuthorScoped").where("lastName", "Djurner").exists(key = variables.insideId)).toBeTrue();
			})

			it("exists(key=, where=) narrows the where instead of throwing", () => {
				expect(g.model("AuthorScoped").exists(key = variables.outsideId, where = "lastName = 'Djurner'")).toBeFalse();
				expect(g.model("AuthorScoped").exists(key = variables.insideId, where = "lastName = 'Djurner'")).toBeTrue();
			})

			it("a record loaded through a scope cannot be one outside it, so it cannot be updated", () => {
				var state = {loaded = ""};
				transaction {
					state.loaded = g.model("AuthorScoped").withLastNameDjurner().findByKey(variables.outsideId);
					if (IsObject(state.loaded)) {
						state.loaded.update(firstName = "Changed");
					}
					state.after = g.model("AuthorScoped").findByKey(variables.outsideId).firstName;
					transaction action = "rollback";
				}
				expect(IsObject(state.loaded)).toBeFalse();
				expect(state.after).notToBe("Changed");
			})

			it("updateByKey and deleteByKey with a where argument leave a record outside it alone", () => {
				var state = {};
				transaction {
					state.updated = g.model("AuthorScoped").updateByKey(key = variables.outsideId, where = "lastName = 'Djurner'", properties = {firstName = "Changed"});
					state.deleted = g.model("AuthorScoped").deleteByKey(key = variables.outsideId, where = "lastName = 'Djurner'");
					var row = g.model("AuthorScoped").findByKey(variables.outsideId);
					state.stillThere = IsObject(row);
					state.firstName = state.stillThere ? row.firstName : "";
					transaction action = "rollback";
				}
				expect(state.updated).toBeFalse();
				expect(state.deleted).toBeFalse();
				expect(state.stillThere).toBeTrue();
				expect(state.firstName).notToBe("Changed");
			})

			it("findByKey with a composite key narrows a where argument", () => {
				expect(g.model("CombiKey").findByKey(key = "1,1", where = "userId = 2")).toBeFalse();
				expect(IsObject(g.model("CombiKey").findByKey(key = "1,1", where = "userId = 1"))).toBeTrue();
				expect(g.model("CombiKey").exists(key = "1,1", where = "userId = 2")).toBeFalse();
			})

		})

	}

}
