# Wheels Form Helper Common Errors

## Critical Anti-Pattern: submitTag Parameter Issues

### ❌ **The Problem**
```cfm
<!-- This causes "Missing argument name" error -->
#submitTag("Post Comment", class="btn")#
#submitTag("Save", name="draft", class="btn")#
```

**Error Message:** `Missing argument name, when using named parameters to a function, every parameter must have a name`

### ✅ **The Solution**
```cfm
<!-- Use 'value' parameter consistently -->
#submitTag(value="Post Comment", class="btn")#
#submitTag(value="Save", name="draft", class="btn")#
```

## Why This Happens
Wheels requires **consistent parameter syntax** - either all positional or all named parameters. The `submitTag()` function expects the first parameter to be named `value=` when using named parameters.

## Other Form Helper Patterns

### ✅ **Correct Patterns**
```cfm
<!-- Text fields -->
#textField(objectName="post", property="title", class="form-control")#
#textArea(objectName="post", property="content", rows="10", class="form-control")#

<!-- Checkboxes -->
#checkBox(objectName="post", property="published", class="form-check")#

<!-- Select fields -->
#select(objectName="post", property="categoryId", options=categories, class="form-select")#

<!-- Hidden fields -->
#hiddenFieldTag(name="postId", value=post.id)#

<!-- Submit buttons (key insight from session) -->
#submitTag(value="Save Post", class="btn btn-primary")#
#submitTag(value="Delete", confirm="Are you sure?", class="btn btn-danger")#
```

### ❌ **Anti-Patterns to Avoid**
```cfm
<!-- Mixed parameter styles -->
#textField("post", "title", class="form-control")#  <!-- Don't mix positional and named -->

<!-- Missing 'value' parameter -->
#submitTag("Save", class="btn")#  <!-- Use value="Save" instead -->

<!-- Non-existent helpers -->
#emailField()#       <!-- Use textField(type="email") -->
#passwordField()#    <!-- Use textField(type="password") -->
```

## Form Structure Best Practices

### Complete Form Example
```cfm
#startFormTag(controller="posts", action="create", method="post")#
    #hiddenFieldTag("authenticityToken", authenticityToken())#

    <div class="form-group">
        #textField(objectName="post", property="title", label="Title", class="form-control")#
        #errorMessageOn(objectName="post", property="title", class="error-message")#
    </div>

    <div class="form-group">
        #textArea(objectName="post", property="content", label="Content", rows="10", class="form-control")#
        #errorMessageOn(objectName="post", property="content", class="error-message")#
    </div>

    <div class="form-actions">
        #submitTag(value="Create Post", class="btn btn-primary")#
        #linkTo(controller="posts", action="index", text="Cancel", class="btn btn-secondary")#
    </div>
#endFormTag()#
```

## Debugging Form Errors

### Common Error Messages and Solutions

1. **"Missing argument name"**
   - **Cause**: Mixed positional and named parameters
   - **Fix**: Use consistent parameter syntax

2. **"Function [HELPER] not found"**
   - **Cause**: Using non-existent helper functions
   - **Fix**: Check Wheels documentation for available helpers

3. **"Parameter [PROPERTY] is required"**
   - **Cause**: Missing required parameters
   - **Fix**: Ensure all required parameters are provided

### Best Practices for Form Development

1. **Always use named parameters** for consistency
2. **Include CSRF protection** with `hiddenFieldTag("authenticityToken", authenticityToken())`
3. **Add error handling** with `errorMessageOn()` for each field
4. **Use semantic HTML** classes for styling
5. **Test forms thoroughly** after any helper changes

## Integration with Modern CSS Frameworks

### Tailwind CSS Integration
```cfm
#textField(objectName="post", property="title",
          class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500")#

#submitTag(value="Save Post",
          class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md font-medium transition-colors")#
```

### Bootstrap Integration
```cfm
#textField(objectName="post", property="title", class="form-control")#
#submitTag(value="Save Post", class="btn btn-primary")#
```

This pattern was discovered during a real Wheels blog development session and prevented multiple form submission errors.