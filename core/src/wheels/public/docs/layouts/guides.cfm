<cfparam name="docs">
<cfoutput>
	<!--- cfformat-ignore-start --->
	<!--- Navigation sidebar --->
	<div class="three wide column" id="guides-navigation">
		<div class="ui vertical menu fluid">
			<div class="item">
				<div class="ui input">
					<input type="text" id="guide-search" placeholder="Search guides...">
				</div>
			</div>
			<div class="item">
				<div class="header">
					<div id="guidesResults">
						<span class="resultCount">
							<div class="ui active inverted dimmer">
								<div class="ui mini loader">Loading</div>
							</div>
						</span> Guides
					</div>
				</div>
				<div class="menu">
					<a href="/wheels/guides" class="item">Home</a>
				</div>

				<div id="guides-menu" class="ui list link forcescroll sticky">
					<cfloop from="1" to="#arraylen(docs.navigation)#" index="section">
						<cfset sectionData = docs.navigation[section]>
						<div class="item">
							<div class="header">#sectionData.title#</div>
							<div class="list">
								#renderGuideItems(sectionData.items, docs.path)#
							</div>
						</div>
					</cfloop>
				</div>
			</div>
		</div>
	</div>

	<!--- Main content --->
	<div class="nine wide column" id="guides-content">
		<div class="ui raised segment">
			<div class="content">
				<!-- Raw Markdown -->
				<textarea id="raw-markdown" style="display: none;">#encodeForHTML(docs.content)#</textarea>

				<!-- Rendered HTML will go here -->
				<div id="rendered-markdown"></div>
			</div>
		</div>
	</div>

	<!--- Right sidebar - Table of contents --->
	<div class="four wide column" id="guides-toc">
		<div class="ui pointing vertical menu fluid sticky">
			<div class="item">
				<div class="header">On this page</div>
				<div class="menu" id="toc-menu">
					<!--- TOC will be populated by JavaScript --->
				</div>
			</div>
		</div>
	</div>

	<cffunction name="renderGuideItems" access="public" returntype="string" output="true">
		<cfargument name="items" required="true" type="array">
		<cfargument name="currentPath" required="true" type="string">

		<cfloop array="#arguments.items#" index="item">
			<cfif structKeyExists(item, "link")>
				<!--- Determine if the link is external --->
				<cfset isExternal = reFindNoCase("^(http|https)://", item.link) GT 0>

				<!--- Clean internal .md links --->
				<cfif !isExternal>
					<cfset cleanLink = lcase(reReplace(item.link, "\.md$", ""))>
					<cfset isActive = (arguments.currentPath EQ cleanLink) ? " active" : "">
				</cfif>

				<cfif isExternal>
					<!--- External Link --->
					<a href="#item.link#" target="_blank" rel="noopener noreferrer" class="item">#item.title#</a>
				<cfelse>
					<!--- Internal Guide Link (routed through /wheels/guides/) --->
					<a href="/wheels/guides/#cleanLink#" class="item#isActive#">#item.title#</a>
				</cfif>

			<cfelseif structKeyExists(item, "items")>
				<!--- It's a subsection/group --->
				<div class="header">#item.title#</div>
				<div class="list">
					<cfoutput>
						#renderGuideItems(item.items, arguments.currentPath)#
					</cfoutput>
				</div>
			</cfif>
		</cfloop>

		<cfreturn "">
	</cffunction>


	<!--- JavaScript for enhanced functionality --->
	<script>
		$(document).ready(function() {
			let raw = $('##raw-markdown').val();
			
			// Remove everything between --- and --- (inclusive)
			raw = raw.replace(/^\s*---\s*$(?:\r?\n|\r)[\s\S]*?^\s*---\s*$(?:\r?\n|\r)?/gm, '');
			const html = marked.parse(raw);
			$('##rendered-markdown').html(html);

			// Generate table of contents
			var toc = $('##toc-menu');
			var headers = $('##rendered-markdown h1, ##rendered-markdown h2, ##rendered-markdown h3');
			
			headers.each(function(i, header) {
				var $header = $(header);
				var id = 'toc-' + i;
				var text = $header.text();
				var level = header.tagName.toLowerCase();
				
				// Add ID to header for linking
				$header.attr('id', id);
				
				// Add to TOC
				var tocItem = $('<a href="##' + id + '" class="item toc-' + level + '">' + text + '</a>');
				toc.append(tocItem);
			});
			
			// Search functionality
			$('##guide-search').on('input', function() {
				var searchTerm = $(this).val().toLowerCase();
				var items = $('##guides-menu .item a');
				
				items.each(function() {
					var $item = $(this);
					var text = $item.text().toLowerCase();
					
					if (text.indexOf(searchTerm) !== -1 || searchTerm === '') {
						$item.show();
					} else {
						$item.hide();
					}
				});
			});
			
			// Smooth scrolling for TOC links
			$('a[href^="##"]').on('click', function(e) {
				e.preventDefault();
				var target = $(this.getAttribute('href'));
				if (target.length) {
					$('html, body').animate({
						scrollTop: target.offset().top - 100
					}, 500);
				}
			});
			
			// Hide loader
			$('.ui.dimmer').removeClass('active');
		});
	</script>
	
	<style>
		##guides-content {
			font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
			line-height: 1.6;
		}
		
		##guides-content h1, ##guides-content h2, ##guides-content h3 {
			margin-top: 2em;
			margin-bottom: 1em;
		}
		
		##guides-content h1 {
			border-bottom: 2px solid ##eee;
			padding-bottom: 0.5em;
		}
		
		##guides-content code {
			background-color: ##f4f4f4;
			padding: 2px 4px;
			border-radius: 3px;
		}
		
		##guides-content pre {
			background-color: ##f8f8f8;
			border: 1px solid ##ddd;
			border-radius: 4px;
			padding: 12px;
			overflow-x: auto;
		}
		
		##guides-content blockquote {
			border-left: 4px solid ##ddd;
			margin: 0;
			padding-left: 16px;
			color: ##666;
		}
		
		.toc-h1 { font-weight: bold; }
		.toc-h2 { margin-left: 10px; }
		.toc-h3 { margin-left: 20px; font-size: 0.9em; }
		
		.active { 
			background-color: ##e0e0e0 !important;
			font-weight: bold;
		}
	</style>
	<!--- cfformat-ignore-end --->
</cfoutput>