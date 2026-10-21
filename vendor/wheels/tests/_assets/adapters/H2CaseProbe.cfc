/**
 * An H2 model adapter whose identifier fold case is fixed by the spec, so the
 * quoting rule for "upper" / "lower" / "none" is unit-testable without a live
 * H2 datasource. Overrides $identifierCase() only; $quoteIdentifier() is the
 * production rule under test.
 */
component extends="wheels.databaseAdapters.H2.H2Model" output=false {

	this.identifierCase = "upper";

	public string function $identifierCase() {
		return this.identifierCase;
	}

}
