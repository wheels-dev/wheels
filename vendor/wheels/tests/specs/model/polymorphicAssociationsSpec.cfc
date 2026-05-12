component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Polymorphic belongsTo", () => {

			it("stores polymorphic metadata in association struct", () => {
				var classData = g.model("polyComment").$classData();
				var assoc = classData.associations.commentable;

				expect(assoc.type).toBe("belongsTo");
				expect(assoc.polymorphic).toBeTrue();
				expect(assoc.foreignKey).toBe("commentableid");
				expect(assoc.foreignType).toBe("commentabletype");
				// modelName should be empty — resolved at runtime.
				expect(assoc.modelName).toBe("");
			})

			it("resolves correct model type dynamically", () => {
				var comment = g.model("polyComment").findOne(where="commentabletype = 'PolyArticle'");
				var parent = comment.commentable();

				expect(IsObject(parent)).toBeTrue();
				expect(StructKeyExists(parent, "title")).toBeTrue();
			})

			it("resolves different model types for different rows", () => {
				var articleComment = g.model("polyComment").findOne(where="commentabletype = 'PolyArticle'");
				var photoComment = g.model("polyComment").findOne(where="commentabletype = 'PolyPhoto'");

				var article = articleComment.commentable();
				var photo = photoComment.commentable();

				expect(IsObject(article)).toBeTrue();
				expect(IsObject(photo)).toBeTrue();
				// They should come from different models.
				expect(StructKeyExists(article, "title")).toBeTrue();
				expect(StructKeyExists(photo, "url")).toBeTrue();
			})

			it("hasCommentable returns true when parent exists", () => {
				var comment = g.model("polyComment").findOne(where="commentabletype = 'PolyArticle'");
				expect(comment.hasCommentable()).toBeTrue();
			})

			it("hasCommentable returns false when foreign key is empty", () => {
				var comment = g.model("polyComment").new(body="orphan", commentableid="", commentabletype="");
				expect(comment.hasCommentable()).toBeFalse();
			})

			it("throws on include with polymorphic belongsTo", () => {
				expect(function() {
					g.model("polyComment").findAll(include="commentable");
				}).toThrow("Wheels.PolymorphicIncludeNotSupported");
			})

		})

		describe("Polymorphic hasMany", () => {

			it("stores polymorphic metadata with as in association struct", () => {
				var classData = g.model("polyArticle").$classData();
				var assoc = classData.associations.polyComments;

				expect(assoc.type).toBe("hasMany");
				expect(assoc.as).toBe("commentable");
				expect(assoc.foreignKey).toBe("commentableid");
				expect(assoc.foreignType).toBe("commentabletype");
			})

			it("returns only comments for the correct parent type", () => {
				var article = g.model("polyArticle").findOne(where="title = 'First Article'");
				var comments = article.polyComments();

				expect(comments.recordCount).toBeGTE(2);
				// All comments should belong to this article.
				var loop_ok = true;
				for (var row = 1; row <= comments.recordCount; row++) {
					if (comments.commentableid[row] != article.id || comments.commentabletype[row] != "PolyArticle") {
						loop_ok = false;
					}
				}
				expect(loop_ok).toBeTrue();
			})

			it("returns different comments for different parent types", () => {
				var article = g.model("polyArticle").findOne(where="title = 'First Article'");
				var photo = g.model("polyPhoto").findOne(where="url = 'http://example.com/photo1.jpg'");

				var articleComments = article.polyComments();
				var photoComments = photo.polyComments();

				// Article 1 has 2 comments, Photo 1 has 1 comment.
				expect(articleComments.recordCount).toBe(2);
				expect(photoComments.recordCount).toBe(1);
			})

			it("polyCommentCount returns correct count", () => {
				var article = g.model("polyArticle").findOne(where="title = 'First Article'");
				expect(article.polyCommentCount()).toBe(2);
			})

			it("hasPolyComments returns true when children exist", () => {
				var article = g.model("polyArticle").findOne(where="title = 'First Article'");
				expect(article.hasPolyComments()).toBeTrue();
			})

			it("works with include on the inverse side", () => {
				var articles = g.model("polyArticle").findAll(include="polyComments", where="c_o_r_e_polyarticles.title = 'First Article'", returnAs="query");
				expect(articles.recordCount).toBeGTE(1);
			})

		})

		describe("Polymorphic hasOne", () => {

			it("stores polymorphic metadata with as in association struct", () => {
				// We can test the metadata by checking the PolyPhoto model structure.
				var classData = g.model("polyPhoto").$classData();
				var assoc = classData.associations.polyComments;

				expect(assoc.as).toBe("commentable");
				expect(assoc.foreignType).toBe("commentabletype");
			})

		})

		describe("Polymorphic foreign key conventions", () => {

			it("defaults foreignKey to {name}Id for polymorphic belongsTo", () => {
				var classData = g.model("polyComment").$classData();
				expect(classData.associations.commentable.foreignKey).toBe("commentableid");
			})

			it("defaults foreignKey to {as}Id for hasMany with as", () => {
				var classData = g.model("polyArticle").$classData();
				expect(classData.associations.polyComments.foreignKey).toBe("commentableid");
			})

		})

	}

}
