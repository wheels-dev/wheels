component extends="wheels.migrator.Migration" hint="announce then ORM persist — hardener B1 hole" {

	function up() {
		announce("seeding via ORM");
		model("Tag").create(name = "hardener_b1_announce_then_orm");
	}

	function down() {
		announce("removing via ORM");
		// Instance delete — not removeRecord(), which goes through $execute.
		var tag = model("Tag").findOne(where = "name = 'hardener_b1_announce_then_orm'");
		if (IsObject(tag)) {
			tag.delete();
		}
	}

}
