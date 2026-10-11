/**
 * ScopedConversionSchema (core-suite fixture)
 *
 * A wheels.JobSchema whose one-time timestamp conversion touches only one row of wheels_jobs
 * (this.rowId), so JobSchemaSpec can run the real conversion, with its transaction and marker,
 * without moving other specs' rows. Statements for the other job tables are counted but not
 * run. this.failOnStatement > 0 throws Spec.ConversionFailed on that statement.
 */
component extends="wheels.JobSchema" {

	this.rowId = "";
	this.failOnStatement = 0;
	this.statementCount = 0;

	public void function $runConversionStatement(required string sql) {
		this.statementCount++;
		if (this.failOnStatement > 0 && this.statementCount == this.failOnStatement) {
			Throw(type = "Spec.ConversionFailed", message = "injected failure");
		}
		if (FindNoCase("UPDATE wheels_jobs SET", arguments.sql) == 1) {
			queryExecute(
				arguments.sql & " WHERE id = :id",
				{id = {value = this.rowId, cfsqltype = "cf_sql_varchar"}},
				$queryOptions()
			);
		}
	}

}
