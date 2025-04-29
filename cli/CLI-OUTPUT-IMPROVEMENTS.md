# CLI Output Improvements

This document outlines modernized output styles that can be applied to the Wheels CLI to improve user experience, while still working within the CommandBox environment.

## Current Output Style

The current Wheels CLI uses:
- Basic text output with `print.line()`
- Color formatting with `print.redLine()`, `print.greenLine()`, etc.
- Basic text styling with `print.boldGreenLine()`, etc.
- ASCII tables for tabular data
- Simple progress indicators

## Proposed Improvements

### 1. Consistent Header Structure

```
=============================================
 WHEELS COMMAND NAME
=============================================

Command description goes here...

```

### 2. Emoji Integration for Quick Visual Cues

```
✅ Success: Operation completed successfully
❌ Error: Something went wrong
⚠️ Warning: Proceed with caution
ℹ️ Info: Additional information
🔄 Processing: Operation in progress
```

### 3. Modern Table Display

```
┌─────────────────┬───────────────┬────────────┐
│ PROPERTY        │ TYPE          │ REQUIRED   │
├─────────────────┼───────────────┼────────────┤
│ name            │ string        │ Yes        │
│ description     │ string        │ No         │
└─────────────────┴───────────────┴────────────┘
```

### 4. Improved Progress Indicators

```
⏳ Creating database schema... done
⏳ Generating model files... done
⏳ Updating routes... done

✅ Task completed in 3.45s
```

### 5. Better Error Messages

```
❌ ERROR: Database connection failed

   Possible solutions:
   • Check your database credentials in config/database.yml
   • Ensure your database server is running
   • Verify network connection if using a remote database

   Need help? Visit https://wheels.dev/docs/troubleshooting
```

### 6. Command Completion Summary

```
✅ COMMAND COMPLETED SUCCESSFULLY

  • Created 3 model files
  • Generated 4 views
  • Updated 1 controller
  
  Next steps:
  • Run 'wheels watch' to monitor changes
  • Visit http://localhost:8080 to view your application
```

### 7. More Informative Listings

```
MODELS
  • User (id, email, created_at) → has_many :posts
  • Post (id, title, body, user_id) → belongs_to :user
  • Comment (id, body, post_id) → belongs_to :post
```

### 8. Interactive Tips

```
💡 TIP: You can use 'wheels generate test User' to generate tests for this model
```

### 9. Cleaner Help Text

```
USAGE
  wheels generate model [name] [options]

ARGUMENTS
  name                Name of the model to generate

OPTIONS
  --properties        List of properties (name:type,...)
  --timestamps        Add timestamp fields (default: true)
  --force             Overwrite existing files (default: false)

EXAMPLES
  wheels generate model User
  wheels generate model Post title:string body:text published:boolean
```

### 10. Implementation Approach

These improvements can be implemented through:

1. **Style Helper Class**: Create a StyleHelper component to standardize output styles

```cfml
// Example implementation
component {
  public void function header(required string text) {
    print.boldMagentaLine("=============================================");
    print.boldMagentaLine(" " & uCase(text));
    print.boldMagentaLine("=============================================");
    print.line();
  }
  
  public void function success(required string text) {
    print.boldGreenLine("✅ " & text);
  }
  
  public void function error(required string text) {
    print.boldRedLine("❌ " & text);
  }
  
  // Additional styled methods...
}
```

2. **Table Formatter**: Enhance table display with Unicode box-drawing characters

3. **Progress Tracker**: Add a helper for showing progress across multiple steps

4. **Consistent Color Scheme**:
   - Green: Success, completion
   - Yellow: Warnings, important notes
   - Cyan: Processing, information
   - Magenta: Headers, titles
   - Red: Errors, destructive actions

These improvements will modernize the CLI while maintaining compatibility with CommandBox.