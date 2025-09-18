# Date and Time Helpers

## Description
Format and display dates, times, and relative time information in views with consistent formatting.

## Key Points
- Built-in date and time formatting functions
- Relative time display (time ago, distance of time)
- Customizable format masks
- Timezone handling support
- Consistent date presentation across application

## Code Sample
```cfm
<cfoutput>
<!-- Basic date formatting -->
#dateFormat(user.createdAt, "mm/dd/yyyy")#
#timeFormat(user.lastLoginAt, "h:mm tt")#

<!-- Relative time display -->
#distanceOfTimeInWords(user.createdAt, Now())# <!-- "3 days ago" -->
#timeAgoInWords(user.lastLoginAt)# <!-- "2 hours ago" -->

<!-- Custom date formats -->
#dateFormat(post.publishedAt, "mmmm dd, yyyy")# <!-- "January 15, 2024" -->
#dateFormat(event.startDate, "dddd, mmmm dd")# <!-- "Monday, March 25" -->

<!-- Date and time combined -->
#dateTimeFormat(comment.createdAt, "mm/dd/yyyy h:nn tt")#

<!-- Conditional date display -->
<cfif IsDate(user.lastLoginAt)>
    Last login: #timeAgoInWords(user.lastLoginAt)#
<cfelse>
    Never logged in
</cfif>

<!-- Formatted date ranges -->
<cfif DateCompare(event.startDate, event.endDate) EQ 0>
    #dateFormat(event.startDate, "mmmm dd, yyyy")#
<cfelse>
    #dateFormat(event.startDate, "mmmm dd")# - #dateFormat(event.endDate, "dd, yyyy")#
</cfif>

<!-- ISO 8601 dates for HTML5/JavaScript -->
<time datetime="#dateFormat(post.createdAt, 'yyyy-mm-dd')#">
    #timeAgoInWords(post.createdAt)#
</time>

<!-- Timezone considerations -->
#dateFormat(DateConvert("utc2Local", user.createdAt), "mm/dd/yyyy h:nn tt")#
</cfoutput>
```

## Usage
1. Use `dateFormat()` for date-only formatting
2. Use `timeFormat()` for time-only formatting
3. Use `timeAgoInWords()` for relative time display
4. Use `distanceOfTimeInWords()` to compare two dates
5. Apply timezone conversions when needed

## Related
- [Custom Helpers](./custom.md)
- [Form Helpers](./forms.md)
- [Automatic Time Stamps](../../database/automatic-time-stamps.md)

## Important Notes
- Check for valid dates with `IsDate()` before formatting
- Consider timezone differences in global applications
- Use relative time for recent activities
- Consistent date formats improve user experience
- HTML5 `<time>` elements improve accessibility