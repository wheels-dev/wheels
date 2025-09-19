# Model Validations

## Description
Comprehensive guide to CFWheels model validation system, including built-in validations, custom validations, and validation patterns.

## Built-in Validation Methods

### Presence and Format Validations

#### Presence Validation
```cfm
component extends="Model" {
    function config() {
        // Required fields
        validatesPresenceOf("name,email,password");

        // Single property with custom message
        validatesPresenceOf(property="email", message="Email address is required");

        // Conditional presence
        validatesPresenceOf("parentId", condition="this.type == 'child'");
        validatesPresenceOf("companyName", unless="this.isIndividual");
    }
}
```

#### Format Validation
```cfm
component extends="Model" {
    function config() {
        // Email format
        validatesFormatOf(
            property="email",
            with="^[^\s@]+@[^\s@]+\.[^\s@]+$",
            message="Please enter a valid email address"
        );

        // Phone format
        validatesFormatOf(
            property="phone",
            with="^\(\d{3}\) \d{3}-\d{4}$",
            message="Phone must be in format (123) 456-7890"
        );

        // URL format
        validatesFormatOf(
            property="website",
            with="^https?://[^\s]+$",
            allowBlank=true
        );

        // Custom regex patterns
        validatesFormatOf(
            property="zipCode",
            with="^\d{5}(-\d{4})?$",
            message="ZIP code must be 5 digits or 9 digits with dash"
        );
    }
}
```

### Length and Numerical Validations

#### Length Validation
```cfm
component extends="Model" {
    function config() {
        // String length constraints
        validatesLengthOf(property="username", minimum=3, maximum=50);
        validatesLengthOf(property="password", minimum=8);
        validatesLengthOf(property="bio", maximum=500, allowBlank=true);

        // Exact length
        validatesLengthOf(property="postalCode", is=6);

        // Custom messages
        validatesLengthOf(
            property="title",
            minimum=5,
            maximum=255,
            message="Title must be between 5 and 255 characters"
        );
    }
}
```

#### Numerical Validation
```cfm
component extends="Model" {
    function config() {
        // Integer constraints
        validatesNumericalityOf(
            property="age",
            onlyInteger=true,
            greaterThan=0,
            lessThan=150
        );

        // Decimal constraints
        validatesNumericalityOf(property="price", greaterThan=0);
        validatesNumericalityOf(
            property="discount",
            greaterThanOrEqualTo=0,
            lessThanOrEqualTo=100
        );

        // Even or odd numbers
        validatesNumericalityOf(property="quantity", onlyInteger=true, odd=true);
        validatesNumericalityOf(property="pairs", onlyInteger=true, even=true);
    }
}
```

### Uniqueness and Confirmation

#### Uniqueness Validation
```cfm
component extends="Model" {
    function config() {
        // Simple uniqueness
        validatesUniquenessOf("email");
        validatesUniquenessOf("username");

        // Allow blank values
        validatesUniquenessOf("sku", allowBlank=true);

        // Scoped uniqueness (unique within a group)
        validatesUniquenessOf(property="name", scope="categoryid");
        validatesUniquenessOf(property="email", scope="companyid,departmentid");

        // Case sensitivity
        validatesUniquenessOf(property="username", caseSensitive=false);

        // Custom message
        validatesUniquenessOf(
            property="email",
            message="This email address is already registered"
        );
    }
}
```

#### Confirmation Validation
```cfm
component extends="Model" {
    function config() {
        // Password confirmation
        validatesConfirmationOf("password");

        // Email confirmation
        validatesConfirmationOf("email", when="onCreate");

        // Custom confirmation field name
        validatesConfirmationOf(
            property="newPassword",
            confirmation="passwordVerification"
        );
    }
}
```

### Inclusion and Exclusion

#### Inclusion Validation
```cfm
component extends="Model" {
    function config() {
        // Status must be in allowed list
        validatesInclusionOf(
            property="status",
            in="pending,approved,rejected"
        );

        // Priority levels
        validatesInclusionOf(
            property="priority",
            in="low,medium,high,urgent",
            message="Priority must be low, medium, high, or urgent"
        );

        // Array of values
        local.allowedRoles = ["user", "admin", "moderator"];
        validatesInclusionOf(property="role", in=local.allowedRoles);
    }
}
```

#### Exclusion Validation
```cfm
component extends="Model" {
    function config() {
        // Username cannot be reserved words
        validatesExclusionOf(
            property="username",
            in="admin,root,system,api,www",
            message="This username is reserved"
        );

        // Email domains to exclude
        validatesExclusionOf(
            property="email",
            in="@tempmail.com,@throwaway.email",
            message="Temporary email addresses are not allowed"
        );
    }
}
```

## Conditional Validations

### When Conditions
```cfm
component extends="Model" {
    function config() {
        // Only on create
        validatesPresenceOf("password", when="onCreate");

        // Only on update
        validatesPresenceOf("currentPassword", when="onUpdate");

        // Custom condition
        validatesPresenceOf("parentId", condition="this.type == 'child'");

        // Multiple conditions
        validatesLengthOf(
            property="bio",
            maximum=500,
            condition="this.isPublic && this.profileComplete"
        );
    }
}
```

### Unless Conditions
```cfm
component extends="Model" {
    function config() {
        // Skip validation unless condition is true
        validatesPresenceOf("companyName", unless="this.isIndividual");
        validatesPresenceOf("taxId", unless="this.isExempt");

        // Complex unless condition
        validatesNumericalityOf(
            property="discount",
            greaterThan=0,
            unless="this.discountType == 'none'"
        );
    }
}
```

## Custom Validations

### Method-based Custom Validations
```cfm
component extends="Model" {
    function config() {
        // Custom validation methods
        validate(method="validateAge");
        validate(method="validateCreditCard", when="onCreate");
        validate(method="validateBusinessHours");
        validate(method="validatePasswordStrength", when="onCreate");
    }

    /**
     * Custom validation: Age must be reasonable
     */
    private void function validateAge() {
        if (this.age < 13 || this.age > 120) {
            addError(property="age", message="Age must be between 13 and 120");
        }
    }

    /**
     * Custom validation: Credit card format
     */
    private void function validateCreditCard() {
        if (len(this.creditCardNumber)) {
            local.cleaned = reReplace(this.creditCardNumber, "[^\d]", "", "all");

            // Basic length check
            if (len(local.cleaned) < 13 || len(local.cleaned) > 19) {
                addError(property="creditCardNumber", message="Invalid credit card number");
                return;
            }

            // Luhn algorithm check
            if (!passesLuhnCheck(local.cleaned)) {
                addError(property="creditCardNumber", message="Invalid credit card number");
            }
        }
    }

    /**
     * Custom validation: Business hours format
     */
    private void function validateBusinessHours() {
        if (len(this.businessHours)) {
            // Expected format: "09:00-17:00"
            if (!reFindNoCase("^\d{2}:\d{2}-\d{2}:\d{2}$", this.businessHours)) {
                addError(property="businessHours", message="Business hours must be in format HH:MM-HH:MM");
            }
        }
    }

    /**
     * Custom validation: Password strength
     */
    private void function validatePasswordStrength() {
        if (len(this.password)) {
            local.errors = [];

            // Check length
            if (len(this.password) < 8) {
                arrayAppend(local.errors, "must be at least 8 characters long");
            }

            // Check for uppercase letter
            if (!reFindNoCase("[A-Z]", this.password)) {
                arrayAppend(local.errors, "must contain at least one uppercase letter");
            }

            // Check for lowercase letter
            if (!reFindNoCase("[a-z]", this.password)) {
                arrayAppend(local.errors, "must contain at least one lowercase letter");
            }

            // Check for number
            if (!reFindNoCase("[0-9]", this.password)) {
                arrayAppend(local.errors, "must contain at least one number");
            }

            // Check for special character
            if (!reFindNoCase("[^A-Za-z0-9]", this.password)) {
                arrayAppend(local.errors, "must contain at least one special character");
            }

            if (arrayLen(local.errors)) {
                addError(property="password", message="Password #arrayToList(local.errors, ', ')#");
            }
        }
    }

    /**
     * Helper: Luhn algorithm for credit card validation
     */
    private boolean function passesLuhnCheck(required string number) {
        local.sum = 0;
        local.alternate = false;

        for (local.i = len(arguments.number); local.i >= 1; local.i--) {
            local.digit = val(mid(arguments.number, local.i, 1));

            if (local.alternate) {
                local.digit *= 2;
                if (local.digit > 9) {
                    local.digit -= 9;
                }
            }

            local.sum += local.digit;
            local.alternate = !local.alternate;
        }

        return (local.sum % 10) == 0;
    }
}
```

### Inline Custom Validations
```cfm
component extends="Model" {
    function config() {
        // Inline validation using closure
        validate(
            property="email",
            method=function() {
                if (len(this.email) && listFind("@tempmail.com,@fake.com", listLast(this.email, "@"))) {
                    addError(property="email", message="Temporary email addresses not allowed");
                }
            }
        );
    }
}
```

## Validation Lifecycle and Methods

### Validation Checking Methods
```cfm
// Check if model is valid
user = model("User").new(params.user);
if (user.valid()) {
    user.save();
} else {
    // Handle validation errors
    errors = user.allErrors();
}

// Check for specific property errors
if (user.hasErrors("email")) {
    emailErrors = user.errorsOn("email");
}

// Get all error messages
allErrors = user.allErrors();

// Get errors for specific property
emailErrors = user.errorsOn("email");

// Add custom error
user.addError(property="custom", message="Custom error message");
```

### Validation Context
```cfm
// Validate in specific context
user.valid(mode="onCreate");
user.valid(mode="onUpdate");

// Skip validations
user.save(validate=false);

// Validate without saving
if (user.valid()) {
    // Proceed with business logic
}
```

## Advanced Validation Patterns

### Conditional Validation Based on Other Fields
```cfm
component extends="Model" {
    function config() {
        validate(method="validateShippingInfo");
    }

    private void function validateShippingInfo() {
        if (this.requiresShipping) {
            if (!len(this.shippingAddress)) {
                addError(property="shippingAddress", message="Shipping address is required");
            }
            if (!len(this.shippingMethod)) {
                addError(property="shippingMethod", message="Shipping method is required");
            }
        }
    }
}
```

### Cross-Model Validation
```cfm
component extends="Model" {
    function config() {
        validate(method="validateOrderItems");
    }

    private void function validateOrderItems() {
        local.items = this.orderItems();

        if (local.items.recordCount == 0) {
            addError(message="Order must have at least one item");
        }

        // Check inventory for each item
        for (local.item in local.items) {
            if (local.item.quantity > local.item.product().inventory) {
                addError(
                    property="items",
                    message="Insufficient inventory for #local.item.product().name#"
                );
            }
        }
    }
}
```

### Validation Groups
```cfm
component extends="Model" {
    function config() {
        // Basic validations
        validatesPresenceOf("name,email");

        // Extended validations for complete profile
        validate(method="validateCompleteProfile", condition="this.validationGroup == 'complete'");
    }

    private void function validateCompleteProfile() {
        validatesPresenceOf("phone,address,city,state,zipCode");
        validatesLengthOf(property="bio", minimum=50);
    }
}

// Usage
user.validationGroup = "complete";
if (user.valid()) {
    // Complete profile validation passed
}
```

## Error Handling and Display

### Controller Error Handling
```cfm
// In controller
function create() {
    user = model("User").new(params.user);

    if (user.save()) {
        redirectTo(route="user", key=user.id, success="User created successfully!");
    } else {
        // Store model with errors for view
        renderView(action="new");
    }
}
```

### View Error Display
```cfm
<!-- Display all errors for object -->
#errorMessagesFor("user")#

<!-- Display errors for specific property -->
#errorMessageOn(objectName="user", property="email")#

<!-- Manual error display -->
<cfif user.hasErrors()>
    <div class="alert alert-danger">
        <h4>Please correct the following errors:</h4>
        <ul>
            <cfloop array="#user.allErrors()#" index="error">
                <li>#error.message#</li>
            </cfloop>
        </ul>
    </div>
</cfif>

<!-- Property-specific error styling -->
<div class="form-group <cfif user.hasErrors('email')>has-error</cfif>">
    #label(objectName="user", property="email")#
    #textField(objectName="user", property="email", class="form-control")#
    #errorMessageOn(objectName="user", property="email")#
</div>
```

## Testing Validations

### Validation Test Examples
```cfm
component extends="tests.Test" {

    function testValidatesPresenceOfName() {
        user = model("User").new();
        assert(!user.valid(), "User should be invalid without name");
        assert(user.hasErrors("name"), "User should have name error");
    }

    function testValidatesEmailFormat() {
        user = model("User").new(name="John", email="invalid-email");
        assert(!user.valid(), "User should be invalid with bad email");
        assert(user.hasErrors("email"), "User should have email format error");

        user.email = "john@example.com";
        assert(user.valid(), "User should be valid with good email");
    }

    function testValidatesUniquenessOfEmail() {
        // Create first user
        user1 = model("User").create(name="John", email="john@example.com");
        assert(user1.valid(), "First user should be valid");

        // Try to create second user with same email
        user2 = model("User").new(name="Jane", email="john@example.com");
        assert(!user2.valid(), "Second user should be invalid with duplicate email");
        assert(user2.hasErrors("email"), "Second user should have email uniqueness error");
    }

    function testCustomPasswordValidation() {
        user = model("User").new(name="John", email="john@example.com");

        // Test weak password
        user.password = "weak";
        assert(!user.valid(), "User should be invalid with weak password");
        assert(user.hasErrors("password"), "User should have password strength error");

        // Test strong password
        user.password = "StrongPass123!";
        assert(user.valid(), "User should be valid with strong password");
    }

    function testConditionalValidation() {
        order = model("Order").new(requiresShipping=false);
        assert(order.valid(), "Order should be valid without shipping when not required");

        order.requiresShipping = true;
        assert(!order.valid(), "Order should be invalid without shipping when required");

        order.shippingAddress = "123 Main St";
        order.shippingMethod = "standard";
        assert(order.valid(), "Order should be valid with shipping info when required");
    }
}
```

## Common Validation Patterns

### User Registration
```cfm
component extends="Model" {
    function config() {
        validatesPresenceOf("username,email,password");
        validatesUniquenessOf("username,email");
        validatesLengthOf(property="username", minimum=3, maximum=50);
        validatesLengthOf(property="password", minimum=8);
        validatesFormatOf(property="email", with="^[^\s@]+@[^\s@]+\.[^\s@]+$");
        validatesConfirmationOf("password");
        validate(method="validatePasswordStrength");
        validate(method="validateUsernameFormat");
    }
}
```

### Product Catalog
```cfm
component extends="Model" {
    function config() {
        validatesPresenceOf("name,price,categoryid");
        validatesNumericalityOf("price", greaterThan=0);
        validatesNumericalityOf("weight", greaterThan=0, allowBlank=true);
        validatesLengthOf(property="name", minimum=3, maximum=255);
        validatesUniquenessOf("sku", allowBlank=true);
        validatesInclusionOf(property="status", in="active,inactive,discontinued");
    }
}
```

### Content Management
```cfm
component extends="Model" {
    function config() {
        validatesPresenceOf("title,content,authorid");
        validatesLengthOf(property="title", minimum=5, maximum=255);
        validatesLengthOf(property="content", minimum=50);
        validatesUniquenessOf("slug");
        validatesInclusionOf(property="status", in="draft,published,archived");
        validate(method="validatePublishDate");
        validate(method="validateSlugFormat");
    }
}
```

## Best Practices

1. **Use Built-in Validations**: Prefer built-in validations over custom ones when possible
2. **Consistent Error Messages**: Use clear, consistent error messages across your application
3. **Conditional Validations**: Use conditional validations for complex business rules
4. **Test Thoroughly**: Write comprehensive tests for all validation scenarios
5. **Group Related Validations**: Organize validations logically in the config() method
6. **Performance**: Custom validations should be efficient, especially for large datasets
7. **User Experience**: Provide helpful error messages that guide users to correct input

## Related Documentation
- [Model Architecture](./architecture.md)
- [Model Callbacks](./callbacks.md)
- [User Authentication](./user-authentication.md)
- [Form Helpers](../../views/helpers/forms.md)