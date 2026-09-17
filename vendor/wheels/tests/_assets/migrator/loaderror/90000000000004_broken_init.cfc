component extends="wheels.migrator.Migration" hint="intentional load failure for S5" {

	public any function init() {
		Throw(type = "Wheels.HardenerLoadError", message = "intentional load failure for S5");
	}

	public void function up() {
		announce("must not run after loadError");
	}

	public void function down() {
		announce("must not run after loadError");
	}

}
