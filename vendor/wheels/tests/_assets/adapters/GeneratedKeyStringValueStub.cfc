/** A generated-key object exposing stringValue(), like oracle.sql.ROWID (#3708). */
component output=false {

	public any function init(required string text) {
		variables.text = arguments.text;
		return this;
	}

	public string function stringValue() {
		return variables.text;
	}

}
