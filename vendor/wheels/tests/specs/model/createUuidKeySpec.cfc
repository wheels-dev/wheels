component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Tests UUID primary key auto-generation on create", () => {

			it("treats only explicitly sized 36-character columns as uuid columns", () => {
				var m = g.model("post")

				// A missing size no longer matches (it previously made every unsized
				// char/varchar/text column a UUID candidate).
				expect(m.$isUUIDColumn({dataType = "varchar"})).toBeFalse()
				expect(m.$isUUIDColumn({dataType = "text"})).toBeFalse()
				expect(m.$isUUIDColumn({dataType = "char"})).toBeFalse()

				// An explicit 36-character size still matches.
				expect(m.$isUUIDColumn({dataType = "char", size = 36})).toBeTrue()
				expect(m.$isUUIDColumn({dataType = "varchar", size = 36})).toBeTrue()
				expect(m.$isUUIDColumn({dataType = "uniqueidentifier", size = 36})).toBeTrue()

				// Wrong size or type never matches.
				expect(m.$isUUIDColumn({dataType = "varchar", size = 255})).toBeFalse()
				expect(m.$isUUIDColumn({dataType = "int", size = 36})).toBeFalse()
			})

			it("generates a uuid primary key when the property is not set", () => {
				var m = g.model("uuidRecord")
				// Skip on drivers that don't report char(36) as size 36 (e.g. SQLite),
				// where UUID column detection cannot work at all.
				if (!m.$isUUIDColumn(m.columnDataForProperty("uuidid"))) {
					return
				}
				transaction {
					var rec = m.create(name = "generated", transaction = "none")

					expect(Len(rec.uuidid)).toBe(36)
					expect(m.findByKey(key = rec.uuidid, reload = true)).toBeWheelsModel()

					transaction action="rollback";
				}
			})

			it("generates a uuid primary key when the property is an empty string", () => {
				var m = g.model("uuidRecord")
				if (!m.$isUUIDColumn(m.columnDataForProperty("uuidid"))) {
					return
				}
				transaction {
					var rec = m.new(name = "blankpk")
					rec.uuidid = ""
					rec.save(transaction = "none")

					expect(Len(rec.uuidid)).toBe(36)

					transaction action="rollback";
				}
			})

			it("respects an explicitly assigned uuid primary key", () => {
				var m = g.model("uuidRecord")
				if (!m.$isUUIDColumn(m.columnDataForProperty("uuidid"))) {
					return
				}
				transaction {
					var explicitKey = g.generateUUID()
					var rec = m.create(uuidid = explicitKey, name = "explicit", transaction = "none")

					expect(rec.uuidid).toBe(explicitKey)

					transaction action="rollback";
				}
			})

		})
	}
}
