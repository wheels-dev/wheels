# Format Validation

## Description
Validates that property values match specific regular expression patterns or formats.

## Key Points
- Use `validatesFormatOf()` with regular expression patterns
- Common for email, phone, URL, and custom format validation
- Supports both `regEx` and `type` parameters
- Built-in types: email, URL, numeric, creditcard
- Case-sensitive matching by default

## Code Sample
```cfm
component extends="Model" {
    function config() {
        // Email format validation
        validatesFormatOf(
            property="email",
            regEx="^[\w\.-]+@[\w\.-]+\.\w+$",
            message="Please enter a valid email address"
        );

        // Built-in email type
        validatesFormatOf(property="email", type="email");

        // Phone number format
        validatesFormatOf(
            property="phoneNumber",
            regEx="^\(\d{3}\) \d{3}-\d{4}$",
            message="Format: (555) 123-4567"
        );

        // URL validation
        validatesFormatOf(property="website", type="url");

        // Custom format with conditions
        validatesFormatOf(
            property="socialSecurityNumber",
            regEx="^\d{3}-\d{2}-\d{4}$",
            when="onCreate",
            allowBlank=true
        );
    }
}
```

## Usage
1. Add `validatesFormatOf()` in model's `config()` method
2. Use `regEx` parameter for custom patterns
3. Use `type` parameter for built-in formats
4. Set `allowBlank=true` to skip validation on empty values
5. Add helpful error messages for user guidance

## Related
- [Presence Validation](./presence.md)
- [Uniqueness Validation](./uniqueness.md)
- [Custom Validation](./custom.md)

## Important Notes
- Regular expressions are case-sensitive by default
- Built-in types: email, url, numeric, creditcard, zipcode
- Use `allowBlank=true` for optional formatted fields
- Combine with presence validation for required formatted fields
- Test regular expressions thoroughly with edge cases