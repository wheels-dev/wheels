# TestBox Migration Cheat Sheet

This quick reference guide helps you migrate from RocketUnit to TestBox syntax in Wheels 3.0.

## Component Structure

| RocketUnit | TestBox |
|------------|---------|
| `component extends="tests.Test"` | `component extends="testbox.system.BaseSpec"` |
| Test methods start with `test` | Test methods wrapped in `it()` blocks |
| Methods run in order | Tests can be organized with `describe()` |

### Basic Structure Migration

**RocketUnit:**
```cfc
component extends="tests.Test" {
	function testSomething() {
		// test code
	}
}
```

**TestBox:**
```cfc
component extends="testbox.system.BaseSpec" {
	function run() {
		describe("Feature", () => {
			it("should do something", () => {
				// test code
			});
		});
	}
}
```

## Assertion Mappings

### Basic Assertions

| RocketUnit | TestBox | Notes |
|------------|---------|-------|
| `assert("expression")` | `expect(expression).toBeTrue()` | For boolean true |
| `assert("!expression")` | `expect(expression).toBeFalse()` | For boolean false |
| `assert(expression)` | `expect(expression).toBeTrue()` | Without quotes |

### Equality Assertions

| RocketUnit | TestBox |
|------------|---------|
| `assert("a == b")` | `expect(a).toBe(b)` |
| `assert("a eq b")` | `expect(a).toBe(b)` |
| `assert("a != b")` | `expect(a).notToBe(b)` |
| `assert("a neq b")` | `expect(a).notToBe(b)` |
| `assert("a === b")` | `expect(a).toBeSameInstance(b)` |

### Comparison Assertions

| RocketUnit | TestBox |
|------------|---------|
| `assert("a > b")` | `expect(a).toBeGT(b)` |
| `assert("a gt b")` | `expect(a).toBeGT(b)` |
| `assert("a >= b")` | `expect(a).toBeGTE(b)` |
| `assert("a < b")` | `expect(a).toBeLT(b)` |
| `assert("a lt b")` | `expect(a).toBeLT(b)` |
| `assert("a <= b")` | `expect(a).toBeLTE(b)` |

### Type Checking

| RocketUnit | TestBox |
|------------|---------|
| `assert("isArray(x)")` | `expect(x).toBeArray()` |
| `assert("isStruct(x)")` | `expect(x).toBeStruct()` |
| `assert("isNumeric(x)")` | `expect(x).toBeNumeric()` |
| `assert("isBoolean(x)")` | `expect(x).toBeBoolean()` |
| `assert("isDate(x)")` | `expect(x).toBeDate()` |
| `assert("isObject(x)")` | `expect(x).toBeComponent()` |
| `assert("isSimpleValue(x)")` | `expect(x).toBeString()` |

### String and Collection Assertions

| RocketUnit | TestBox |
|------------|---------|
| `assert("len(str) == 5")` | `expect(str).toHaveLength(5)` |
| `assert("arrayLen(arr) == 3")` | `expect(arrayLen(arr)).toBe(3)` |
| `assert("listLen(lst) == 2")` | `expect(listLen(lst)).toBe(2)` |
| `assert("str contains 'text'")` | `expect(str).toInclude('text')` |
| `assert("find('text', str)")` | `expect(str).toInclude('text')` |
| `assert("str == ''")` | `expect(str).toBeEmpty()` |
| `assert("arrayIsEmpty(arr)")` | `expect(arr).toBeEmpty()` |

### Structure/Object Assertions

| RocketUnit | TestBox |
|------------|---------|
| `assert("structKeyExists(obj, 'key')")` | `expect(obj).toHaveKey('key')` |
| `assert("structIsEmpty(obj)")` | `expect(obj).toBeEmpty()` |
| `assert("structCount(obj) == 5")` | `expect(structCount(obj)).toBe(5)` |
| `assert("isDefined('variable')")` | `expect(variables).toHaveKey('variable')` |

### Exception Testing

| RocketUnit | TestBox |
|------------|---------|
| Try/catch with assert | `expect(() => { code }).toThrow()` |
| Check exception type | `expect(() => { code }).toThrow("ExceptionType")` |
| Check exception message | `expect(() => { code }).toThrow(regex="pattern")` |

## Lifecycle Methods

| RocketUnit | TestBox | Scope |
|------------|---------|-------|
| `function setup()` | `beforeEach(() => {})` | Before each test |
| `function teardown()` | `afterEach(() => {})` | After each test |
| `function beforeTests()` | `beforeAll(() => {})` | Before all tests in describe |
| `function afterTests()` | `afterAll(() => {})` | After all tests in describe |

## Wheels-Specific Helpers

### Model Testing

| Operation | TestBox with BaseSpec |
|-----------|----------------------|
| Create model | `var user = model("User").new()` |
| Create and save | `var user = create("user")` |
| Build without saving | `var user = build("user")` |
| Create multiple | `var users = createList("user", 5)` |
| Check validation | `expect(user.valid()).toBeFalse()` |
| Check errors | `assertHasErrors(user, "email")` |

### Controller Testing

| Operation | TestBox with BaseSpec |
|-----------|----------------------|
| Get controller | `var ctrl = controller("Users")` |
| Process request | `var result = processRequest(route="users", method="GET")` |
| Set params | `params({id: 1, format: "json"})` |
| Check redirect | `assertRedirected(ctrl, "/users")` |
| Check render | `assertRendered(ctrl, "index")` |

### Authentication Testing

| Operation | TestBox with BaseSpec |
|-----------|----------------------|
| Login as user | `loginAs(userId)` |
| Logout | `logout()` |
| Check login | `expect(isLoggedIn()).toBeTrue()` |

## Common Migration Patterns

### Pattern 1: Simple Test Migration

**Before:**
```cfc
function test_userValidation() {
	var user = model("User").new();
	user.email = "";
	assert("!user.valid()");
	assert("structKeyExists(user.errors(), 'email')");
}
```

**After:**
```cfc
it("should validate user email", () => {
	var user = model("User").new();
	user.email = "";
	expect(user.valid()).toBeFalse();
	expect(user.errors()).toHaveKey("email");
});
```

### Pattern 2: Exception Testing

**Before:**
```cfc
function test_divisionByZero() {
	var passed = false;
	try {
		var result = 10 / 0;
	} catch (any e) {
		passed = true;
	}
	assert("passed");
}
```

**After:**
```cfc
it("should throw on division by zero", () => {
	expect(() => {
		var result = 10 / 0;
	}).toThrow();
});
```

### Pattern 3: Complex Assertions

**Before:**
```cfc
function test_userList() {
	var users = model("User").findAll();
	assert("isArray(users) and arrayLen(users) > 0");
}
```

**After:**
```cfc
it("should return array of users", () => {
	var users = model("User").findAll();
	expect(users).toBeArray();
	expect(arrayLen(users)).toBeGT(0);
});
```

## Assertions Requiring Manual Review

These patterns need manual conversion:

1. **Complex AND/OR logic**
   - `assert("a > 0 and b < 10")` → Split into multiple expectations
   
2. **Evaluate expressions**
   - `assert("evaluate(dynamicCode)")` → Refactor to avoid evaluate

3. **Custom assertions**
   - Create custom matchers or use `expect().toSatisfy()`

## Quick CLI Commands

```bash
# Migrate a single file
wheels test migrate path/to/test.cfc

# Migrate with backup
wheels test migrate path/to/test.cfc --backup

# Dry run (preview changes)
wheels test migrate path/to/test.cfc --dry-run

# Migrate entire directory
wheels test migrate tests/ --recursive

# Generate migration report
wheels test migrate tests/ --report
```

## Tips for Successful Migration

1. **Start with a dry run** to preview changes
2. **Always backup** your test files before migration
3. **Run tests immediately** after migration to catch issues
4. **Review warnings** for complex assertions that need manual attention
5. **Update test names** to be more descriptive using BDD style
6. **Group related tests** using `describe()` blocks
7. **Use factories** for consistent test data generation

## Need Help?

- Run `wheels test migrate --help` for CLI options
- Check the [full TestBox documentation](https://testbox.ortusbooks.com/)
- See the [Wheels testing guide](/docs/testing-with-testbox.md) for detailed examples