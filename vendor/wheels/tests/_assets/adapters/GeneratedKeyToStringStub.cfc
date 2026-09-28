/** A generated-key object exposing only toString(), the java.sql.RowId contract (#3708). */
component output=false {

	public any function init(required string text) {
		variables.text = arguments.text;
		return this;
	}

	public string function toString() {
		return variables.text;
	}

}
