# Hash/Pound Sign Escaping in CFML

## Overview
In CFML, the hash symbol (#) has special meaning for variable interpolation and evaluation. When you need to use a literal hash symbol (such as in CSS colors, HTML anchors, or other contexts), you must escape it by doubling it (##).

## The Rule
**Single # = Variable evaluation**
**Double ## = Literal hash symbol**

## Syntax
```cfml
// Variable interpolation (single #)
name = "John";
message = "Hello #name#!";  // Outputs: Hello John!

// Literal hash symbol (double ##)
color = "##FF0000";  // Outputs: #FF0000
```

## When Hash Escaping is Required

### 1. CSS Color Values
```cfml
<cfscript>
// Wrong - CFML tries to evaluate #FFF as a variable
badColor = "#FFF";  // Error: Variable FFF is undefined

// Correct - Double ## creates literal #
goodColor = "##FFF";  // Outputs: #FFF
backgroundColor = "##333333";  // Outputs: #333333
</cfscript>

// In cfoutput blocks
<cfoutput>
<style>
    body { background-color: ##e0e0e0; }
    .highlight { color: ##ff6600; }
</style>
</cfoutput>
```

### 2. HTML Anchors and Fragment Identifiers
```cfml
<cfscript>
// Anchor links
anchorLink = '<a href="##section1">Go to Section 1</a>';

// Fragment identifiers
fragmentUrl = "page.cfm##top";
</cfscript>

<cfoutput>
<a href="##contact">Contact Section</a>
<div id="contact">...</div>
</cfoutput>
```

### 3. JavaScript and CSS in CFML Blocks
```cfml
<cfoutput>
<script>
    // Hash in JavaScript strings within CFML
    var elementId = "##myElement";
    document.querySelector("##navbar").style.display = "block";

    // Hash in regular expressions
    var hashRegex = /##[\w]+/g;
</script>

<style>
    ##header { margin-top: 20px; }
    .class##variation { color: ##blue; }
</style>
</cfoutput>
```

### 4. URL Parameters and Query Strings
```cfml
<cfscript>
// URL with fragment
redirectUrl = "dashboard.cfm?tab=overview##results";

// Social media sharing URLs
twitterUrl = "https://twitter.com/intent/tweet?hashtags=cfml&text=Learning##CFML";
</cfscript>
```

### 5. Regular Expressions
```cfml
<cfscript>
// Hash symbols in regex patterns
hashtagPattern = "##\w+";  // Matches hashtags like #cfml
colorPattern = "##[0-9A-Fa-f]{6}";  // Matches hex colors like #FF0000

// Using reFind with hash patterns
text = "Check out #CFML and #WebDev";
hashTags = reFind("##\w+", text, 1, true);
</cfscript>
```

### 6. Database Queries with Hash Values
```cfml
<cfscript>
// Inserting literal hash values into database
colorCode = "##FF5733";
queryExecute(
    "INSERT INTO colors (name, hex_value) VALUES (?, ?)",
    ["Orange", colorCode]
);

// Hash in SQL comments (less common)
sql = "
    SELECT * FROM products
    -- This query filters by color ##FF0000
    WHERE color_hex = ?
";
</cfscript>
```

## Context-Dependent Escaping

### In CFScript
```cfml
<cfscript>
// Always double ## for literal hash
cssColor = "##336699";
jsSelector = "##elementId";
htmlAnchor = '<a href="##top">Top</a>';
</cfscript>
```

### In Tag Attributes
```cfml
<!-- In tag attributes, escaping is usually required -->
<cfset linkUrl = "page.cfm##section">
<cfset cssClass = "color-##ff0000">

<!-- In cfoutput, definitely required -->
<cfoutput>
<div style="background: ##f5f5f5;">Content</div>
</cfoutput>
```

### In String Literals vs. Output Blocks
```cfml
<cfscript>
// In string assignments - double ##
colorVar = "##red";
anchorVar = "##top";
</cfscript>

<!-- In output blocks - double ## -->
<cfoutput>
<style>
    .main { color: ##333; }
</style>
</cfoutput>

<!-- Outside CFML processing - single # is fine -->
<style>
    .static { color: #333; }
</style>
```

## Common Mistakes and Solutions

### Mistake 1: Forgetting to Escape in Strings
```cfml
<cfscript>
// Wrong - Will cause "Variable FFF is undefined" error
// color = "#FFF";

// Correct
color = "##FFF";
</cfscript>
```

### Mistake 2: Over-escaping Outside CFML Context
```cfml
<!-- Wrong - Double escaping where not needed -->
<!-- <style>
    body { color: ##333; }  /* This will output ##333 literally */
</style> -->

<!-- Correct - No CFML processing here -->
<style>
    body { color: #333; }
</style>

<!-- But in cfoutput blocks, you DO need escaping -->
<cfoutput>
<style>
    body { color: ##333; }  /* This correctly outputs #333 */
</style>
</cfoutput>
```

### Mistake 3: Mixed Variable and Literal Usage
```cfml
<cfscript>
userId = 123;
// Combining variable interpolation with literal hash
userUrl = "profile.cfm?id=#userId###details";
// Output: profile.cfm?id=123#details
</cfscript>
```

## Complex Examples

### CSS with CFML Variables
```cfml
<cfscript>
primaryColor = "##2c3e50";
secondaryColor = "##ecf0f1";
fontSize = 16;
</cfscript>

<cfoutput>
<style>
    .theme-primary {
        background-color: #primaryColor#;
        color: #secondaryColor#;
        font-size: #fontSize#px;
        border: 1px solid ##ddd;  /* Literal gray border */
    }

    ##header { /* Literal ID selector */
        background: linear-gradient(to right, #primaryColor#, ##ffffff);
    }
</style>
</cfoutput>
```

### JavaScript with Mixed Hash Usage
```cfml
<cfscript>
modalId = "confirmModal";
</cfscript>

<cfoutput>
<script>
    // Variable interpolation for ID
    var modal = document.getElementById("#modalId#");

    // Literal hash for CSS selectors in JavaScript
    var header = document.querySelector("##header");
    var navItems = document.querySelectorAll("##navbar .nav-item");

    // Hash in object keys or values
    var config = {
        theme: "#primaryColor#",
        anchor: "##main-content"
    };
</script>
</cfoutput>
```

### URL Building with Fragments
```cfml
<cfscript>
page = "dashboard";
section = "reports";
userId = session.userId;

// Building URL with query params and fragment
dashboardUrl = "#page#.cfm?user=#userId###section#";
// Output: dashboard.cfm?user=123#reports

// Social sharing URL with hashtags
shareText = "Check out this CFML framework!";
twitterUrl = "https://twitter.com/intent/tweet?text=#urlEncodedFormat(shareText)#&hashtags=cfml,webdev";
</cfscript>
```

## Best Practices

### 1. Consistency in Escaping
- Always double ## when you need a literal hash symbol in CFML-processed content
- Be consistent across your codebase

### 2. Context Awareness
- Understand whether your code is in a CFML-processed context
- Static HTML/CSS/JS files don't need hash escaping
- Dynamic content within `<cfoutput>` or CFScript strings does need escaping

### 3. Testing Hash-Heavy Content
```cfml
<cfscript>
// When working with lots of hash symbols, test thoroughly
cssContent = "
    ##main { background: ##f0f0f0; }
    ##sidebar { border: 1px solid ##ccc; }
    .highlight { color: ##ff6600; }
";

// Verify output matches expectations
writeOutput(htmlCodeFormat(cssContent));
</cfscript>
```

### 4. Documentation
- Comment your code when mixing variable interpolation with literal hashes
- Make intent clear for future maintainers

## Key Points
- **Single #** triggers variable evaluation in CFML
- **Double ##** produces a literal hash symbol
- Escaping is required in CFML-processed contexts (CFScript strings, cfoutput blocks)
- Static HTML/CSS/JavaScript files don't require hash escaping
- Common use cases: CSS colors, HTML anchors, JavaScript selectors, URLs with fragments
- Test thoroughly when mixing variable interpolation with literal hash symbols

## Related Concepts
- [Variable Interpolation](../data-types/variables.md)
- [String Literals](../data-types/strings/string-literals.md)
- [CFScript vs Tags](./cfscript-vs-tags.md)