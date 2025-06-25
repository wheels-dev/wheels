component extends="testbox.system.BaseSpec" {

	function run() {

		g = application.wo

		describe("Tests that views", () => {

			it("should be able to query views on a column", () => {
				view = g.model("ViewUserPhotoKeyUserId").findAll(where = "username = 'tonyp'")

				expect(view.recordcount).notToBe(0)

				view = g.model("ViewUserPhotoKeyPhotoGalleryId").findAll(where = "username = 'tonyp'")

				expect(view.recordcount).notToBe(0)
			})

			it("should be able to query views on the specified primary key", () => {
				view = g.model("ViewUserPhotoKeyUserId").findOne(order = "userid")
				view = g.model("ViewUserPhotoKeyUserId").findByKey(view.userid)

				expect(view).toBeInstanceOf("ViewUserPhotoKeyUserId")

				view = g.model("ViewUserPhotoKeyPhotoGalleryId").findOne(order = "galleryid")
				view = g.model("ViewUserPhotoKeyPhotoGalleryId").findByKey(view.galleryid)

				expect(view).toBeInstanceOf("ViewUserPhotoKeyPhotoGalleryId")
			})

			it("associations should still work", () => {
				view = g.model("ViewUserPhotoKeyPhotoGalleryId").findAll(include = "photos", where = "username = 'tonyp'")

				expect(view.recordcount).notToBe(0)
			})
		})
	}
}