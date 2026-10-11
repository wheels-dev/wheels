/**
 * Slot arithmetic for recurring job schedules: parses 5-field cron expressions and finds the
 * next slot after an instant, for cron (in a time zone) and epoch-aligned intervals.
 *
 * Instants are epoch milliseconds. Wall-clock time is handled as "local minutes": minutes since
 * 1970-01-01 00:00 on the schedule's local calendar, with civil-date arithmetic done in integer
 * math (no CFML date objects, so no server-time-zone or DST surprises). UTC needs nothing else;
 * any other IANA time zone converts through java.time with these DST rules: a local time that
 * doesn't exist (spring forward) runs at the next valid instant, and a local time that occurs
 * twice (fall back) runs once, at its first occurrence.
 */
component {

	public function init() {
		return this;
	}

	/**
	 * Parse a cron expression into its match tables. Standard 5 fields — minute hour
	 * day-of-month month day-of-week — with `*`, lists, ranges, steps, month and day names
	 * (day 0 and 7 are Sunday), and the @hourly/@daily/@midnight/@weekly/@monthly/@yearly/
	 * @annually aliases. Seconds and Quartz extensions (L, W, #, ?) are refused.
	 * Throws Wheels.Job.InvalidSchedule.
	 */
	public struct function parse(required string expression) {
		local.text = Trim(arguments.expression);
		local.aliases = {
			"@yearly" = "0 0 1 1 *",
			"@annually" = "0 0 1 1 *",
			"@monthly" = "0 0 1 * *",
			"@weekly" = "0 0 * * 0",
			"@daily" = "0 0 * * *",
			"@midnight" = "0 0 * * *",
			"@hourly" = "0 * * * *"
		};
		if (Left(local.text, 1) == "@") {
			if (!StructKeyExists(local.aliases, LCase(local.text))) {
				$invalid("Unknown cron alias '#local.text#'. Use @hourly, @daily, @midnight, @weekly, @monthly, @yearly or @annually.");
			}
			local.text = local.aliases[LCase(local.text)];
		}
		local.fields = ListToArray(local.text, " " & Chr(9));
		if (ArrayLen(local.fields) != 5) {
			$invalid("A cron expression needs 5 fields (minute hour day-of-month month day-of-week); '#arguments.expression#' has #ArrayLen(local.fields)#.");
		}
		return {
			minutes = $field(local.fields[1], 0, 59, "minute", ""),
			hours = $field(local.fields[2], 0, 23, "hour", ""),
			days = $field(local.fields[3], 1, 31, "day-of-month", ""),
			months = $field(local.fields[4], 1, 12, "month", "JAN,FEB,MAR,APR,MAY,JUN,JUL,AUG,SEP,OCT,NOV,DEC"),
			weekdays = $weekdayField(local.fields[5]),
			// Vixie cron: a day field that starts with "*" (including "*/2") is "starred".
			dayStarred = Left(local.fields[3], 1) == "*",
			weekdayStarred = Left(local.fields[5], 1) == "*"
		};
	}

	/**
	 * The first cron slot strictly after `afterMs`, as epoch ms, or -1 when the expression never
	 * fires within 5 years (e.g. February 31st). Five years covers every real calendar pattern,
	 * including February 29th.
	 */
	public numeric function nextCron(required struct cron, required numeric afterMs, string timeZone = "UTC") {
		local.zone = $zone(arguments.timeZone);
		local.t = $localMinute(arguments.afterMs, local.zone) + 1;
		local.limit = local.t + 5 * 366 * 1440;
		while (local.t <= local.limit) {
			local.f = $civilFromMinute(local.t);
			if (!arguments.cron.months[local.f.month]) {
				local.t = $firstMinuteOfNextMonth(local.f.year, local.f.month);
				continue;
			}
			if (!$dayMatches(arguments.cron, local.f)) {
				local.t = (local.f.days + 1) * 1440;
				continue;
			}
			if (!arguments.cron.hours[local.f.hour + 1]) {
				local.t = (Floor(local.t / 60) + 1) * 60;
				continue;
			}
			if (!arguments.cron.minutes[local.f.minute + 1]) {
				local.t++;
				continue;
			}
			local.instant = $instantOf(local.t, local.zone);
			// A repeated local time (fall back) resolves to its first occurrence, which can lie
			// before `afterMs`: that slot already ran, so keep looking.
			if (local.instant > arguments.afterMs) {
				return local.instant;
			}
			local.t++;
		}
		return -1;
	}

	/**
	 * The first interval slot strictly after `afterMs`: epoch-aligned multiples of the period,
	 * so every host computes the same slots.
	 */
	public numeric function nextInterval(required numeric periodSeconds, required numeric afterMs) {
		local.period = arguments.periodSeconds * 1000;
		return (Floor(arguments.afterMs / local.period) + 1) * local.period;
	}

	/**
	 * Throws Wheels.Job.InvalidSchedule unless `timeZone` can be used here.
	 */
	public void function validateTimeZone(required string timeZone) {
		$zone(arguments.timeZone);
	}

	/**
	 * An instant (epoch ms) as an ISO 8601 UTC timestamp, e.g. 2026-10-12T11:00:00Z.
	 */
	public string function isoUtc(required numeric epochMs) {
		local.totalSeconds = Floor(arguments.epochMs / 1000);
		local.days = Floor(local.totalSeconds / 86400);
		local.rest = local.totalSeconds - local.days * 86400;
		local.d = $civilFromDays(local.days);
		local.h = Floor(local.rest / 3600);
		local.mi = Floor((local.rest - local.h * 3600) / 60);
		local.s = local.rest - local.h * 3600 - local.mi * 60;
		return NumberFormat(local.d.year, "0000") & "-" & NumberFormat(local.d.month, "00") & "-" & NumberFormat(local.d.day, "00")
			& "T" & NumberFormat(local.h, "00") & ":" & NumberFormat(local.mi, "00") & ":" & NumberFormat(local.s, "00") & "Z";
	}

	/**
	 * An ISO 8601 UTC timestamp (YYYY-MM-DDTHH:MM[:SS]Z) as epoch ms. For specs and fixtures.
	 */
	public numeric function msFromIsoUtc(required string iso) {
		local.m = REMatch("^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2}))?Z$", Trim(arguments.iso));
		if (!ArrayLen(local.m)) {
			$invalid("Not an ISO 8601 UTC timestamp: '#arguments.iso#'.");
		}
		local.text = Trim(arguments.iso);
		local.seconds = Len(local.text) == 20 ? Val(Mid(local.text, 18, 2)) : 0;
		local.days = $daysFromCivil(Val(Left(local.text, 4)), Val(Mid(local.text, 6, 2)), Val(Mid(local.text, 9, 2)));
		return ((local.days * 1440 + Val(Mid(local.text, 12, 2)) * 60 + Val(Mid(local.text, 15, 2))) * 60 + local.seconds) * 1000;
	}

	// ---- internals ---------------------------------------------------------------------------

	private array function $field(required string text, required numeric low, required numeric high, required string label, required string names) {
		// One slot per allowed value: minute/hour tables (from 0) are indexed by value + 1,
		// day-of-month/month tables (from 1) by the value itself.
		local.table = [];
		for (local.i = arguments.low; local.i <= arguments.high; local.i++) {
			ArrayAppend(local.table, false);
		}
		local.offset = arguments.low == 0 ? 1 : 0;
		for (local.part in ListToArray(arguments.text, ",")) {
			local.range = $range(local.part, arguments.low, arguments.high, arguments.label, arguments.names);
			for (local.v = local.range.first; local.v <= local.range.last; local.v += local.range.step) {
				local.table[local.v + local.offset] = true;
			}
		}
		return local.table;
	}

	private array function $weekdayField(required string text) {
		// 0-7 with both 0 and 7 meaning Sunday; the table is indexed by 0-6 + 1.
		local.table = [false, false, false, false, false, false, false];
		for (local.part in ListToArray(arguments.text, ",")) {
			local.range = $range(local.part, 0, 7, "day-of-week", "SUN,MON,TUE,WED,THU,FRI,SAT");
			for (local.v = local.range.first; local.v <= local.range.last; local.v += local.range.step) {
				local.table[(local.v MOD 7) + 1] = true;
			}
		}
		return local.table;
	}

	private struct function $range(required string part, required numeric low, required numeric high, required string label, required string names) {
		local.text = UCase(Trim(arguments.part));
		if (!Len(local.text)) {
			$invalid("Empty value in the #arguments.label# field.");
		}
		// One shape only: * or N or NAME, optionally -M, optionally /STEP.
		if (!REFind("^(\*|[A-Z0-9]+(-[A-Z0-9]+)?)(/[0-9]+)?$", local.text)
			&& !Find("##", local.text) && !Find("?", local.text)) {
			$invalid("'#arguments.part#' isn't a valid #arguments.label# value.");
		}
		// Quartz forms: L, 5L, L-3, 15W, LW, 6##3, ?. (Not a bare W/L test: WED contains a W.)
		if (Find("##", local.text) || Find("?", local.text) || REFind("^([0-9]*L|L-?[0-9]*|[0-9]+W|LW)$", ListFirst(local.text, "/"))) {
			$invalid("'#arguments.part#' in the #arguments.label# field uses a Quartz extension (L, W, ## or ?), which isn't supported.");
		}
		local.step = 1;
		local.stepped = Find("/", local.text) > 0;
		if (local.stepped) {
			local.stepText = ListLast(local.text, "/");
			local.text = ListFirst(local.text, "/");
			if (!REFind("^[0-9]+$", local.stepText) || Val(local.stepText) < 1) {
				$invalid("'#arguments.part#' has an invalid step in the #arguments.label# field.");
			}
			local.step = Val(local.stepText);
		}
		if (local.text == "*") {
			return {first = arguments.low, last = arguments.high == 7 ? 6 : arguments.high, step = local.step};
		}
		local.bounds = ListToArray(local.text, "-");
		if (ArrayLen(local.bounds) < 1 || ArrayLen(local.bounds) > 2) {
			$invalid("'#arguments.part#' isn't a valid #arguments.label# value.");
		}
		local.first = $value(local.bounds[1], arguments.low, arguments.high, arguments.label, arguments.names);
		local.last = ArrayLen(local.bounds) == 2 ? $value(local.bounds[2], arguments.low, arguments.high, arguments.label, arguments.names) : local.first;
		if (ArrayLen(local.bounds) == 1 && local.stepped) {
			// Vixie cron / cronie: "N/S" runs from N to the field's maximum, every S, so "5/15" is
			// 5,20,35,50 and "5/1" is 5-59. Day-of-week runs to 7 (Sunday again): "7/2" is Sunday,
			// and "1/2" is Monday, Wednesday, Friday and Sunday.
			local.last = arguments.high;
		}
		if (local.last < local.first) {
			$invalid("'#arguments.part#' is a reversed range in the #arguments.label# field.");
		}
		return {first = local.first, last = local.last, step = local.step};
	}

	private numeric function $value(required string token, required numeric low, required numeric high, required string label, required string names) {
		if (Len(arguments.names) && ListFindNoCase(arguments.names, arguments.token)) {
			// Month names start at 1, day names at 0.
			return ListFindNoCase(arguments.names, arguments.token) - (arguments.label == "day-of-week" ? 1 : 0);
		}
		if (!REFind("^[0-9]+$", arguments.token)) {
			$invalid("'#arguments.token#' isn't a valid #arguments.label# value.");
		}
		local.v = Val(arguments.token);
		if (local.v < arguments.low || local.v > arguments.high) {
			$invalid("#arguments.label# value #local.v# is out of range (#arguments.low#-#arguments.high#).");
		}
		return local.v;
	}

	/**
	 * Vixie cron: when either day field is starred (starts with an asterisk, with or without a
	 * step), a day must match both; when neither is, matching either is enough.
	 */
	private boolean function $dayMatches(required struct cron, required struct f) {
		local.dayOk = arguments.cron.days[arguments.f.day];
		local.weekdayOk = arguments.cron.weekdays[arguments.f.weekday + 1];
		if (arguments.cron.dayStarred || arguments.cron.weekdayStarred) {
			return local.dayOk && local.weekdayOk;
		}
		return local.dayOk || local.weekdayOk;
	}

	/**
	 * "" for UTC (pure arithmetic), else a java.time ZoneId. Throws Wheels.Job.InvalidSchedule
	 * for an unknown zone, or for a non-UTC zone where java.time isn't available.
	 */
	private any function $zone(required string timeZone) {
		local.name = Trim(arguments.timeZone);
		if (!Len(local.name) || ListFindNoCase("UTC,Etc/UTC,Z,GMT,Etc/GMT", local.name)) {
			return "";
		}
		if (!$javaTimeAvailable()) {
			$invalid("Time zone '#local.name#' needs java.time, which this CFML engine doesn't provide. Use timezone(""UTC"") and write the cron in UTC.");
		}
		var outcome = {zone = "", error = ""};
		try {
			outcome.zone = CreateObject("java", "java.time.ZoneId").of(local.name);
		} catch (any e) {
			outcome.error = e.message;
		}
		if (Len(outcome.error)) {
			$invalid("Time zone '#local.name#' can't be used: #outcome.error# Use an IANA name such as America/New_York (UTC needs no time zone support).");
		}
		return outcome.zone;
	}

	/**
	 * Whether this engine has the java.time this component uses, probed once per application:
	 * a New York local time converted to an instant and back, and an unknown zone rejected. A
	 * partial implementation (no LocalDateTime.of, or a ZoneId.of that accepts anything) is
	 * treated as missing, so non-UTC schedules are refused instead of computed wrongly.
	 */
	public boolean function $javaTimeAvailable() {
		if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "$jobsJavaTimeAvailable")) {
			return application.wheels.$jobsJavaTimeAvailable;
		}
		var probe = {ok = false};
		try {
			var zone = CreateObject("java", "java.time.ZoneId").of("America/New_York");
			var ldt = CreateObject("java", "java.time.LocalDateTime").of(JavaCast("int", 2026), JavaCast("int", 1), JavaCast("int", 15), JavaCast("int", 12), JavaCast("int", 0));
			var instantMs = ldt.atZone(zone).toInstant().toEpochMilli();
			var hourBack = CreateObject("java", "java.time.Instant").ofEpochMilli(JavaCast("long", instantMs)).atZone(zone).toLocalDateTime().getHour();
			probe.ok = instantMs == msFromIsoUtc("2026-01-15T17:00Z") && hourBack == 12;
		} catch (any e) {
			probe.ok = false;
		}
		if (probe.ok) {
			try {
				CreateObject("java", "java.time.ZoneId").of("Mars/Olympus_Mons");
				probe.ok = false;
			} catch (any e) {
				// An unknown zone must be refused.
			}
		}
		if (StructKeyExists(application, "wheels")) {
			application.wheels.$jobsJavaTimeAvailable = probe.ok;
		}
		return probe.ok;
	}

	private numeric function $localMinute(required numeric epochMs, required any zone) {
		if (IsSimpleValue(arguments.zone)) {
			return Floor(arguments.epochMs / 60000);
		}
		local.ldt = CreateObject("java", "java.time.Instant").ofEpochMilli(JavaCast("long", arguments.epochMs)).atZone(arguments.zone).toLocalDateTime();
		return $daysFromCivil(local.ldt.getYear(), local.ldt.getMonthValue(), local.ldt.getDayOfMonth()) * 1440
			+ local.ldt.getHour() * 60 + local.ldt.getMinute();
	}

	private numeric function $instantOf(required numeric localMinute, required any zone) {
		if (IsSimpleValue(arguments.zone)) {
			return arguments.localMinute * 60000;
		}
		local.f = $civilFromMinute(arguments.localMinute);
		local.ldt = CreateObject("java", "java.time.LocalDateTime").of(
			JavaCast("int", local.f.year),
			JavaCast("int", local.f.month),
			JavaCast("int", local.f.day),
			JavaCast("int", local.f.hour),
			JavaCast("int", local.f.minute)
		);
		local.rules = arguments.zone.getRules();
		if (local.rules.getValidOffsets(local.ldt).size() == 0) {
			// Spring forward: this local time doesn't exist; run at the next valid instant.
			return local.rules.getTransition(local.ldt).getInstant().toEpochMilli();
		}
		// atZone keeps the earlier offset in an overlap: the first occurrence.
		return local.ldt.atZone(arguments.zone).toInstant().toEpochMilli();
	}

	private struct function $civilFromMinute(required numeric localMinute) {
		local.days = Floor(arguments.localMinute / 1440);
		local.inDay = arguments.localMinute - local.days * 1440;
		local.rv = $civilFromDays(local.days);
		local.rv.days = local.days;
		local.rv.hour = Floor(local.inDay / 60);
		local.rv.minute = local.inDay - local.rv.hour * 60;
		// 1970-01-01 was a Thursday (4); 0 = Sunday.
		local.rv.weekday = (local.days + 4) MOD 7;
		return local.rv;
	}

	private numeric function $firstMinuteOfNextMonth(required numeric year, required numeric month) {
		local.y = arguments.month == 12 ? arguments.year + 1 : arguments.year;
		local.m = arguments.month == 12 ? 1 : arguments.month + 1;
		return $daysFromCivil(local.y, local.m, 1) * 1440;
	}

	/**
	 * Days since 1970-01-01 for a proleptic Gregorian date (H. Hinnant's days_from_civil).
	 */
	private numeric function $daysFromCivil(required numeric year, required numeric month, required numeric day) {
		local.y = arguments.month <= 2 ? arguments.year - 1 : arguments.year;
		local.era = Floor(local.y / 400);
		local.yoe = local.y - local.era * 400;
		local.mp = arguments.month > 2 ? arguments.month - 3 : arguments.month + 9;
		local.doy = Floor((153 * local.mp + 2) / 5) + arguments.day - 1;
		local.doe = local.yoe * 365 + Floor(local.yoe / 4) - Floor(local.yoe / 100) + local.doy;
		return local.era * 146097 + local.doe - 719468;
	}

	/**
	 * The proleptic Gregorian date for days since 1970-01-01 (civil_from_days).
	 */
	private struct function $civilFromDays(required numeric days) {
		local.z = arguments.days + 719468;
		local.era = Floor(local.z / 146097);
		local.doe = local.z - local.era * 146097;
		local.yoe = Floor((local.doe - Floor(local.doe / 1460) + Floor(local.doe / 36524) - Floor(local.doe / 146096)) / 365);
		local.y = local.yoe + local.era * 400;
		local.doy = local.doe - (365 * local.yoe + Floor(local.yoe / 4) - Floor(local.yoe / 100));
		local.mp = Floor((5 * local.doy + 2) / 153);
		local.d = local.doy - Floor((153 * local.mp + 2) / 5) + 1;
		local.m = local.mp < 10 ? local.mp + 3 : local.mp - 9;
		return {year = local.m <= 2 ? local.y + 1 : local.y, month = local.m, day = local.d};
	}

	private void function $invalid(required string message) {
		Throw(type = "Wheels.Job.InvalidSchedule", message = arguments.message);
	}

}
