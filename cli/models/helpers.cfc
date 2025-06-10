component accessors="true" singleton {
    property name="serverService" inject="ServerService";

    // Return commonly used model name variants
    public struct function getNameVariants(required string name){
        var loc={};
        loc.objectName          = lcase(trim(arguments.name));
        loc.objectNameSingular  = singularize(loc.objectName);
        loc.objectNamePlural    = pluralize(loc.objectName);
        loc.objectNameSingularC = capitalize(loc.objectNameSingular);
        loc.objectNamePluralC   = capitalize(loc.objectNamePlural);
        return loc;
    }

    public string function stripSpecialChars(required string str) {
        return trim(reReplace(str,"[{}()^$&%##!@=<>:;,~`'*?/+|\[\]\-\\]",'','all'));
    }

//=====================================================================
//=     String Functions stolen from cfwheels
//=====================================================================

    public string function stripTags(required string html){
        var loc = {};
        loc.rv = REReplaceNoCase(arguments.html, "<\ *[a-z].*?>", "", "all");
        loc.rv = REReplaceNoCase(loc.rv, "<\ */\ *[a-z].*?>", "", "all");
        return loc.rv
    }
    public string function capitalize(string str){
        var rv=UCase(Left(arguments.str, 1)) & Mid(arguments.str, 2, Len(arguments.str)-1);
        return rv;
    }

    public string function pluralize(required string word, numeric count="-1", boolean returnCount="true"){
        return singularizeOrPluralize(text=arguments.word, which="pluralize", count=arguments.count, returnCount=arguments.returnCount);
    }
    public string function singularize(required string word){
        return singularizeOrPluralize(text=arguments.word, which="singularize");
    }

    public string function singularizeOrPluralize(required string text, required string which, numeric count="-1", boolean returnCount="true"){
        var loc = {};

        // by default we pluralize/singularize the entire string
        loc.text = arguments.text;

        // keep track of the success of any rule matches
        loc.ruleMatched = false;

        // when count is 1 we don't need to pluralize at all so just set the return value to the input string
        loc.rv = loc.text;

        if (arguments.count != 1)
        {

            if (REFind("[A-Z]", loc.text))
            {
                // only pluralize/singularize the last part of a camelCased variable (e.g. in "websiteStatusUpdate" we only change the "update" part)
                // also set a variable with the unchanged part of the string (to be prepended before returning final result)
                loc.upperCasePos = REFind("[A-Z]", Reverse(loc.text));
                loc.prepend = Mid(loc.text, 1, Len(loc.text)-loc.upperCasePos);
                loc.text = Reverse(Mid(Reverse(loc.text), 1, loc.upperCasePos));
            }
            loc.uncountables = "advice,air,blood,deer,equipment,fish,food,furniture,garbage,graffiti,grass,homework,housework,information,knowledge,luggage,mathematics,meat,milk,money,music,pollution,research,rice,sand,series,sheep,soap,software,species,sugar,traffic,transportation,travel,trash,water,feedback";
            loc.irregulars = "child,children,foot,feet,man,men,move,moves,person,people,sex,sexes,tooth,teeth,woman,women";
            if (ListFindNoCase(loc.uncountables, loc.text))
            {
                loc.rv = loc.text;
                loc.ruleMatched = true;
            }
            else if (ListFindNoCase(loc.irregulars, loc.text))
            {
                loc.pos = ListFindNoCase(loc.irregulars, loc.text);
                if (arguments.which == "singularize" && loc.pos % 2 == 0)
                {
                    loc.rv = ListGetAt(loc.irregulars, loc.pos-1);
                }
                else if (arguments.which == "pluralize" && loc.pos % 2 != 0)
                {
                    loc.rv = ListGetAt(loc.irregulars, loc.pos+1);
                }
                else
                {
                    loc.rv = loc.text;
                }
                loc.ruleMatched = true;
            }
            else
            {
                if (arguments.which == "pluralize")
                {
                    loc.ruleList = "(quiz)$,\1zes,^(ox)$,\1en,([m|l])ouse$,\1ice,(matr|vert|ind)ix|ex$,\1ices,(x|ch|ss|sh)$,\1es,([^aeiouy]|qu)y$,\1ies,(hive)$,\1s,(?:([^f])fe|([lr])f)$,\1\2ves,sis$,ses,([ti])um$,\1a,(buffal|tomat|potat|volcan|her)o$,\1oes,(bu)s$,\1ses,(alias|status)$,\1es,(octop|vir)us$,\1i,(ax|test)is$,\1es,s$,s,$,s";
                }
                else if (arguments.which == "singularize")
                {
                    loc.ruleList = "(quiz)zes$,\1,(matr)ices$,\1ix,(vert|ind)ices$,\1ex,^(ox)en,\1,(alias|status)es$,\1,([octop|vir])i$,\1us,(cris|ax|test)es$,\1is,(shoe)s$,\1,(o)es$,\1,(bus)es$,\1,([m|l])ice$,\1ouse,(x|ch|ss|sh)es$,\1,(m)ovies$,\1ovie,(s)eries$,\1eries,([^aeiouy]|qu)ies$,\1y,([lr])ves$,\1f,(tive)s$,\1,(hive)s$,\1,([^f])ves$,\1fe,(^analy)ses$,\1sis,((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$,\1\2sis,([ti])a$,\1um,(n)ews$,\1ews,(.*)?ss$,\1ss,s$,#Chr(7)#";
                }
                loc.rules = ArrayNew(2);
                loc.count = 1;
                loc.iEnd = ListLen(loc.ruleList);
                for (loc.i=1; loc.i <= loc.iEnd; loc.i=loc.i+2)
                {
                    loc.rules[loc.count][1] = ListGetAt(loc.ruleList, loc.i);
                    loc.rules[loc.count][2] = ListGetAt(loc.ruleList, loc.i+1);
                    loc.count = loc.count + 1;
                }
                loc.iEnd = ArrayLen(loc.rules);
                for (loc.i=1; loc.i <= loc.iEnd; loc.i++)
                {
                    if(REFindNoCase(loc.rules[loc.i][1], loc.text))
                    {
                        loc.rv = REReplaceNoCase(loc.text, loc.rules[loc.i][1], loc.rules[loc.i][2]);
                        loc.ruleMatched = true;
                        break;
                    }
                }
                loc.rv = Replace(loc.rv, Chr(7), "", "all");
            }

            // this was a camelCased string and we need to prepend the unchanged part to the result
            if (StructKeyExists(loc, "prepend") && loc.ruleMatched)
            {
                loc.rv = loc.prepend & loc.rv;
            }
        }

        // return the count number in the string (e.g. "5 sites" instead of just "sites")
        if (arguments.returnCount && arguments.count != -1)
        {
            loc.rv = LSNumberFormat(arguments.count) & " " & loc.rv;
        }
        return loc.rv;
    }
}
