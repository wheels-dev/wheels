# CFML Comments

## Overview
CFML supports multiple comment styles for different contexts: tag comments, script comments, and documentation comments. Proper commenting is essential for code maintenance and documentation generation.

## Syntax
- **Tag Comments**: `<!--- comment --->`
- **Script Single-line**: `// comment`
- **Script Multi-line**: `/* comment */`
- **Documentation**: `/** JavaDoc-style */`

## Examples

### Tag Comments
```markup
<!--- HTML Comment (visible in source) -->
<!-- I am an HTML Comment -->

<!--- ColdFusion Comment (not sent to browser) -->
<!--- I am a ColdFusion Comment --->
```

### Script Comments
```cfscript
// Single line comment

/*
  Multi
  Line
  Comments
  are
  great!
*/

/**
 * Multi-line Javadoc style comment
 *
 * @COLDBOX_CONFIG_FILE The override location of the config file
 * @COLDBOX_APP_ROOT_PATH The location of the app on disk
 */
```

### Documentation Comments
```cfscript
/**
 * This is my component
 *
 * @author Luis Majano
 */
component extends="Base" implements="IHello" singleton {

    /**
     * Constructor
     *
     * @wirebox The Injector
     * @wirebox.inject wirebox
     * @vars The vars I need
     * @vars.generic Array
     *
     * @return MyComponent
     * @throws SomethingException
     */
    function init(required wirebox, required vars) {
        variables.wirebox = arguments.wirebox;
        return this;
    }

}
```

### Function Documentation
```cfscript
/**
 * This is the hint for the function
 *
 * @param1 This is the hint for the param
 */
function myFunc(string param1) {
    // Function implementation
}
```

## Key Points
- CFML comments (`<!--- --->`) are not sent to the browser
- HTML comments (`<!-- -->`) are visible in browser source
- JavaDoc-style comments affect component and function metadata
- Documentation comments enable automatic API documentation generation
- DocBox library can generate documentation from CFCDoc comments
- Leading asterisks in multi-line comments are parsed out automatically

## Related Concepts
- [Basic Syntax](basic-syntax.md)
- [Components](../components/component-basics.md)
- [Functions](../components/functions.md)