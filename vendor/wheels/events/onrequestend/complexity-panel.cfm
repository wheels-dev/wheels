<!--- Complexity panel — owns its <cfoutput> wrapper instead of relying on the
	enclosing debug.cfm <cfoutput>. At least one supported engine does not
	inherit the cfoutput context across a <cfinclude> boundary, so the
	expressions in this partial leaked as literal CFML references instead of
	evaluated values. A self-contained <cfoutput> evaluates them on Lucee,
	Adobe CF, BoxLang, and RustCFML (issue 3548).

	File paths use HtmlEditFormat (not EncodeForHTML): RustCFML's EncodeForHTML
	encodes "/" as "&#x2f;", which breaks readable path display and the panel
	regression. HtmlEditFormat still escapes <>&"' while preserving slashes.
	Reads local.codeComplexity, populated defensively in debug.cfm. --->
<cfoutput>
<div class="wdb-panel" id="wdb-panel-complexity">
	<div class="wdb-panel-header">
		<h3>Code Complexity &mdash; app/</h3>
		<button class="wdb-close-btn" onclick="wdbClosePanel()">&times;</button>
	</div>
	<div class="wdb-panel-body">
		<div class="wdb-section">
			<div class="wdb-section-title">Summary</div>
			<div style="font-size:12px;color:##cdd6f4;line-height:1.8;">
				#local.codeComplexity.summary.files# files &middot;
				#local.codeComplexity.summary.functions# functions &middot;
				max <strong>#local.codeComplexity.summary.maxComplexity#</strong> &middot;
				avg <strong>#local.codeComplexity.summary.avgComplexity#</strong>
			</div>
		</div>
		<div class="wdb-section">
			<div class="wdb-section-title">Most Complex Files</div>
			<div style="font-size:11px;color:##a6adc8;margin-bottom:6px;">Cyclomatic complexity = 1 + decision points (if / for / case / catch / &amp;&amp; / || / ternary). Static only &mdash; test coverage is a separate <code>wheels coverage</code> run.</div>
			<table class="wdb-table">
				<tr>
					<th>File</th>
					<th style="text-align:right;">Funcs</th>
					<th style="text-align:right;">Complexity</th>
					<th style="text-align:right;">Avg/Fn</th>
				</tr>
				<cfloop from="1" to="#Min(15, ArrayLen(local.codeComplexity.files))#" index="local.ci">
					<cfset local.cf = local.codeComplexity.files[local.ci]>
					<cfif local.cf.complexity GT 30>
						<cfset local.rowColor = "##f38ba8">
					<cfelseif local.cf.complexity GT 15>
						<cfset local.rowColor = "##f9e2af">
					<cfelse>
						<cfset local.rowColor = "##a6e3a1">
					</cfif>
					<tr style="border-bottom:1px solid ##313244;color:##cdd6f4;">
						<td style="padding:4px 8px;font-family:monospace;">#HtmlEditFormat(local.cf.file)#</td>
						<td style="padding:4px 8px;text-align:right;">#local.cf.functions#</td>
						<td style="padding:4px 8px;text-align:right;color:#local.rowColor#;font-weight:600;">#local.cf.complexity#</td>
						<td style="padding:4px 8px;text-align:right;">#NumberFormat(local.cf.avg, "0.0")#</td>
					</tr>
				</cfloop>
			</table>
		</div>
	</div>
</div>
</cfoutput>
