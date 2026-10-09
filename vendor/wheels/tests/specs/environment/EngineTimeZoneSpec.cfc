/**
 * The engine runs in the time zone its container names in TZ. The compat matrix's time zone
 * lanes set TZ=America/New_York and the other legs of the same engines set UTC. If the JVM or the
 * engine ignored TZ, those lanes would quietly run in UTC and prove nothing, so this fails them
 * instead. Only strings are read from the JVM (Adobe 2025 refuses member calls on the JDK's
 * internal TimeZone classes), and a container without TZ, or an engine without a JVM, skips.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("the engine's time zone", function() {

			it("is the zone the container's TZ names", function() {
				var zone = $zone();
				if (!Len(zone.tz) || !Len(zone.jvm)) {
					skip("TZ isn't set for this engine, or it has no JVM zone to compare.");
				}
				if ($isUtc(zone.tz)) {
					expect($isUtc(zone.jvm)).toBeTrue("TZ is " & zone.tz & " but the JVM runs in [" & zone.jvm & "]");
					expect(GetTimeZoneInfo().utcTotalOffset).toBe(0, "the engine's offset from UTC");
				} else {
					expect(zone.jvm).toBe(zone.tz, "the JVM's default zone");
					expect(GetTimeZoneInfo().utcTotalOffset).notToBe(0, "the engine's offset from UTC");
				}
			});

			it("applies daylight saving in America/New_York to Now()", function() {
				var zone = $zone();
				if (zone.tz != "America/New_York") {
					skip("Only on the America/New_York lanes.");
				}
				// Now()'s wall time against its instant, both in integer arithmetic (no engine date
				// conversion; BoxLang's GetTimeZoneInfo() leaves daylight saving out of utcTotalOffset).
				var n = Now();
				var utcSeconds = Round(n.getTime() / 1000);
				var wallSeconds = $daysFromCivil(Year(n), Month(n), Day(n)) * 86400 + Hour(n) * 3600 + Minute(n) * 60 + Second(n);
				// US rules: daylight saving from the second Sunday of March at 2:00 EST (07:00 UTC)
				// to the first Sunday of November at 2:00 EDT (06:00 UTC).
				var y = Year(n);
				var dstStart = $daysFromCivil(y, 3, $nthSunday(y, 3, 2)) * 86400 + 7 * 3600;
				var dstEnd = $daysFromCivil(y, 11, $nthSunday(y, 11, 1)) * 86400 + 6 * 3600;
				var expected = utcSeconds >= dstStart && utcSeconds < dstEnd ? -14400 : -18000;
				expect(Abs(wallSeconds - utcSeconds - expected)).toBeLTE(1, "Now() is " & (wallSeconds - utcSeconds) & " seconds from UTC; expected " & expected);
			});

		});
	}

	/**
	 * The container's TZ and the JVM's default zone; "" for whichever the engine can't report
	 * (RustCFML reads environment variables but has no JVM zone).
	 */
	private struct function $zone() {
		var zone = {tz = "", jvm = ""};
		try {
			var system = CreateObject("java", "java.lang.System");
			var tz = system.getenv("TZ");
			var jvm = system.getProperty("user.timezone");
			zone.tz = IsNull(tz) ? "" : Trim(tz);
			zone.jvm = IsNull(jvm) ? "" : Trim(jvm);
		} catch (any e) {
			zone.tz = "";
		}
		return zone;
	}

	/**
	 * Days from 1970-01-01 to a calendar date (proleptic Gregorian), in integer arithmetic.
	 */
	private numeric function $daysFromCivil(required numeric y, required numeric m, required numeric d) {
		var yy = arguments.m <= 2 ? arguments.y - 1 : arguments.y;
		var era = Int(yy / 400);
		var yoe = yy - era * 400;
		var mp = arguments.m > 2 ? arguments.m - 3 : arguments.m + 9;
		var doy = Int((153 * mp + 2) / 5) + arguments.d - 1;
		var doe = yoe * 365 + Int(yoe / 4) - Int(yoe / 100) + doy;
		return era * 146097 + doe - 719468;
	}

	/**
	 * The day of the month of a month's nth Sunday.
	 */
	private numeric function $nthSunday(required numeric y, required numeric m, required numeric nth) {
		// 1970-01-01 was a Thursday: (days + 4) mod 7 is the weekday, 0 = Sunday.
		var firstWeekday = ($daysFromCivil(arguments.y, arguments.m, 1) + 4) % 7;
		return 1 + (7 - firstWeekday) % 7 + (arguments.nth - 1) * 7;
	}

	private boolean function $isUtc(required string zone) {
		return ListFindNoCase("UTC,Etc/UTC,UCT,Etc/UCT,GMT,Etc/GMT,GMT0,Etc/GMT0,Universal,Etc/Universal,Zulu,Etc/Zulu", arguments.zone) > 0;
	}

}
