/**
 * Automatic validations against columns the migrator creates, one per column helper (#3898).
 *
 * The core runner turns automatic validations off for the whole suite (tests/runner.cfm), and
 * the shared test schema is built with raw DDL. So until this spec nothing exercised automatic
 * validations against real migrator columns, which is how the SQLite/H2 boolean-as-integer bug
 * (fixed in 4.1.2) reached a release. This spec runs on every engine x database leg.
 *
 * It pins behaviour, not per-adapter type names: a valid value for each column type validates
 * and saves, and a wrong value is rejected on the right property. A type-mapping bug shows up
 * as either "a good value is rejected" (the boolean bug) or "a bad value is accepted".
 *
 * AutoValidatedType turns automatic validations on for itself only.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
		variables.table = "c_o_r_e_autovalidatedtypes";
		variables.adapterName = variables.migration.adapter.adapterName();
		variables.isAdobe = application.wo.$engineAdapter().isAdobe();
		var t = variables.migration.createTable(name = variables.table, force = true);
		t.string(columnNames = "requiredName", limit = 20, allowNull = false);
		// No t.char() column yet: it creates an untyped column on SQLite, H2, MySQL and Oracle (#4092).
		t.text(columnNames = "notes");
		t.integer(columnNames = "quantity");
		t.bigInteger(columnNames = "bigCount");
		t.float(columnNames = "ratio");
		t.decimal(columnNames = "price", precision = 10, scale = 2);
		t.boolean(columnNames = "active");
		t.date(columnNames = "startsOn");
		t.datetime(columnNames = "startsAt");
		t.time(columnNames = "alarmAt");
		t.timestamp(columnNames = "stampedAt");
		t.integer(columnNames = "defaulted", default = 5, allowNull = false);
		t.create();
		StructDelete(application.wheels.models, "AutoValidatedType");
	}

	function afterAll() {
		variables.migration.dropTable(variables.table);
		StructDelete(application.wheels.models, "AutoValidatedType");
	}

	function run() {

		describe("Automatic validations on migrator-created columns", () => {

			afterEach(() => {
				model("AutoValidatedType").deleteAll(instantiate = false, callbacks = false, transaction = "commit");
			});

			it("accepts a valid value for every column type and saves the record", () => {
				var rec = model("AutoValidatedType").new($validProperties());
				expect(rec.valid()).toBeTrue("valid values were rejected: " & SerializeJSON(rec.allErrors()));
				expect(rec.save(transaction = "commit")).toBeTrue("the save failed: " & SerializeJSON(rec.allErrors()));
				expect(model("AutoValidatedType").count()).toBe(1);
			});

			it("accepts every boolean form on a boolean column", () => {
				for (var value in [true, false, "true", "false", 1, 0, "yes", "no"]) {
					var props = $validProperties();
					props.active = value;
					var rec = model("AutoValidatedType").new(props);
					expect(rec.valid()).toBeTrue("boolean value [#ToString(value)#] was rejected: " & SerializeJSON(rec.allErrors()));
				}
			});

			it("leaves a NOT NULL column with a database default optional on create", () => {
				var props = $validProperties();
				StructDelete(props, "defaulted");
				var rec = model("AutoValidatedType").new(props);
				expect(rec.valid()).toBeTrue("the defaulted column was required on create: " & SerializeJSON(rec.allErrors()));
			});

			it("requires a NOT NULL column without a default", () => {
				var props = $validProperties();
				props.requiredName = "";
				$expectRejectedOn(props, "requiredName");
			});

			it("rejects a string longer than its column", () => {
				var props = $validProperties();
				props.requiredName = RepeatString("x", 21);
				$expectRejectedOn(props, "requiredName");
			});

			it("does not cap a text column at a small length", () => {
				var props = $validProperties();
				props.notes = RepeatString("long text ", 500);
				var rec = model("AutoValidatedType").new(props);
				expect(rec.valid()).toBeTrue("a 5000-character text value was rejected: " & SerializeJSON(rec.allErrors()));
			});

			it("rejects a non-number in an integer column", () => {
				var props = $validProperties();
				props.quantity = "abc";
				$expectRejectedOn(props, "quantity");
			});

			it("rejects a fraction in an integer column", () => {
				if (variables.adapterName == "Oracle") {
					skip("Oracle migrator integer columns are a bare NUMBER, which the model treats as a float (##4097).");
				}
				var props = $validProperties();
				props.quantity = "1.5";
				$expectRejectedOn(props, "quantity");
			});

			it("stores a value above the 32-bit range in a bigInteger column", () => {
				if (variables.isAdobe && variables.adapterName == "SQLite") {
					skip("SQLite migrator bigInteger columns are INTEGER, which binds as CF_SQL_INTEGER; Adobe rejects values above 2147483647 (##4089).");
				}
				var props = $validProperties();
				props.bigCount = 9000000000;
				var rec = model("AutoValidatedType").new(props);
				expect(rec.valid()).toBeTrue("a 64-bit value was rejected: " & SerializeJSON(rec.allErrors()));
				expect(rec.save(transaction = "commit")).toBeTrue("the save failed: " & SerializeJSON(rec.allErrors()));
			});

			it("rejects a non-number in a bigInteger column", () => {
				var props = $validProperties();
				props.bigCount = "abc";
				$expectRejectedOn(props, "bigCount");
			});

			it("rejects a non-number in a float column", () => {
				var props = $validProperties();
				props.ratio = "abc";
				$expectRejectedOn(props, "ratio");
			});

			it("rejects a non-number in a decimal column", () => {
				var props = $validProperties();
				props.price = "abc";
				$expectRejectedOn(props, "price");
			});

			it("rejects a non-date in a date column", () => {
				var props = $validProperties();
				props.startsOn = "not a date";
				$expectRejectedOn(props, "startsOn");
			});

			it("rejects a non-date in a datetime column", () => {
				var props = $validProperties();
				props.startsAt = "not a date";
				$expectRejectedOn(props, "startsAt");
			});

		});
	}

	/**
	 * A value every column type accepts.
	 */
	public struct function $validProperties() {
		return {
			requiredName = "widget",
			notes = "some notes",
			quantity = 3,
			bigCount = 123456,
			ratio = 1.5,
			price = "19.99",
			active = true,
			startsOn = CreateDate(2026, 10, 2),
			startsAt = CreateDateTime(2026, 10, 2, 9, 30, 0),
			alarmAt = CreateTime(9, 30, 0),
			stampedAt = CreateDateTime(2026, 10, 2, 9, 30, 0),
			defaulted = 7
		};
	}

	/**
	 * Asserts the record is invalid with an error on the given property.
	 */
	public void function $expectRejectedOn(required struct properties, required string property) {
		var rec = model("AutoValidatedType").new(arguments.properties);
		expect(rec.valid()).toBeFalse("[#arguments.property#] accepted an invalid value");
		expect(ArrayLen(rec.errorsOn(arguments.property))).toBeGT(0, "no error on [#arguments.property#]: " & SerializeJSON(rec.allErrors()));
	}

}
