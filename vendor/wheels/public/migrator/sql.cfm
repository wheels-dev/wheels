<cfscript>
param name="request.wheels.params.version" default=0;

// Setting this flag is mega important, otherwise we can't return the SQL, and it will actually execute
request.$wheelsDebugSQL = true;

up = [];
down = [];

// Get available migrations
migrations = application.wheels.migrator.getAvailableMigrations();

request.$wheelsDebugSQLResult = [];

// Get This migration
for (mig in migrations) {
	if (mig["version"] EQ request.wheels.params.version) {
		migration = mig;
	}
}
try {
	// We're going to fake a migration up and down to get the SQL (using redo doesn't let us separate the values easily)
	migration.CFC.up();
	up = request.$wheelsDebugSQLResult;
} catch (any e) {
	up[1] = e.message;
}

// Reset the debug array
request.$wheelsDebugSQLResult = [];

try {
	migration.CFC.down();
} catch (any e) {
	down[1] = e.message;
}
</cfscript>
<!--- cfformat-ignore-start --->
<cfoutput>
	<div class="ui info message">
		<div class="header">Note</div>
		This preview is what this migration file would have executed in the current context. So if you're trying to add a record to a table which doesn't yet exist (for instance), this will correctly throw an error.
	</div>

	<p>
		<strong>Migration Version</strong>
		: <code>#migration.version#</code>
	</p>
	<cfif ArrayLen(up)>
		<h4>Up()</h4>
		<cfloop from="1" to="#ArrayLen(up)#" index="sql">
			<pre>
				<code class="sql hljs">#up[sql]#</code>
			</pre>
		</cfloop>
	</cfif>

	<cfif ArrayLen(down)>
		<h4>Down()</h4>
		<cfloop from="1" to="#ArrayLen(down)#" index="sql">
			<pre>
				<code class="sql hljs">#down[sql]#</code>
			</pre>
		</cfloop>
	</cfif>

	<cfif !ArrayLen(up) AND !ArrayLen(down)>
		<p>No SQL returned: this might be an empty migration file?</p>
	</cfif>
</cfoutput>
<!--- cfformat-ignore-end --->
