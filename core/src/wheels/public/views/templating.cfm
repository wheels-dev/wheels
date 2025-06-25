<cfinclude template="../layout/_header.cfm">
<cfscript>
datasourceAvailable=true;
message = "";
try {
	availableMigrations = application.wheels.migrator.getAvailableMigrations();
	prefix = "timestamp";
	if(arrayLen(availableMigrations)){
		if(len(availableMigrations[1]["version"]) NEQ 14 ){
			prefix = "numeric";
		}
	}
} catch (database err){
	datasourceAvailable = false;
	message = err.message;
}
</cfscript>
<cfoutput>
<!--- cfformat-ignore-start --->
<div class="ui container">
	#pageHeader("Migrator", "Migration Templates")#

	<cfinclude template="../migrator/_navigation.cfm">

	<cfif datasourceAvailable>

	<!--- Create --->
	<h5>Create a Template</h5>

	<div class="ui segment">
		<div class="ui form">

	<!--- Migration Prefix --->
	<div id="prefix">
		<h5>Migration Prefix</h5>
		<cfif !arrayLen(availableMigrations)><p>As you have no migration files yet, we need to define how you would like them prefixed</p></cfif>

		<div class="field">
			<div class="ui radio checkbox">
			<input type="radio" name="migrationPrefix" value="timestamp" <cfif preFix EQ 'timestamp'>checked</cfif>>
			<label>Timestamp (e.g. <code>#dateformat(now(),'yyyymmdd')##timeformat(now(),'hhmmss')#</code>)	<strong>(Recommended)</strong></label>
			</div>
		</div>
		<div class="field">
			<div class="ui radio checkbox">
			<input type="radio" name="migrationPrefix" value="numeric" <cfif preFix EQ 'numeric'>checked</cfif>>
			<label>Numeric (e.g. <code>001</code>)</label>
			</div>
		</div>
	</div>
		<div class="ui hidden divider"></div>

		<h5>Select a template:</h5>
		<div class="field">
			<div class="ui radio checkbox">
				<input type="radio" name="templateName" value="blank" checked>
				<label>Create a blank migration file</label>
			</div>
		</div>

		<div class="ui horizontal section divider">
			Or Use Existing Template
		</div>

		<div class="ui grid">
			<div class="column four wide">
				<h4 class="ui dividing header">Tables</h4>
				<div class="field"><div class="ui radio checkbox"><input type="radio" name="templateName" value="create-table"><label> Create table</label></div></div>
				<div class="field"><div class="ui radio checkbox"><input type="radio" name="templateName" value="change-table"><label> Change table (multi-column)</label></div></div>
				<div class="field"><div class="ui radio checkbox"><input type="radio" name="templateName" value="rename-table"><label> Rename table</label></div></div>
				<div class="field"><div class="ui radio checkbox"><input type="radio" name="templateName" value="remove-table"><label> Remove table</label></div></div>
			</div>

			<div class="column four wide">
				<h4 class="ui dividing header">Columns</h4>
				<div class="field"><div class="ui radio checkbox"><input type="radio" name="templateName" value="create-column"><label> Create single column</label></div></div>
				<div class="field"><div class="ui radio checkbox"><input type="radio" name="templateName" value="change-column"><label> Change single column</label></div></div>
				<div class="field"><div class="ui radio checkbox"><input type="radio" name="templateName" value="rename-column"><label> Rename single column</label></div></div>
				<div class="field"><div class="ui radio checkbox"><input type="radio" name="templateName" value="remove-column"><label> Remove single column</label></div></div>
			</div>

			<div class="column four wide">
				<h4 class="ui dividing header">Records</h4>
				<div class="field"><div class="ui radio checkbox"><input type="radio" name="templateName" value="create-record"><label> Create record</label></div></div>
				<div class="field"><div class="ui radio checkbox"><input type="radio" name="templateName" value="update-record"><label> Update record</label></div></div>
				<div class="field"><div class="ui radio checkbox"><input type="radio" name="templateName" value="remove-record"><label> Remove record</label></div></div>
			</div>

			<div class="column four wide">
				<h4 class="ui dividing header">Other</h4>
				<div class="field"><div class="ui radio checkbox"><input type="radio" name="templateName" value="create-index"><label> Create index</label></div></div>
				<div class="field"><div class="ui radio checkbox"><input type="radio" name="templateName" value="remove-index"><label> Remove index</label></div></div>
				<div class="field"><div class="ui radio checkbox"><input type="radio" name="templateName" value="announce"><label> Announce operation</label></div></div>
				<div class="field"><div class="ui radio checkbox"><input type="radio" name="templateName" value="execute"><label> Execute operation</label></div></div>
			</div>
		</div>


		<div class="ui horizontal section divider"></div>

		<div class="field">
			<div class="ui labeled input">
				<div class="ui label">
					Description
				</div>
			<input name="migrationName" id="migrationName" type="text" class="" placeholder=" (eg. 'creates member table')">
			</div>
		</div>

		<input type="submit" value="Create Migration File"
		data-data-url="#urlFor(route='wheelsMigratorTemplates')#"
		class="ui button red createMigration" data-command="createMigration">

		<div id="result"></div>

		</div><!--/ui form -->
	</div><!-- ui segment -->

<cfelse>
	<div class="ui placeholder segment">
		<div class="ui icon header">
			<i class="database icon"></i>
			Database Error<br><small>
		#message#</small>
		</div>
	</div>
</cfif>
 </div><!--/container -->

</cfoutput>

<script>
$(document).ready(function() {
	$(".createMigration").on("click", function(e){
		var url = $(this).data("data-url");
		var data = {
			"migrationPrefix": $("input[name='migrationPrefix']:checked").val(),
			"templateName" : $("input[name='templateName']:checked").val(),
			"migrationName" : $("#migrationName").val()
		}
		var resp = $.ajax({
				url: url,
				method: 'post',
				data: data
		})
		.done(function(data, status, req) {
			var res = $("#result");
			$("#migrationName").val("");
			res.html(data);
		})
		.fail(function(e) {
			alert( "An error occurred" );
		});
	});
});
</script>
<cfinclude template="../layout/_footer.cfm">
<!--- cfformat-ignore-end --->
