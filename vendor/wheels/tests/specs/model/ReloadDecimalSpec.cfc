/**
 * reload() keeps fractional values. It used to JavaCast("int") every numeric
 * value that fit in 32 bits, so a decimal column of 149.25 reloaded as 149,
 * the object then reported the column as changed, and the next save() wrote
 * the truncated value back even if the caller only edited another field.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("reload() and decimal columns", () => {

			it("keeps a fractional decimal value", () => {
				transaction action="begin" {
					var rec = g.model("sqltype").create(
						stringVariableType = "reload-fraction",
						textType = "precision check",
						decimalType = 149.25,
						transaction = "none"
					);
					rec.reload();
					var reloaded = rec.decimalType;
					var changed = rec.hasChanged("decimalType");
					transaction action="rollback";
				}
				expect(reloaded).toBe(149.25);
				expect(changed).toBeFalse("reload() must not leave the decimal column looking changed");
			});

			it("keeps a negative fractional value", () => {
				transaction action="begin" {
					var rec = g.model("sqltype").create(
						stringVariableType = "reload-negative",
						textType = "precision check",
						decimalType = -3.75,
						transaction = "none"
					);
					rec.reload();
					var reloaded = rec.decimalType;
					transaction action="rollback";
				}
				expect(reloaded).toBe(-3.75);
			});

			it("does not write a truncated value back when another field is saved after reload()", () => {
				transaction action="begin" {
					var rec = g.model("sqltype").create(
						stringVariableType = "reload-then-save",
						textType = "precision check",
						decimalType = 149.25,
						transaction = "none"
					);
					rec.reload();
					rec.stringVariableType = "reload-then-save-edited";
					rec.save(transaction = "none");
					var stored = g.model("sqltype").findByKey(rec.key());
					var storedDecimal = stored.decimalType;
					var storedString = stored.stringVariableType;
					transaction action="rollback";
				}
				expect(storedString).toBe("reload-then-save-edited");
				expect(storedDecimal).toBe(149.25);
			});

			it("still normalizes integer columns", () => {
				transaction action="begin" {
					var rec = g.model("sqltype").create(
						stringVariableType = "reload-integer",
						textType = "precision check",
						decimalType = 1.5,
						transaction = "none"
					);
					var originalKey = rec.key();
					rec.reload();
					var reloadedKey = rec.key();
					transaction action="rollback";
				}
				expect(reloadedKey).toBe(originalKey);
				expect(IsNumeric(reloadedKey)).toBeTrue();
			});

		});

	}

}
