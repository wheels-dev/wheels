# Custom View Helpers

## Description
Create reusable view helper functions to reduce code duplication and standardize common formatting across your application.

## Key Points
- Create helper functions in `/app/global/functions.cfm`
- Available in all views automatically
- Keep presentation logic out of controllers
- Encapsulate complex formatting and display logic
- Support parameters for flexibility

## Code Sample
```cfm
<!-- /app/global/functions.cfm -->
<cfscript>
    // Format currency with consistent styling
    function formatCurrency(required numeric amount) {
        return DollarFormat(arguments.amount);
    }

    // Display user avatar with fallback
    function userAvatar(required user, size="medium") {
        local.sizes = {small: 32, medium: 64, large: 128};
        local.imageSize = local.sizes[arguments.size];

        if (Len(arguments.user.avatarUrl)) {
            return '<img src="#arguments.user.avatarUrl#" width="#local.imageSize#" height="#local.imageSize#" alt="#arguments.user.fullName()#" class="avatar avatar-#arguments.size#">';
        } else {
            return '<div class="avatar avatar-#arguments.size# avatar-placeholder">#Left(arguments.user.firstName, 1)##Left(arguments.user.lastName, 1)#</div>';
        }
    }

    // Format status badges
    function statusBadge(required string status) {
        local.classes = {
            active: "badge-success",
            inactive: "badge-secondary",
            pending: "badge-warning",
            suspended: "badge-danger"
        };

        local.class = local.classes[arguments.status] ?: "badge-primary";
        return '<span class="badge #local.class#">#UCase(arguments.status)#</span>';
    }

    // Truncate text with ellipsis
    function truncate(required string text, length=100, suffix="...") {
        if (Len(arguments.text) <= arguments.length) {
            return arguments.text;
        }
        return Left(arguments.text, arguments.length) & arguments.suffix;
    }

    // Generate breadcrumb navigation
    function breadcrumbs(required array items) {
        local.output = '<nav aria-label="breadcrumb"><ol class="breadcrumb">';

        for (local.i = 1; local.i <= ArrayLen(arguments.items); local.i++) {
            local.item = arguments.items[local.i];
            local.isLast = (local.i == ArrayLen(arguments.items));

            local.output &= '<li class="breadcrumb-item' & (local.isLast ? ' active' : '') & '">';
            if (!local.isLast && StructKeyExists(local.item, "url")) {
                local.output &= linkTo(url=local.item.url, text=local.item.text);
            } else {
                local.output &= local.item.text;
            }
            local.output &= '</li>';
        }

        return local.output & '</ol></nav>';
    }
</cfscript>

<!-- Usage in views -->
<cfoutput>
<!-- Currency formatting -->
<p>Price: #formatCurrency(product.price)#</p>

<!-- User avatar -->
#userAvatar(currentUser(), "large")#

<!-- Status badge -->
#statusBadge(user.status)#

<!-- Text truncation -->
<p>#truncate(article.summary, 150)#</p>

<!-- Breadcrumb navigation -->
#breadcrumbs([
    {text: "Home", url: urlFor(action="index")},
    {text: "Users", url: urlFor(controller="users", action="index")},
    {text: user.fullName()}
])#
</cfoutput>
```

## Usage
1. Create helper functions in `/app/global/functions.cfm`
2. Write functions that return formatted HTML or strings
3. Use descriptive function names
4. Support parameters for flexibility
5. Keep presentation logic out of controllers

## Related
- [Form Helpers](./forms.md)
- [Link Helpers](./links.md)
- [Global Functions](../../patterns/service-layer.md)

## Important Notes
- Helpers available in all views automatically
- Keep helpers focused on presentation
- Use HTML encoding for security
- Test helpers thoroughly
- Document complex helper functions