/**
 * Helper functions for wheels CLI
 **/
component {
    
    function init(){ return this; }
    
    public struct function parseObjectNames(required string objectName) {
        local.objectName = arguments.objectName;
        local.objectNameSingular = singularize(local.objectName);
        local.objectNamePlural   = pluralize(local.objectName);
        loc.objectNameSingularC = capitalize(loc.objectNameSingular);
        loc.objectNamePluralC   = capitalize(loc.objectNamePlural);
        return loc;
    }

    public string function stripSpecialChars(required string str) {
        return trim(reReplace(str,"[{}()^$&%####!@=<>:;,~`'*?/+|\[\]\-\\]",'','all'));
    }
    
    /**
     * Removes all HTML tags from a string.
     *
     * @html The HTML to remove tag markup from.
     * @encode If true, HTML encodes the result.
     */
    public string function stripTags(required string html, boolean encode=false) {
        local.rv = ReReplaceNoCase(arguments.html, "<\ *[a-z].*?>", "", "all");
        local.rv = ReReplaceNoCase(local.rv, "<\ */\ *[a-z].*?>", "", "all");
        if (arguments.encode) {
            local.rv = EncodeForHTML(local.rv);
        }
        return local.rv;
    }

//=====================================================================
//=     String Functions stolen from cfwheels
//=====================================================================

    /**
     * Returns str with the first character converted to uppercase.
     */
    public string function capitalize(required string str) {
        local.rv = "";
        if (Len(arguments.str) > 0) {
            local.rv = UCase(Left(arguments.str, 1)) & Mid(arguments.str, 2, Len(arguments.str)-1);
        }
        return local.rv;
    }

    /**
     * Returns the plural form of the passed in word.
     * We're basically using the Rails inflector but with a few modifications.
     */
    public string function pluralize(required string word) {
        // Keep original word handy.
        local.result = arguments.word;
        
        // Some words need to be mapped.
        // Referenced below with len(local.map) gt 0
        local.map = "";
        
        if (Len(Trim(local.result))) {
            // Handle our test words
            if (REFindNoCase("(quiz)$", local.result)) {
                return local.result & "zes";
            }
            if (REFindNoCase("(matr|vert|ind)(ix|ex)$", local.result)) {
                return REeplaceNoCase(local.result, "ix|ex", "ices");
            }
            if (REFindNoCase("(x|ch|ss|sh)$", local.result)) {
                return local.result & "es";
            }
            if (REFindNoCase("([^aeiouy]|qu)y$", local.result)) {
                return REeplaceNoCase(local.result, "y$", "ies");
            }
            if (REFindNoCase("(hive)$", local.result)) {
                return REeplaceNoCase(local.result, "hive", "hives");
            }
            if (REFindNoCase("(?:([^f])fe|([lr])f)$", local.result)) {
                return REeplaceNoCase(local.result, "(?:([^f])fe|([lr])f)$", "\1\2ves");
            }
            if (REFindNoCase("sis$", local.result)) {
                return REeplaceNoCase(local.result, "sis$", "ses");
            }
            if (REFindNoCase("([ti])um$", local.result)) {
                return REeplaceNoCase(local.result, "([ti])um$", "\1a");
            }
            if (REFindNoCase("(buffal|tomat)o$", local.result)) {
                return REeplaceNoCase(local.result, "o$", "oes");
            }
            if (REFindNoCase("(ax|test)is$", local.result)) {
                return REeplaceNoCase(local.result, "is$", "es");
            }
            if (REFindNoCase("(octop|vir)us$", local.result)) {
                return REeplaceNoCase(local.result, "us$", "i");
            }
            if (REFindNoCase("(alias|status)$", local.result)) {
                return REeplaceNoCase(local.result, "$", "es");
            }
            if (REFindNoCase("(ox)$", local.result)) {
                return REeplaceNoCase(local.result, "ox$", "oxen");
            }
            if (REFindNoCase("(person)$", local.result)) {
                return REeplaceNoCase(local.result, "(person)$", "people");
            }
            if (REFindNoCase("(man)$", local.result)) {
                return REeplaceNoCase(local.result, "(man)$", "men");
            }
            if (REFindNoCase("(child)$", local.result)) {
                return REeplaceNoCase(local.result, "(child)$", "children");
            }
            if (REFindNoCase("(sex)$", local.result)) {
                return REeplaceNoCase(local.result, "(sex)$", "sexes");
            }
            if (REFindNoCase("(move)$", local.result)) {
                return REeplaceNoCase(local.result, "(move)$", "moves");
            }
            if (REFindNoCase("(shoe)$", local.result)) {
                return local.result & "s";
            }
            // our words that need to be mapped
            local.map = this.mappedWords(local.result);
            if (Len(local.map) > 0) {
                return local.map;
            }
            if (REFindNoCase("s$", local.result)) {
                return local.result;
            }
        }
        
        // If all matches fail, pluralizing will just add "s" to the word
        return local.result & "s";
    }

    /**
     * A helper method for pluralizing/singularizing
     * Returns a mapped value if one exists, otherwise it returns an empty string
     */
    public string function mappedWords(required string word) {
        local.pluralWords = {};
        local.singularWords = {};
        if (StructKeyExists(local.pluralWords, arguments.word)) {
            return local.pluralWords[arguments.word];
        } else if (StructKeyExists(local.singularWords, arguments.word)) {
            return local.singularWords[arguments.word];
        } else {
            return "";
        }
    }
    
    /**
     * Returns the singular form of the passed in word.
     */
    public string function singularize(required string word) {
        // Init the return value to the original string.
        local.result = arguments.word;
        
        // Return empty string if passed an empty string.
        if (!len(trim(local.result))) return local.result;
            
        // Some words need to be mapped.
        local.map = "";
                
        // Handle observable/observables
        // This is a custom addition, special case rules
        // might make sense to handle in the main wheels core
        // inflector, but doing one-off edge cases here is
        // probably fine
        if (REFindNoCase("(observable)s$", local.result)){
            return REeplaceNoCase(local.result, "(observable)s$", "\1");
        }
        
        if (REFindNoCase("(quiz)zes$", local.result)) {
            return REeplaceNoCase(local.result, "(quiz)zes$", "\1");
        }
        if (REFindNoCase("(matr)ices$", local.result)) {
            return REeplaceNoCase(local.result, "(matr)ices$", "\1ix");
        }
        if (REFindNoCase("(vert|ind)ices$", local.result)) {
            return REeplaceNoCase(local.result, "(vert|ind)ices$", "\1ex");
        }
        if (REFindNoCase("^(ox)en", local.result)) {
            return REeplaceNoCase(local.result, "^(ox)en", "\1");
        }
        if (REFindNoCase("(alias|status)es$", local.result)) {
            return REeplaceNoCase(local.result, "(alias|status)es$", "\1");
        }
        if (REFindNoCase("(octop|vir)i$", local.result)) {
            return REeplaceNoCase(local.result, "(octop|vir)i$", "\1us");
        }
        if (REFindNoCase("^(a)x[ie]s$", local.result)) {
            return REeplaceNoCase(local.result, "^(a)x[ie]s$", "\1xis");
        }
        if (REFindNoCase("(cris|test)es$", local.result)) {
            return REeplaceNoCase(local.result, "(cris|test)es$", "\1is");
        }
        if (REFindNoCase("(shoe)s$", local.result)) {
            return REeplaceNoCase(local.result, "(shoe)s$", "\1");
        }
        if (REFindNoCase("(o)es$", local.result)) {
            return REeplaceNoCase(local.result, "(o)es$", "\1");
        }
        if (REFindNoCase("(bus)es$", local.result)) {
            return REeplaceNoCase(local.result, "(bus)es$", "\1");
        }
        if (REFindNoCase("([m|l])ice$", local.result)) {
            return REeplaceNoCase(local.result, "([m|l])ice$", "\1ouse");
        }
        if (REFindNoCase("(x|ch|ss|sh)es$", local.result)) {
            return REeplaceNoCase(local.result, "(x|ch|ss|sh)es$", "\1");
        }
        if (REFindNoCase("(m)ovies$", local.result)) {
            return REeplaceNoCase(local.result, "(m)ovies$", "\1ovie");
        }
        if (REFindNoCase("(s)eries$", local.result)) {
            return REeplaceNoCase(local.result, "(s)eries$", "\1eries");
        }
        if (REFindNoCase("([^aeiouy]|qu)ies$", local.result)) {
            return REeplaceNoCase(local.result, "([^aeiouy]|qu)ies$", "\1y");
        }
        if (REFindNoCase("([lr])ves$", local.result)) {
            return REeplaceNoCase(local.result, "([lr])ves$", "\1f");
        }
        if (REFindNoCase("(tive)s$", local.result)) {
            return REeplaceNoCase(local.result, "(tive)s$", "\1");
        }
        if (REFindNoCase("(hive)s$", local.result)) {
            return REeplaceNoCase(local.result, "(hive)s$", "\1");
        }
        if (REFindNoCase("([^f])ves$", local.result)) {
            return REeplaceNoCase(local.result, "([^f])ves$", "\1fe");
        }
        if (REFindNoCase("(^analy)ses$", local.result)) {
            return REeplaceNoCase(local.result, "(^analy)ses$", "\1sis");
        }
        if (REFindNoCase("((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$", local.result)) {
            return REeplaceNoCase(local.result, "((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$", "\1\2sis");
        }
        if (REFindNoCase("([ti])a$", local.result)) {
            return REeplaceNoCase(local.result, "([ti])a$", "\1um");
        }
        if (REFindNoCase("(n)ews$", local.result)) {
            return REeplaceNoCase(local.result, "(n)ews$", "\1ews");
        }
        if (REFindNoCase("s$", local.result) && !REFindNoCase("(ss)$", local.result)) {
            return REeplaceNoCase(local.result, "s$", "");
        }
            
        // Return the word as-is if it can't be singularized.
        return local.result;
    }
}