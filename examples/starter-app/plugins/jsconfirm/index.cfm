<cfoutput>

<h1>JS Confirm #application.wheels.pluginMeta["jsConfirm"]["version"]#</h1>
<p>Adds a <code>confirm</code> argument to <code>buttonTo()</code> and <code>linkTo()</code> so you can show a JavaScript confirmation prompt.</p>

<p><strong>Usage Examples</strong></p>
<pre>
  ##buttonTo(text="Delete", action="deleteIt", confirm="Are you sure?")##
</pre>
<pre>
  ##linkTo(text="Click", action="doClick", confirm="Are you sure?")##
</pre>

</cfoutput>