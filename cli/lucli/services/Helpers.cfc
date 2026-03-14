/**
 * Standalone helpers for the Wheels LuCLI module.
 *
 * Provides string utilities (capitalize, pluralize, singularize) without
 * CommandBox DI dependencies. Business logic is ported from cli/src/models/helpers.cfc.
 */
component {

	public function init() {
		return this;
	}

	public string function capitalize(required string str) {
		if (!len(str)) return "";
		return uCase(left(str, 1)) & mid(str, 2, len(str) - 1);
	}

	public string function pluralize(required string word, numeric count = -1, boolean returnCount = true) {
		return singularizeOrPluralize(
			text = word,
			which = "pluralize",
			count = count,
			returnCount = returnCount
		);
	}

	public string function singularize(required string word) {
		return singularizeOrPluralize(text = word, which = "singularize");
	}

	public string function singularizeOrPluralize(
		required string text,
		required string which,
		numeric count = -1,
		boolean returnCount = true
	) {
		var loc = {};
		loc.text = text;
		loc.ruleMatched = false;
		loc.rv = loc.text;

		if (count != 1) {
			if (reFindNoCase("[A-Z]", loc.text)) {
				loc.upperCasePos = reFind("[A-Z]", reverse(loc.text));
				loc.prepend = mid(loc.text, 1, len(loc.text) - loc.upperCasePos);
				loc.text = reverse(mid(reverse(loc.text), 1, loc.upperCasePos));
			}

			loc.uncountables = "advice,air,blood,deer,equipment,fish,food,furniture,garbage,graffiti,grass,homework,housework,information,knowledge,luggage,mathematics,meat,milk,money,music,pollution,research,rice,sand,series,sheep,soap,software,species,sugar,traffic,transportation,travel,trash,water,feedback";
			loc.irregulars = "child,children,foot,feet,man,men,move,moves,person,people,sex,sexes,tooth,teeth,woman,women";

			if (listFindNoCase(loc.uncountables, loc.text)) {
				loc.rv = loc.text;
				loc.ruleMatched = true;
			} else if (listFindNoCase(loc.irregulars, loc.text)) {
				loc.pos = listFindNoCase(loc.irregulars, loc.text);
				if (which == "singularize" && loc.pos % 2 == 0) {
					loc.rv = listGetAt(loc.irregulars, loc.pos - 1);
				} else if (which == "pluralize" && loc.pos % 2 != 0) {
					loc.rv = listGetAt(loc.irregulars, loc.pos + 1);
				} else {
					loc.rv = loc.text;
				}
				loc.ruleMatched = true;
			} else {
				if (which == "pluralize") {
					loc.ruleList = "(quiz)$,\1zes,^(ox)$,\1en,([m|l])ouse$,\1ice,(matr|vert|ind)ix|ex$,\1ices,(x|ch|ss|sh)$,\1es,([^aeiouy]|qu)y$,\1ies,(hive)$,\1s,(?:([^f])fe|([lr])f)$,\1\2ves,sis$,ses,([ti])um$,\1a,(buffal|tomat|potat|volcan|her)o$,\1oes,(bu)s$,\1ses,(alias|status)$,\1es,(octop|vir)us$,\1i,(ax|test)is$,\1es,s$,s,$,s";
				} else if (which == "singularize") {
					loc.ruleList = "(quiz)zes$,\1,(matr)ices$,\1ix,(vert|ind)ices$,\1ex,^(ox)en,\1,(alias|status)es$,\1,([octop|vir])i$,\1us,(cris|ax|test)es$,\1is,(shoe)s$,\1,(o)es$,\1,(bus)es$,\1,([m|l])ice$,\1ouse,(x|ch|ss|sh)es$,\1,(m)ovies$,\1ovie,(s)eries$,\1eries,([^aeiouy]|qu)ies$,\1y,([lr])ves$,\1f,(tive)s$,\1,(hive)s$,\1,([^f])ves$,\1fe,(^analy)ses$,\1sis,((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$,\1\2sis,([ti])a$,\1um,(n)ews$,\1ews,(.*)?ss$,\1ss,s$,#chr(7)#";
				}

				loc.rules = [];
				loc.iEnd = listLen(loc.ruleList);
				for (loc.i = 1; loc.i <= loc.iEnd; loc.i += 2) {
					arrayAppend(loc.rules, [
						listGetAt(loc.ruleList, loc.i),
						listGetAt(loc.ruleList, loc.i + 1)
					]);
				}

				for (var rule in loc.rules) {
					if (reFindNoCase(rule[1], loc.text)) {
						loc.rv = reReplaceNoCase(loc.text, rule[1], rule[2]);
						loc.ruleMatched = true;
						break;
					}
				}
				loc.rv = replace(loc.rv, chr(7), "", "all");
			}

			if (structKeyExists(loc, "prepend") && loc.ruleMatched) {
				loc.rv = loc.prepend & loc.rv;
			}
		}

		if (returnCount && count != -1) {
			loc.rv = lsNumberFormat(count) & " " & loc.rv;
		}

		return loc.rv;
	}

	public string function stripSpecialChars(required string str) {
		return trim(reReplace(str, "[{}()^$&%##!@=<>:;,~`'*?/+|\[\]\-\\]", "", "all"));
	}

	/**
	 * Generate a migration timestamp (YYYYMMDDHHMMSS)
	 */
	public string function generateMigrationTimestamp() {
		var n = now();
		return dateFormat(n, "yyyymmdd") & timeFormat(n, "HHmmss");
	}

}
