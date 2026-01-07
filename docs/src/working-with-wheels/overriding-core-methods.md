## Overriding Core Wheels Methods (Wheels 3.x)

In Wheels 2.5, developers could override core framework methods (such as `findAll`) in their models and call the original Wheels implementation using the `super` scope.

Due to internal framework restructuring in Wheels 3.0, this behavior no longer works using the traditional `super.methodName()` syntax. To restore this capability in a predictable and explicit way, Wheels now provides a new **`super`-prefixed method convention**.

---

### Wheels 2.5 Behavior

In Wheels 2.5, overriding a core model method and calling the original implementation looked like this:

```javascript
component extends="Model" {

    function findAll() {
        // custom logic here

        return super.findAll();
    }

}
```

This worked because Wheels core methods were directly accessible via the `super` scope.

---

### Why This Changed in Wheels 3.0

Wheels 3.0 introduced a significant internal reorganization of the framework to support:

- improved extensibility
- cleaner separation of concerns
- better compatibility with multiple runtimes

As a result, calling core methods using `super.methodName()` is no longer reliable or supported in the same way.

---

### New Approach in Wheels 3.0+

To override a core Wheels method and still call the original implementation, you now use a **`super`-prefixed method name**.

Instead of calling:

```
super.findAll()
```

You call:

```
superFindAll()
```

---

### Example: Overriding `findAll()`

```javascript
component extends="Model" {

    function findAll() {
        // custom logic before calling Wheels core method

        return superFindAll();
    }

}
```

This allows you to:

- safely override any core Wheels method
- explicitly call the original Wheels implementation
- avoid framework internals or brittle inheritance behavior

---

### Key Notes

- The `superMethodName()` convention applies only when overriding a core Wheels method
- Method names are case-insensitive, following normal CFML rules
- This behavior is available in Wheels 3.x and later
- No changes are required for applications that do not override core methods

---

### Migration Tip for Wheels 2.5 Applications

If you are upgrading an application from Wheels 2.5 to 3.0+ and have overridden core methods:

1. Search for usages of `super.methodName()`
2. Replace them with `superMethodName()`
3. Test overridden behavior to ensure expected results

This small change restores the same extension capability that existed in Wheels 2.5, while remaining compatible with the updated framework architecture.