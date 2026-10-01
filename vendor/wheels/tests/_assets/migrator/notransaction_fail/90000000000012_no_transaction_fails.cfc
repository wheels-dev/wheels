component extends="wheels.migrator.Migration" hint="opts out of the per-step transaction and fails part-way (issue 3772)" {

	this.useTransaction = false;

	function up() {
		announce("started without a transaction");
		Throw(type = "Wheels.Test.NoTransactionStepFailed", message = "deliberate failure after the step started");
	}

	function down() {
	}

}
