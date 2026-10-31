/**
 * An H2 migrator whose DDL identifier case is fixed by the spec, so the folded-DDL
 * quoting rule for "upper" / "lower" / "none" is unit-testable without a live H2
 * datasource. Overrides $ddlIdentifierCase() only; the quote methods are the
 * production rule under test.
 */
component extends="wheels.databaseAdapters.H2.H2Migrator" output=false {

	this.identifierCase = "upper";

	public string function $ddlIdentifierCase() {
		return this.identifierCase;
	}

}
