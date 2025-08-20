component extends="wheels.migrator.Migration" hint="create kangaroos table" {
	function up() {
		hasError = false;
		transaction {
			try {
				t = createTable(name = "c_o_r_e_dropbears");
				t.string(columnNames = "name", default = "", null = true, limit = 255);
				t.timestamps();
				t.create();
			} catch (any ex) {
				hasError = true;
				catchObject = ex;
			}
			if(hasError) {
				transaction action="rollback";
				throw(detail="#catchObject.detail#", errorCode="1", message="#catchObject.message#", type="Any")
			} else {
				transaction action="commit";
			}
		}
	}
	function down() {
		hasError = false;
		transaction {
			try {
				dropTable('c_o_r_e_dropbears');
			} catch (any ex) {
				hasError = true;
				catchObject = ex;
			}
			if(hasError) {
				transaction action="rollback";
				throw(detail="#catchObject.detail#", errorCode="1", message="#catchObject.message#", type="Any")
			} else {
				transaction action="commit";
			}
		}
	}
}