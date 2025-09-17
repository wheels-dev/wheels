# CFScript vs Tags

## Overview
CFML offers two syntactic approaches: traditional tag-based syntax and modern script syntax. Modern CFML development favors script syntax for business logic and tag syntax for presentation layers.

## Syntax
- **Tag Syntax**: XML-like tags with `<cf...>` prefix
- **Script Syntax**: JavaScript-like syntax within `<cfscript>` blocks or `.cfc` files
- **Tags in Script**: Modern engines allow tag-like constructs in script format

## Examples

### Tag Syntax Example
```markup
<cfset name = "Luis">
<cfoutput>Hello #name#!</cfoutput>

<cfif structKeyExists(session, "user")>
    <cfset currentUser = session.user>
</cfif>
```

### Script Syntax Example
```cfscript
name = "Luis";
writeOutput("Hello " & name & "!");

if (structKeyExists(session, "user")) {
    currentUser = session.user;
}
```

### Tags in Script Format
```cfscript
cfhttp(method="GET", charset="utf-8", url="https://www.google.com/", result="result") {
    cfhttpparam(name="q", type="formfield", value="cfml");
}
```

### Component Definition
```cfscript
component {

    public string function hello() {
        return "Hello, World!";
    }

}
```

## Key Points
- Script syntax is preferred for business logic and components
- Tag syntax is preferred for presentation/view layers
- No functional differences between approaches - purely syntactic
- Script syntax is more familiar to developers from other languages
- Tags in script eliminate need for switching between syntaxes
- Modern engines support both approaches seamlessly

## Related Concepts
- [Basic Syntax](basic-syntax.md)
- [Comments](comments.md)
- [Components](../components/component-basics.md)