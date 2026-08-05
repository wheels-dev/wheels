/**
 * A `cf_sql_timestamp` written to a datetime column must read back in one of the
 * two shapes the framework knows how to interpret (#3302).
 *
 * There is no engine-independent guarantee that it reads back as a date. SQLite
 * has no real DATETIME type, and on Lucee 7 + sqlite-jdbc the value returns as
 * raw epoch milliseconds — a probe here read `1785873308685` back from a
 * `cf_sql_timestamp` write. `RateLimiter.$secondsSince()` already encodes that
 * reality: `IsDate()` first, otherwise treat the value as epoch milliseconds
 * against `GetTickCount()`.
 *
 * So the contract is a disjunction, and this spec asserts exactly it: the value
 * is a CFML date, or it is a number of milliseconds close enough to now to be an
 * epoch timestamp. Anything else lands in `$secondsSince`'s numeric branch as
 * garbage, and every caller that branches on elapsed time silently misbehaves:
 *
 *   - `RateLimiter` token buckets read as permanently empty or permanently full.
 *   - `Migrator`'s `applied_at` renders as nothing in `migrate info` / `doctor`.
 *
 * Both fail on adobe2023 + oracle — three `RateLimiterDatabaseSpec` legs and two
 * `SchemaEnrichmentSpec` legs, all consistent with one shared cause. Asserting
 * that cause directly beats chasing five symptoms, and the failure message
 * prints the value, which none of the five do.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("cf_sql_timestamp round-trip (##3302)", () => {

			it("reads back as a CFML date or as epoch milliseconds", () => {
				var written = DateAdd("n", -37, Now());

				queryExecute(
					"DELETE FROM c_o_r_e_bulkitems WHERE code = :code",
					{code: {value: "TS-ROUNDTRIP", cfsqltype: "cf_sql_varchar"}},
					{datasource: application.wheels.dataSourceName}
				);
				queryExecute(
					"INSERT INTO c_o_r_e_bulkitems (code, name, quantity, createdat)
					VALUES (:code, :name, :quantity, :createdat)",
					{
						code: {value: "TS-ROUNDTRIP", cfsqltype: "cf_sql_varchar"},
						name: {value: "TimestampRoundTrip", cfsqltype: "cf_sql_varchar"},
						quantity: {value: 1, cfsqltype: "cf_sql_integer"},
						createdat: {value: written, cfsqltype: "cf_sql_timestamp"}
					},
					{datasource: application.wheels.dataSourceName}
				);

				var row = queryExecute(
					"SELECT createdat FROM c_o_r_e_bulkitems WHERE code = :code",
					{code: {value: "TS-ROUNDTRIP", cfsqltype: "cf_sql_varchar"}},
					{datasource: application.wheels.dataSourceName}
				);
				expect(row.recordCount).toBe(1);

				var readBack = row.createdat;
				var shape = IsDate(readBack) ? "date" : (IsNumeric(readBack) ? "numeric" : "neither");

				// Report the value, not just the verdict. "Expected [NO] to be true"
				// is what the five downstream failures already say, and it names
				// nothing at all.
				expect(shape).notToBe(
					"neither",
					"A cf_sql_timestamp round-tripped as something $secondsSince() cannot "
					& "read: wrote [" & DateTimeFormat(written, "yyyy-mm-dd HH:nn:ss")
					& "], read back [" & readBack & "]. Every framework path that stores a "
					& "timestamp and later measures elapsed time against it — RateLimiter's "
					& "token bucket, the migrator's applied_at — is unreliable here."
				);

				// Whichever shape it is, it has to still mean the time that was
				// written. Reproduce $secondsSince()'s own computation rather than
				// reconstructing a date from the epoch value: both branches yield
				// "seconds since the stored moment", which is timezone-free, so the
				// comparison holds wherever the suite runs.
				var elapsed = IsDate(readBack)
					? DateDiff("s", readBack, Now())
					: Int((GetTickCount() - readBack) / 1000);
				var expected = DateDiff("s", written, Now());

				expect(Abs(elapsed - expected)).toBeLT(
					120,
					"The stored timestamp came back as a #shape# that does not resolve to "
					& "the time written: wrote [" & DateTimeFormat(written, "yyyy-mm-dd HH:nn:ss")
					& "], read back [" & readBack & "]. $secondsSince() would report "
					& elapsed & "s elapsed where " & expected & "s is correct."
				);

				queryExecute(
					"DELETE FROM c_o_r_e_bulkitems WHERE code = :code",
					{code: {value: "TS-ROUNDTRIP", cfsqltype: "cf_sql_varchar"}},
					{datasource: application.wheels.dataSourceName}
				);
			});

		});

	}

}
