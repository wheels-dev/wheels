/**
 * Hardener SHOULDs M2–M8 (model layer).
 *
 * Directory-scoped so `wheels test --core --ci --filter=model.hardener`
 * discovers this folder (a single-file directory= scope finds 0 bundles).
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("M2 validatesUniquenessOf includeSoftDeletes default", () => {

			it("does not treat a soft-deleted row as a taken value by default", () => {
				transaction action="begin" {
					var orgPost = g.model("post").findOne();
					var newPost = g.model("post").new(orgPost.properties());
					orgPost.delete();
					expect(newPost.valid()).toBeTrue();
					transaction action="rollback";
				}
			});

			it("still treats a soft-deleted row as taken when includeSoftDeletes is true", () => {
				transaction action="begin" {
					var orgPost = g.model("post").findOne();
					var newPost = g.model("post").new(orgPost.properties());
					orgPost.delete();
					newPost.validatesUniquenessOf(properties = "title", includeSoftDeletes = true);
					expect(newPost.valid()).toBeFalse();
					transaction action="rollback";
				}
			});

		});

		describe("M3 QueryBuilder single-arg where is raw SQL", () => {

			it("does not advertise the builder as universally injection-safe", () => {
				var src = FileRead(ExpandPath("/wheels/model/query/QueryBuilder.cfc"));
				expect(FindNoCase("preventing SQL injection", src)).toBe(
					0,
					"Class comment must not claim every where() form prevents SQL injection."
				);
				expect(FindNoCase("raw", src)).toBeGT(0);
			});

			it("interpolates a single-argument where() clause verbatim", () => {
				var modelRef = g.model("author");
				var qb = new wheels.model.query.QueryBuilder(modelReference = modelRef);
				qb.where("lastName = 'x' OR 1=1");
				expect(qb.$buildFinderArgs().where).toBe("lastName = 'x' OR 1=1");
			});

		});

		describe("M4 create() must not pollute the shared class model", () => {

			afterEach(() => {
				var authorClass = g.model("author");
				if (StructKeyExists(authorClass, "firstName") && authorClass.firstName == "ClassLeakXYZ") {
					StructDelete(authorClass, "firstName");
				}
			});

			it("does not write mass-assigned properties onto the class model", () => {
				var authorClass = g.model("author");
				StructDelete(authorClass, "firstName");
				transaction action="begin" {
					authorClass.create(firstName = "ClassLeakXYZ", lastName = "Probe");
					transaction action="rollback";
				}
				var leaked = StructKeyExists(authorClass, "firstName") && authorClass.firstName == "ClassLeakXYZ";
				expect(leaked).toBeFalse();
			});

		});

		describe("M5 hasMany nested keys must not use GetTickCount", () => {

			it("does not stamp an out-of-window numeric key as the child primary key", () => {
				var tick = Val(Right(GetTickCount(), 12));
				var currentWindow = Ceiling(tick / 900000000);
				var candidateA = 2700000000;
				var candidateB = 4500000000;
				var staleKey = (Ceiling(candidateA / 900000000) == currentWindow) ? candidateB : candidateA;
				var nested = {};
				nested[staleKey] = {filename = "m5.jpg", DESCRIPTION1 = "m5"};
				var gallery = g.model("gallery").new(
					title = "M5 Gallery",
					description = "nested key probe",
					userId = 1
				);
				gallery.$setCollectionAssociationProperty(
					property = "photos",
					value = nested,
					association = gallery.$classData().associations.photos
				);
				expect(ArrayLen(gallery.photos)).toBe(1);
				expect(gallery.photos[1].isNew()).toBeTrue();
				if (StructKeyExists(gallery.photos[1], "id") && !IsNull(gallery.photos[1].id) && Len(gallery.photos[1].id)) {
					expect(ToString(gallery.photos[1].id)).notToBe(ToString(staleKey));
				}
			});

			it("treats an explicit new- marker as a new child rather than a primary key", () => {
				var gallery = g.model("gallery").new(
					title = "M5 New Marker",
					description = "nested key probe",
					userId = 1
				);
				gallery.$setCollectionAssociationProperty(
					property = "photos",
					value = {"new-1": {filename = "m5-new.jpg", DESCRIPTION1 = "m5-new"}},
					association = gallery.$classData().associations.photos
				);
				expect(ArrayLen(gallery.photos)).toBe(1);
				expect(gallery.photos[1].isNew()).toBeTrue();
				if (StructKeyExists(gallery.photos[1], "id") && !IsNull(gallery.photos[1].id) && Len(gallery.photos[1].id)) {
					expect(ToString(gallery.photos[1].id)).notToBe("new-1");
				}
			});

		});

		describe("M6 belongsTo include must keep orphan parents", () => {

			it("keeps parent rows that have no associated record", () => {
				transaction action="begin" {
					var post = g.model("post").findOne();
					g.model("post").updateByKey(
						key = post.id,
						authorId = "",
						validate = false,
						transaction = "none"
					);
					var allCount = g.model("post").count();
					var included = g.model("post").findAll(include = "author");
					expect(included.recordcount).toBe(allCount);
					transaction action="rollback";
				}
			});

		});

		describe("M7 hasChanged detects StructDelete of a persisted property", () => {

			it("returns true after StructDelete of a persisted property", () => {
				var author = g.model("author").findOne();
				StructDelete(author, "firstName");
				expect(author.hasChanged("firstName")).toBeTrue();
				expect(author.hasChanged()).toBeTrue();
			});

			it("still returns false for a property that was never present", () => {
				var author = g.model("author").findOne();
				expect(author.hasChanged("somethingThatDoesNotExist")).toBeFalse();
			});

		});

		describe("M8 mass assignment default and strict option", () => {

			afterEach(() => {
				application.wheels.massAssignmentStrict = false;
			});

			it("is open by default when neither accessible nor protected is configured", () => {
				var author = g.model("author").new(properties = {firstName = "OpenDefault", lastName = "Probe"});
				expect(author.firstName).toBe("OpenDefault");
				expect(author.lastName).toBe("Probe");
			});

			it("massAssignmentStrict leaves unlisted properties unassigned when neither list is configured", () => {
				application.wheels.massAssignmentStrict = true;
				var author = g.model("author").new(properties = {firstName = "StrictBlocked", lastName = "Probe"});
				var assigned = StructKeyExists(author, "firstName") && author.firstName == "StrictBlocked";
				expect(assigned).toBeFalse();
			});

		});

	}

}
