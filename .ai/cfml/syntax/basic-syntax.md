# Basic CFML Syntax

## Overview
CFML supports two syntax styles: tag-based syntax (for views/templates) and script syntax (for business logic/components). Modern CFML development emphasizes script syntax for components and business logic.

## Syntax
- `.cfm` files: ColdFusion markup files (tag-based by default)
- `.cfc` files: ColdFusion Component files (script-based by default)
- Semi-colons are optional in Lucee and Adobe ColdFusion 2018+
- Language is case-insensitive but best practice is to maintain consistent casing

## Examples

### Basic Script Syntax
```cfscript
// Variable assignment
s = new Sample();
writeOutput( s.hello() );

// Function definition
function hello(){
    return "Hello, World!";
}
```

### Tag Syntax
```markup
<cfset s = new Sample()>
<cfoutput>#s.hello()#</cfoutput>
```

### Mixed Syntax (Script in Tag-based File)
```markup
<cfscript>
    s = new Sample();
    writeOutput( s.hello() );
</cfscript>
```

## Key Points
- Tag syntax uses `<cf...>` constructs
- Script syntax uses JavaScript-like syntax
- Semi-colons are line terminators (optional in modern engines)
- Variables are dynamically typed
- Case-insensitive language but consistent casing is recommended
- Built-in functions are first-class functions (can be passed as arguments)

## Related Concepts
- [Comments](comments.md)
- [Variables](../data-types/variables.md)
- [Variable Scopes](../data-types/variable-scopes.md)