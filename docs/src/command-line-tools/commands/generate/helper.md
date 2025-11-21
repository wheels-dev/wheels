# wheels generate helper

Generate global helper functions for use throughout the application.

## Synopsis

```bash
wheels generate helper name=<helperName> [options]

# Can also be used as:
wheels g helper name=<helperName> [options]
```

## CommandBox Parameter Syntax

- **Named parameters**: `param=value` (e.g., `name=Format`, `functions="truncate,slugify"`)
- **Flag parameters**: `--flag` equals `flag=true` (e.g., `--force` equals `force=true`)
- **Param with value**: `--param=value` equals `param=value` (e.g., `--description="Formatting utilities"`)

**Recommended:** Use named parameters with flags: `wheels generate helper name=StringUtils --functions="truncate,highlight,slugify"`

## Description

The `wheels generate helper` command creates global helper function files that are automatically available throughout your application. Helper functions are useful for view formatting, data transformation, and reusable utility functions. All generated helpers are automatically included in `/app/global/functions.cfm` and become globally accessible.

## Arguments

| Argument | Description | Default |
|----------|-------------|---------|
| `name` | Helper name (e.g., Format, StringUtils) | Required |

### Helper Name Validation
- Helper name must be a valid CFML component name
- Cannot contain spaces or special characters
- Will automatically append "Helper" if not present (Format → FormatHelper)
- Must be unique (cannot overwrite existing helper without `--force`)

## Options

| Option | Description | Valid Values | Default |
|--------|-------------|--------------|---------|
| `functions` | Comma-separated list of functions to generate | Valid CFML function names | `"helperFunction"` |
| `description` | it will be placed as comment at the top of helper file | Any descriptive text | `""` |
| `force` | Overwrite existing files and skip validation | `true`, `false` | `false` |

### Function Name Validation
- Function names must be unique across all helper files
- Must be valid CFML function names
- Cannot duplicate existing global functions
- Validation is skipped when using `--force`

## Examples

### Basic helper
```bash
wheels generate helper name=Format
```
Creates:
- `/app/helpers/FormatHelper.cfm` with default helper function
- Adds include to `/app/global/functions.cfm`
- `/tests/specs/helpers/FormatHelperSpec.cfc` test file

### Helper with multiple functions
```bash
wheels generate helper name=StringUtils --functions="truncate,highlight,slugify"
```
Creates a helper with three functions: `truncate()`, `highlight()`, `slugify()`

### Helper with description
```bash
wheels generate helper name=DateHelpers --description="Date formatting and manipulation utilities" --functions="formatDate,timeAgo"
```
Adds description to the helper file header

### Force overwrite existing helper
```bash
wheels generate helper name=Format --force
```
Overwrites existing FormatHelper.cfm without prompting

### Complex helper with smart templates
```bash
wheels generate helper name=Format --functions="currency,date,truncate"
```
The generator recognizes common function names and creates appropriate implementations:
- `currency` → Currency formatting logic
- `date` → Date formatting logic
- `truncate` → Text truncation logic

## Generated Code Examples

### Basic Helper Structure
```cfm
/**
 * FormatHelper
 */
<cfscript>

	/**
	 * Helper function helper function
	 * @value.hint The value to process
	 * @options.hint Additional options
	 * @return Processed value
	 */
	public any function helperFunction(
		required any value,
		struct options = {}
	) {
		// TODO: Implement helperFunction logic
		return arguments.value;
	}

</cfscript>
```

### Helper with Description
```cfm
/**
 * DateHelper
 * Date formatting and manipulation utilities
 */
<cfscript>

	/**
	 * Format date helper function
	 * @value.hint The value to process
	 * @options.hint Additional options
	 * @return Processed value
	 */
	public any function formatDate(
		required any value,
		struct options = {}
	) {
		// Format date with relative time support
		if (!isDate(arguments.value)) {
			return arguments.value;
		}

		local.format = arguments.options.format ?: "medium";

		switch(local.format) {
			case "relative":
				return timeAgoInWords(arguments.value);
			case "short":
				return dateFormat(arguments.value, "m/d/yy");
			case "long":
				return dateFormat(arguments.value, "mmmm d, yyyy");
			default:
				return dateFormat(arguments.value, "mmm d, yyyy");
		}
	}

</cfscript>
```

### Smart Template: Truncate Function
```cfm
/**
 * Truncate helper function
 * @value.hint The value to process
 * @options.hint Additional options
 * @return Processed value
 */
public any function truncate(
	required any value,
	struct options = {}
) {
	// Truncate text to specified length
	local.length = arguments.options.length ?: 100;
	local.suffix = arguments.options.suffix ?: "...";

	if (len(arguments.value) <= local.length) {
		return arguments.value;
	}

	return left(arguments.value, local.length - len(local.suffix)) & local.suffix;
}
```

### Smart Template: Slugify Function
```cfm
/**
 * Slugify helper function
 * @value.hint The value to process
 * @options.hint Additional options
 * @return Processed value
 */
public any function slugify(
	required any value,
	struct options = {}
) {
	// Convert text to URL-friendly slug
	local.slug = lCase(trim(arguments.value));

	// Replace spaces with hyphens
	local.slug = reReplace(local.slug, "\s+", "-", "all");

	// Remove non-alphanumeric characters except hyphens
	local.slug = reReplace(local.slug, "[^a-z0-9\-]", "", "all");

	// Remove multiple consecutive hyphens
	local.slug = reReplace(local.slug, "\-+", "-", "all");

	// Trim hyphens from start and end
	local.slug = reReplace(local.slug, "^\-|\-$", "", "all");

	return local.slug;
}
```

### Smart Template: Currency Function
```cfm
/**
 * Currency helper function
 * @value.hint The value to process
 * @options.hint Additional options
 * @return Processed value
 */
public any function currency(
	required any value,
	struct options = {}
) {
	// Format currency values
	if (!isNumeric(arguments.value)) {
		return arguments.value;
	}

	local.currency = arguments.options.currency ?: "USD";
	local.symbol = arguments.options.symbol ?: "$";

	return local.symbol & numberFormat(arguments.value, "0.00");
}
```

## Automatic Include in functions.cfm

When you generate a helper, it's automatically added to `/app/global/functions.cfm`:

```cfm
<cfscript>
//=====================================================================
//=     Global Functions
//=====================================================================
include "../helpers/FormatHelper.cfm";
include "../helpers/StringUtilsHelper.cfm";
include "../helpers/DateHelper.cfm";
</cfscript>
```

## Using Helpers in Your Application

### In Controllers
```cfm
component extends="Controller" {

	function index() {
		users = model("User").findAll();

		// Use helper function
		for (user in users) {
			user.displayName = truncate(user.bio, {length: 50});
		}
	}

}
```

### In Views
```cfm
<cfparam name="post">
<cfoutput>
	<article>
		<h1>#post.title#</h1>
		<p class="meta">
			Posted #formatDate(post.createdAt, {format: "relative"})# by #post.author#
		</p>
		<div class="content">
			#post.content#
		</div>
		<div class="permalink">
			/posts/#slugify(post.title)#
		</div>
	</article>
</cfoutput>
```

### In Models
```cfm
component extends="Model" {

	function init() {
		beforeSave("generateSlug");
	}

	private function generateSlug() {
		if (!StructKeyExists(this, "slug") || !len(this.slug)) {
			this.slug = slugify(this.title);
		}
	}

}
```

## Smart Template Functions

The generator recognizes common function name patterns and creates appropriate implementations:

| Function Name Pattern | Generated Implementation |
|----------------------|--------------------------|
| Contains "truncate" | Text truncation with length and suffix options |
| Contains "highlight" | Search term highlighting with CSS class |
| Contains "slugify" | URL-friendly slug generation |
| Contains "date" | Date formatting with relative time support |
| Contains "currency" or "money" | Currency formatting with symbol |
| Contains "format" | Generic formatting based on data type |
| Other names | Basic template with TODO comment |

## Function Conflict Detection

The generator validates that function names are unique across all helper files:

### Valid: Unique Function Names
```bash
# First helper
wheels generate helper name=String --functions="truncate,slugify"

# Second helper (different functions)
wheels generate helper name=Format --functions="currency,date"
# Success: No conflicts
```

### Invalid: Duplicate Function Names
```bash
# First helper
wheels generate helper name=String --functions="truncate"

# Second helper (same function)
wheels generate helper name=Text --functions="truncate"
# Error: The following function(s) already exist in helper files: truncate (in StringHelper.cfm)
```

### Override with Force
```bash
# Overwrite with force flag (skips validation)
wheels generate helper name=Text --functions="truncate" --force=true
# Success: File created (may cause global function conflicts)
```

## Common Use Cases

### Text Formatting Helpers
```bash
wheels generate helper name=TextFormat --functions="truncate,excerpt,wordCount,capitalize"
```

### Date/Time Helpers
```bash
wheels generate helper name=DateHelpers --functions="formatDate,timeAgo,businessDays"
```

### URL/String Helpers
```bash
wheels generate helper name=URLHelpers --functions="slugify,urlEncode,sanitizeFilename"
```

### Number Formatting Helpers
```bash
wheels generate helper name=NumberFormat --functions="currency,percentage,fileSize"
```

### Validation Helpers
```bash
wheels generate helper name=ValidationHelpers --functions="isEmail,isPhone,isURL"
```

## Best Practices

1. **Naming**: Use descriptive helper names that indicate purpose (StringUtils, DateHelpers)
2. **Function Names**: Keep function names concise and action-oriented (truncate, not truncateText)
3. **Global Scope**: Remember helpers are global - use unique, descriptive names
4. **Options Pattern**: Use options struct for flexibility instead of many parameters
5. **Type Checking**: Validate input types before processing
6. **Documentation**: Use hint attributes to document parameters and return values
7. **Testing**: Always create and run tests for helper functions
8. **Validation**: Check for function conflicts before creating helpers

## Common Patterns

### Options Struct Pattern
```cfm
public any function formatText(
	required any value,
	struct options = {}
) {
	// Extract options with defaults
	local.maxLength = arguments.options.maxLength ?: 100;
	local.suffix = arguments.options.suffix ?: "...";
	local.preserveWords = arguments.options.preserveWords ?: true;

	// Process with options
	// ...
}
```

### Type-Safe Helpers
```cfm
public string function formatCurrency(
	required any value,
	struct options = {}
) {
	// Validate input
	if (!isNumeric(arguments.value)) {
		throw(type="InvalidArgument", message="Value must be numeric");
	}

	// Process
	return dollarFormat(arguments.value);
}
```

### Chainable Helpers
```cfm
public string function sanitize(required string value) {
	return trim(htmlEditFormat(arguments.value));
}

// Usage: displayText = sanitize(userInput)
```

## Testing

The generator automatically creates test files:

```cfc
// /tests/specs/helpers/FormatHelperSpec.cfc
component extends="wheels.Test" {

	function setup() {
		// Global helpers are automatically included
	}

	function test_truncate() {
		// Test truncate function
		local.input = "test value";
		local.result = truncate(local.input);

		assert(isDefined("local.result"), "Function should return a value");
	}

}
```

### Running Tests
```bash
wheels test run
```

## Error Handling

### Invalid Helper Name
```bash
wheels generate helper name="My Helper"
# Error: Invalid helper name: Cannot contain spaces
```

### Function Name Conflict
```bash
wheels generate helper name=Utils --functions="truncate"
# Error: The following function(s) already exist in helper files: truncate (in StringHelper.cfm)
```

### File Already Exists
```bash
wheels generate helper name=Format
# Error: Helper already exists: FormatHelper.cfm. Use force=true to overwrite.
```

## See Also

- [wheels generate controller](controller.md) - Generate controllers
- [wheels generate model](model.md) - Generate models
- [wheels generate test](test.md) - Generate tests
- [Template System Guide](../../cli-guides/template-system.md) - Customize generator templates
