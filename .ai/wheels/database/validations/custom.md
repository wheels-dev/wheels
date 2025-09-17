# Custom Validation

## Description
Create custom validation logic using the `validate()`, `validateOnCreate()`, and `validateOnUpdate()` methods.

## Key Points
- Use `validate()` for all operations, `validateOnCreate()` and `validateOnUpdate()` for specific operations
- Custom methods should call `addError()` when validation fails
- Can access object properties and external resources
- Supports conditional validation with model state
- Runs after built-in validations

## Code Sample
```cfm
component extends="Model" {
    function config() {
        // Run on all save operations
        validate("validateBusinessRules");

        // Run only on create
        validateOnCreate("validateNewUserRequirements");

        // Run only on update
        validateOnUpdate("validatePasswordChange");
    }

    private function validateBusinessRules() {
        // Custom business logic validation
        if (this.age < 18 && this.accountType == "premium") {
            addError(property="age", message="Premium accounts require age 18+");
        }

        // Cross-field validation
        if (this.startDate > this.endDate) {
            addError(property="endDate", message="End date must be after start date");
        }

        // External validation (API, service, etc.)
        if (!isValidCreditCard(this.creditCardNumber)) {
            addError(property="creditCardNumber", message="Invalid credit card number");
        }
    }

    private function validatePasswordChange() {
        // Only run on updates if password changed
        if (hasChanged("password") && Len(this.password) < 8) {
            addError(property="password", message="Password must be at least 8 characters");
        }
    }
}
```

## Usage
1. Add `validate()`, `validateOnCreate()`, or `validateOnUpdate()` in `config()`
2. Create private methods for validation logic
3. Use `addError(property, message)` to register validation failures
4. Access object properties with `this.propertyName`
5. Use `hasChanged()` to check if properties were modified

## Related
- [Presence Validation](./presence.md)
- [Format Validation](./format.md)
- [Object Callbacks](../../database/object-callbacks.md)

## Important Notes
- Custom validations run after built-in validations
- Use `addError()` to add validation failures
- Access to full object state and external resources
- Can validate relationships and business rules
- Should be private methods for security