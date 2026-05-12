/**
 * Shared string-building helpers for *Commands.cfc.
 * Source of truth: Kamal 2.4.0 lib/kamal/commands/base.rb
 * All methods return strings. No I/O.
 */
component {

    public string function docker() {
        var parts = ["docker"];
        for (var i = 1; i <= arrayLen(arguments); i++) {
            var a = arguments[i];
            if (isArray(a)) {
                for (var item in a) if (len(item)) arrayAppend(parts, item);
            } else if (len(a)) {
                arrayAppend(parts, a);
            }
        }
        return arrayToList(parts, " ");
    }

    public string function combine(required array cmds, string sep = " ") {
        return arrayToList(arguments.cmds, arguments.sep);
    }

    public string function chain(required array cmds) {
        return combine(arguments.cmds, " && ");
    }

    public string function pipe(required array cmds) {
        return combine(arguments.cmds, " | ");
    }

    public string function appendIf(required boolean cond, required array args) {
        return arguments.cond ? arrayToList(arguments.args, " ") : "";
    }
}
