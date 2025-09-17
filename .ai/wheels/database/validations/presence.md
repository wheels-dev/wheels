# Presence Validation

## Description
Ensures that specified properties have non-blank values before saving to the database.

## Key Points
- Use `validatesPresenceOf()` in model's `config()` method
- Automatically applied to NOT NULL database columns
- Checks for empty strings, null values, and whitespace-only strings
- Multiple properties can be validated in single call
- Can be conditional with `when`, `condition`, or `unless`

## Code Sample
```cfm
component extends="Model" {
    function config() {
        // Basic presence validation
        validatesPresenceOf("firstName,lastName,email");

        // Single property
        validatesPresenceOf(property="username");

        // Conditional validation
        validatesPresenceOf(
            property="phoneNumber",
            when="onUpdate",
            message="Phone number is required for updates"
        );

        // Custom condition
        validatesPresenceOf(
            property="companyName",
            condition="this.userType == 'business'"
        );
    }
}
```

## Usage
1. Add `validatesPresenceOf()` in model's `config()` method
2. Specify single property or comma-separated list
3. Add conditions if validation only applies in certain scenarios
4. Custom error messages with `message` argument

## Related
- [Object Validation Overview](../../database/validations/custom.md)
- [Uniqueness Validation](./uniqueness.md)
- [Format Validation](./format.md)

## Important Notes
- Automatically applied to NOT NULL columns
- Disabled for columns with database defaults
- Overrides automatic validation when explicitly set
- Checks for blank strings, not just null values
- Runs before create, update, and save operations