/**
 * Regression coverage for #3337.
 *
 * `useUnderscoreReferenceColumns` (framework default `false`, `wheels new` template default
 * `true`) makes the migrator emit `<name>_id` columns, but the association foreign-key
 * default was unconditional `<modelName><key>` concatenation. A stock new app therefore had
 * a migrator and a model layer that could never agree, and any `include=` threw
 * `key [<name>id] doesn't exist` from deep inside the join builder.
 *
 * The default now resolves against the columns that actually exist on whichever side owns
 * the foreign key, so both conventions work — including apps holding a mix of the two.
 * Deliberately schema-driven rather than reading the setting: the migrator reads the flag
 * per call, while this result is memoized for the application lifetime, so honouring the
 * flag here would let a runtime flip change migrations without changing models.
 *
 * Fixtures: `RefParent` / `RefChild` in `tests/_assets/models`, tables in `tests/populate.cfm`.
 */
component extends="wheels.WheelsTest" {

	function run() {
		g = application.wo;

		describe("association foreign key default — underscore convention (##3337)", () => {

			it("resolves the underscore form for belongsTo, where the column is on this model", () => {
				// RefChild.refparent_id — legacy `refparentid` does not exist
				var assoc = g.model("refChild").$expandedAssociations(include = "refParent")[1];

				expect(assoc.foreignKey).toBe("refparent_id");
			});

			it("resolves the underscore form for hasMany, where the column is on the associated model", () => {
				// the same column, reached from the parent side
				var assoc = g.model("refParent").$expandedAssociations(include = "refChildren")[1];

				expect(assoc.foreignKey).toBe("refparent_id");
			});

			it("still derives the legacy form when that is what the schema uses", () => {
				// c_o_r_e_posts.authorid — the framework's own fixtures are all legacy-shaped,
				// so this pins that the underscore support did not shift existing behaviour
				var assoc = g.model("post").$expandedAssociations(include = "author")[1];

				expect(assoc.foreignKey).toBe("authorid");
			});

			it("traverses the association without throwing — the reported symptom", () => {
				// Pre-fix this threw `key [refparentid] doesn't exist`. Empty tables are fine;
				// the point is that building and running the join succeeds.
				var state = {threw = false, message = ""};
				try {
					g.model("refChild").findAll(include = "refParent");
				} catch (any e) {
					state.threw = true;
					state.message = e.message;
				}

				expect(state.threw).toBeFalse();
				expect(state.message).toBe("");
			});

			it("builds both candidate shapes for composite keys", () => {
				var m = g.model("refChild");

				expect(m.$buildForeignKeyList(modelName = "user", keys = "id")).toBe("userid");
				expect(m.$buildForeignKeyList(modelName = "user", keys = "id", separator = "_")).toBe("user_id");
				expect(m.$buildForeignKeyList(modelName = "user", keys = "a,b")).toBe("usera,userb");
				expect(m.$buildForeignKeyList(modelName = "user", keys = "a,b", separator = "_")).toBe("user_a,user_b");
			});

		});

		describe("unresolvable derived foreign key is reported at the association (##3337)", () => {

			it("throws Wheels.AssociationForeignKeyNotFound naming the association and both shapes", () => {
				var m = g.model("refChild");
				var state = {type = "", message = "", extended = ""};
				try {
					m.$assertDerivedForeignKeyResolves(
						associationName = "someAssociation",
						foreignKey = "nosuchmodelid",
						columnOwner = g.model("refChild"),
						modelName = "nosuchmodel",
						keys = "id"
					);
				} catch (any e) {
					state.type = e.type;
					state.message = e.message;
					state.extended = e.extendedInfo;
				}

				expect(state.type).toBe("Wheels.AssociationForeignKeyNotFound");
				expect(state.message).toInclude("someAssociation");
				expect(state.message).toInclude("nosuchmodelid");
				// the extended info has to name the escape hatch, which the old
				// `key [xxx] doesn't exist` message never did
				expect(state.extended).toInclude("foreignKey");
				expect(state.extended).toInclude("nosuchmodel_id");
			});

			it("stays silent when the derived key does resolve", () => {
				var m = g.model("refChild");
				var state = {threw = false};
				try {
					m.$assertDerivedForeignKeyResolves(
						associationName = "refParent",
						foreignKey = "refparent_id",
						columnOwner = g.model("refChild"),
						modelName = "refparent",
						keys = "id"
					);
				} catch (any e) {
					state.threw = true;
				}

				expect(state.threw).toBeFalse();
			});

			it("stays silent when the owner has no properties at all", () => {
				// an un-migrated or missing table must surface the query's own error, not this one
				var m = g.model("refChild");
				var state = {threw = false};
				try {
					m.$assertDerivedForeignKeyResolves(
						associationName = "whatever",
						foreignKey = "anythingid",
						columnOwner = g.model("userTableless"),
						modelName = "anything",
						keys = "id"
					);
				} catch (any e) {
					state.threw = true;
				}

				expect(state.threw).toBeFalse();
			});

		});
	}

}
