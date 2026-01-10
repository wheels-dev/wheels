<!---
	The Footer
	Uses getSetting() for copyright and year(now()) for the current year.
	No container needed here as the layout provides it.
--->
<cfoutput>
<footer class="bg-light border-top text-center py-4 mt-5 small text-muted w-100">
    <span>#getSetting('general_copyright')# &copy; #year(now())#</span>
</footer>
</cfoutput>
