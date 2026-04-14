<cfsilent>
	<cfset adapter = new LegacyAdapter()>
	<cfset status = adapter.$legacyAdapterStatus()>
	<cfset pluginInfo = adapter.$legacyPluginInfo()>
</cfsilent>
<cfoutput>
<h1>Wheels Legacy Adapter v#status.version#</h1>

<h2>Status</h2>
<table class="table">
	<tr>
		<th>Mode</th>
		<td>#status.mode#</td>
	</tr>
	<tr>
		<th>Deprecations (this request)</th>
		<td>#status.deprecationsThisRequest#</td>
	</tr>
	<tr>
		<th>Legacy Plugins Active</th>
		<td>#YesNoFormat(pluginInfo.hasLegacyPlugins)#</td>
	</tr>
</table>

<cfif pluginInfo.hasLegacyPlugins>
	<h2>Legacy Plugins Found</h2>
	<p>These plugins should be migrated to the package system:</p>
	<table class="table">
		<thead>
			<tr><th>Plugin</th><th>Version</th></tr>
		</thead>
		<tbody>
			<cfloop array="#pluginInfo.plugins#" index="p">
				<tr>
					<td>#p.name#</td>
					<td>#p.version#</td>
				</tr>
			</cfloop>
		</tbody>
	</table>
</cfif>

<cfif ArrayLen(status.entries)>
	<h2>Deprecation Warnings (this request)</h2>
	<table class="table">
		<thead>
			<tr><th>Old</th><th>New</th><th>Guidance</th></tr>
		</thead>
		<tbody>
			<cfloop array="#status.entries#" index="entry">
				<tr>
					<td><code>#entry.oldMethod#</code></td>
					<td><code>#entry.newMethod#</code></td>
					<td>#entry.message#</td>
				</tr>
			</cfloop>
		</tbody>
	</table>
</cfif>

<h2>Migration Guide</h2>
<p>The legacy adapter supports a three-stage migration path:</p>
<ol>
	<li><strong>Stage 1 (Install &amp; Go):</strong> Copy <code>packages/legacyadapter</code> to <code>vendor/legacyadapter</code>. All 3.x code works unchanged. Deprecation warnings appear in logs.</li>
	<li><strong>Stage 2 (Migrate):</strong> Run the migration scanner to find legacy patterns. Update code incrementally. Set <code>legacyAdapterMode</code> to <code>"warn"</code> for more visibility.</li>
	<li><strong>Stage 3 (Remove):</strong> Set mode to <code>"error"</code> to catch any remaining legacy calls. Once clean, remove <code>vendor/legacyadapter</code>.</li>
</ol>

<h3>Configuration</h3>
<pre>// config/settings.cfm
set(legacyAdapterMode = "log");  // silent, log, warn, or error</pre>

<h3>Running the Scanner</h3>
<pre>// In a controller action or script
var report = $runMigrationScan();
WriteDump(report);</pre>
</cfoutput>
