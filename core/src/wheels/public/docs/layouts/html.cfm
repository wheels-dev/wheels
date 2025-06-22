<cfparam name="docs">
<cfoutput>
	<!--- cfformat-ignore-start --->
	<!--- Function AZ --->
		<div class="three wide column" id="function-navigation">
			<div class="ui vertical menu fluid">
				<div class="item">
					<div class="ui input">
					<input type="text" id="doc-search" placeholder="Search...">
				</div>
				</div>
				<div class="item">
					<div class="header"><div id="functionResults">
					<span class="resultCount">
					<div class="ui active inverted dimmer">
						<div class="ui mini loader">Loading</div>
					</div>
					</span> Functions</div></div>
					<div class="menu">
						<a href="" class="item">A-Z</a>
					</div>

					<div id="atoz" class="ui list link forcescroll sticky">
					<cfloop from="1" to="#arraylen(docs.functions)#" index="func">
					<cfset meta=docs.functions[func]>
						<a href="" class="functionlink item" data-section="#meta.tags.sectionClass#" data-category="#meta.tags.categoryClass#" data-function="#lcase(meta.slug)#">#meta.name#()</a>
					</cfloop>
					</div>
				</div>
		</div><!--/menu-->
	</div><!--/ col -->

	<!--- Functions --->
		<div class="nine wide column" id="function-output">
			<cfloop from="1" to="#arraylen(docs.functions)#" index="func">
			<cfset meta=docs.functions[func]>
			<div id="#lcase(meta.name)#"
				data-section="#meta.tags.sectionClass#"
				data-category="#meta.tags.categoryClass#"
				data-function="#lcase(meta.slug)#"
				class="functiondefinition ui raised segment ">

					<h3 class="functitle ui  ">#meta.name#()</h3>

					<cfif len(meta.tags.section)>
						<a href="" class="filtersection ui  basic purple left ribbon label" title="Show all Functions in this category">
						#meta.tags.section#</a>
					</cfif>
					<cfif len(meta.tags.category)>
						<a href="" class="filtercategory ui basic  red left label" title="Show all Functions in this category">
						#meta.tags.category#</a>
					</cfif>
					<cfif structKeyExists(meta, "returnType")>
						<span class="ui label"><svg xmlns="http://www.w3.org/2000/svg" height="10" width="10" viewBox="0 0 512 512"><path d="M205 34.8c11.5 5.1 19 16.6 19 29.2v64H336c97.2 0 176 78.8 176 176c0 113.3-81.5 163.9-100.2 174.1c-2.5 1.4-5.3 1.9-8.1 1.9c-10.9 0-19.7-8.9-19.7-19.7c0-7.5 4.3-14.4 9.8-19.5c9.4-8.8 22.2-26.4 22.2-56.7c0-53-43-96-96-96H224v64c0 12.6-7.4 24.1-19 29.2s-25 3-34.4-5.4l-160-144C3.9 225.7 0 217.1 0 208s3.9-17.7 10.6-23.8l160-144c9.4-8.5 22.9-10.6 34.4-5.4z"/></svg> #meta.returnType#</span>
					</cfif>
					<cfif structKeyExists(meta, "availableIn") && arrayLen(meta.availableIn)>
						<cfloop from="1" to="#arrayLen(meta.availableIn)#" index="a">
							<span class="ui label">
								<svg xmlns="http://www.w3.org/2000/svg" height="10" width="10" viewBox="0 0 320 512"><path d="M296 160H180.6l42.6-129.8C227.2 15 215.7 0 200 0H56C44 0 33.8 8.9 32.2 20.8l-32 240C-1.7 275.2 9.5 288 24 288h118.7L96.6 482.5c-3.6 15.2 8 29.5 23.3 29.5 8.4 0 16.4-4.4 20.8-12l176-304c9.3-15.9-2.2-36-20.7-36z"/></svg>
								#meta.availableIn[a]#
							</span>
						</cfloop>
					</cfif>
					<cfif structKeyExists(meta, "hint")>
						<p class="hint">#$hintOutput(meta.hint)#</p>
					</cfif>

					<cfif isArray(meta.parameters) && arraylen(meta.parameters)>
						<table class="ui celled striped table">
						<thead>
							<tr>
								<th>Name</th>
								<th>Type</th>
								<th>Required</th>
								<th>Default</th>
								<th>Description</th>
							</tr>
						</thead>
						<tbody>
						<cfloop from="1" to="#arraylen(meta.parameters)#" index="p">
						<cfset _param=meta.parameters[p]>
							<cfif !left(_param.name, 1) EQ "$">
								<tr>
									<td class='code'>#_param.name#</td>
									<td class='code'><cfif StructkeyExists(_param, "type")>#_param.type#</cfif></td>
									<td class='code'><cfif StructkeyExists(_param, "required")>#YesNoFormat(_param.required)#</cfif></td>
									<td class='code'><cfif StructkeyExists(_param, "default")>#_param.default#</cfif></td>
									<td><cfif StructkeyExists(_param, "hint")>#$backTickReplace(_param.hint)#</cfif></td>
								</tr>
							</cfif>
						</cfloop>
						</tbody>
						</table>
					</cfif>

					<cfif meta.extended.hasExtended>
						<div class="md">#meta.extended.docs#</div>
					</cfif>
				</div><!--/ #lcase(meta.name)# -->
		</cfloop>
	</div><!--/ col -->

	<!--- Categories --->
		<div class="four wide  column" id="function-category-list">
			<div class="ui pointing vertical menu fluid  sticky">
				<cfloop from="1" to="#arraylen(docs.sections)#" index="s">
				<a href="" data-section="#$cssClassLink(docs.sections[s]['name'])#" class="section item">#docs.sections[s]['name']#</a>

				<div class="menu">
				<cfloop from="1" to="#arraylen(docs.sections[s]['categories'])#" index="ss">
					<a href=""	data-section="#$cssClassLink(docs.sections[s]['name'])#"	data-category="#$cssClassLink(docs.sections[s]['categories'][ss])#" class="item category">#docs.sections[s]['categories'][ss]#</a>
				</cfloop>
				</div>
			</cfloop>
			<div class="item">
				<div class="header">Misc</div>
				<div class="menu">
					<a href=""	data-section=""	data-category="" class="section item">Uncategorized</a>
				</div>
			</div>
	</div><!--/ col -->
	<!--- cfformat-ignore-end --->
</cfoutput>
