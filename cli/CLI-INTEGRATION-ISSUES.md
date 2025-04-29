# CLI Integration Issues

This document outlines issues found during the integration of the wheels-cli into the main CFWheels repository and their solutions.

## Syntax Issues

### Missing Helper Functions

When integrating the CLI code, some helper functions may be missing:

1. **Missing stripTags() Function**
   - The `stripTags()` function used in `base.cfc` was missing in the `helpers.cfc` file
   - Solution: Add the function to `helpers.cfc`:
   ```cfml
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
   ```

### String Escaping

When CFML code generates strings that contain Bash/Shell commands or JSON/XML, proper escaping is needed:

1. **Double Quotes vs. Single Quotes**
   - Use single quotes for shell commands when embedding variables:
   ```cfml
   // Bad:
   - echo \"$SSH_PRIVATE_KEY\" | tr -d '\\r' | ssh-add -
   
   // Good:
   - echo '$SSH_PRIVATE_KEY' | tr -d '\r' | ssh-add -
   ```

2. **XML in RUN Commands**
   - Use single quotes for outer shell command and double quotes for XML attributes:
   ```cfml
   // Bad:
   RUN echo \"<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?><config><session timeout=\\\"120\\\" /></config>\" > /file.xml
   
   // Good:
   RUN echo '<?xml version=\"1.0\" encoding=\"UTF-8\"?><config><session timeout=\"120\" /></config>' > /file.xml
   ```

3. **Docker CMD Arrays**
   - Use single quotes inside string literals for Docker CMD arrays:
   ```cfml
   // Bad:
   CMD [\"catalina.sh\", \"run\"]
   
   // Good:
   CMD ['catalina.sh', 'run']
   ```

### Hash (#) Escaping in CFML

The hash/pound symbol (#) is special in CFML as it's used for variable interpolation. When generating content that includes this symbol:

1. **CSS Colors**
   - Double the hash for literal hash symbols in CSS:
   ```cfml
   // Bad:
   background-color: #1a1a1a;
   
   // Good:
   background-color: ##1a1a1a;
   ```

2. **Element IDs in JavaScript**
   - Double the hash for element IDs in JavaScript:
   ```cfml
   // Bad:
   createApp(App).mount("#app");
   
   // Good:
   createApp(App).mount("##app");
   ```

3. **Markdown Content with Variables**
   - Double the hash for headings in Markdown when mixing with CFML variables:
   ```cfml
   // Bad:
   # #local.docTitle#
   
   // Good:
   # ##local.docTitle##
   ```

## Recommendations

1. **Prefer Single Quotes for Shell Commands**
   - When generating strings containing shell commands, prefer single quotes for the outer string
   
2. **Use String Concatenation for Complex Content**
   - For complex multi-line content (like API documentation), use string concatenation with `&= chr(10)` for line breaks instead of multi-line literal strings
   - This avoids issues with special characters like # and quotes

3. **Validate Files After Escaping**
   - Test all files after making escaping changes to ensure they load correctly in CommandBox

4. **Consider Template Files for Complex Content**
   - For very complex string generation (like documentation), store templates in separate files and read them in
   - This separates the string literals from the CFML code and improves maintainability

## Fixed Files

The following files required syntax fixes:

1. `/cli/commands/wheels/ci/init.cfc` - SSH key and command escaping
2. `/cli/commands/wheels/docker/deploy.cfc` - Docker CMD and XML escaping, error messages with hash symbols
3. `/cli/commands/wheels/docker/init.cfc` - Docker CMD escaping, error messages with hash symbols
4. `/cli/commands/wheels/generate/api-resource.cfc` - Markdown headings with variables
5. `/cli/commands/wheels/generate/frontend.cfc` - CSS colors and DOM element IDs
6. `/cli/models/helpers.cfc` - Hash symbols in regular expression and missing functions

## Testing Process

To verify that CLI commands are working correctly:

1. Start CommandBox in the CFWheels project directory:
   ```bash
   cd /path/to/cfwheels && box
   ```

2. Run a simple wheels command:
   ```bash
   wheels help
   ```

3. Test more complex commands:
   ```bash
   wheels docker init --help
   wheels generate api-resource --help
   ```

4. If a command fails, check the error message for clues about syntax issues.

5. For commands requiring server connection (like `wheels info`), remember to start the server first.

## Additional Recommendations

1. Standardize string building patterns across the codebase
2. Consider creating helper functions for complex string generation
3. Use array-based construction for complex content:
   ```cfml
   local.lines = [];
   arrayAppend(local.lines, "Line 1");
   arrayAppend(local.lines, "Line 2");
   local.content = arrayToList(local.lines, chr(10));
   ```
4. Add tests for CLI commands to catch syntax issues early
5. Document command inputs and outputs for easier maintenance
6. Check for missing helper functions when porting code between repositories