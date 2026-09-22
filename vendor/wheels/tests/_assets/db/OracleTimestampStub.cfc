/**
 * Stands in for `oracle.sql.TIMESTAMP`, the shape Oracle's JDBC driver hands
 * back for TIMESTAMP columns on Adobe CF (#3649).
 *
 * The real class is a `oracle.sql.Datum`, NOT a `java.util.Date`, so
 * `IsDate()` rejects it — but it exposes `timestampValue()` returning a
 * `java.sql.Timestamp`. This stub reproduces exactly that contract on any
 * JVM engine, so the bridge can be tested without an Oracle container.
 */
component {

	public any function init(required numeric millis) {
		variables.millis = arguments.millis;
		return this;
	}

	public any function timestampValue() {
		return CreateObject("java", "java.sql.Timestamp").init(JavaCast("long", variables.millis));
	}

}
