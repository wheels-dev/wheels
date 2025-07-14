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
					<a href="/wheels/guides/" class="item">Home</a>
				</div>

				<div id="guides-menu" class="ui list link forcescroll sticky">
					<cfloop from="1" to="#arraylen(docs.navigation)#" index="section">
						<cfset sectionData = docs.navigation[section]>
						<div class="item">
							<div class="header">#sectionData.title#</div>
							<div class="list">
								<cfloop from="1" to="#arraylen(sectionData.items)#" index="item">
									<cfset itemData = sectionData.items[item]>
									<cfset isActive = (docs.path EQ itemData.link) ? " active" : "">
									<a href="/wheels/guides/#itemData.link#" class="item#isActive#">#itemData.title#</a>
								</cfloop>
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
				#docs.content#
			</div>
		</div>
	</div>

	<!--- Right sidebar - Table of contents --->
	<div class="four wide column" id="guides-toc">
		<div class="ui pointing vertical menu fluid sticky">
			<div class="item">
				<div class="header">Table of Contents</div>
				<div class="menu" id="toc-menu">
					<!--- TOC will be populated by JavaScript --->
				</div>
			</div>
		</div>
	</div>

	<!--- JavaScript for enhanced functionality --->
	<script>
		$(document).ready(function() {
			// Generate table of contents
			var toc = $('##toc-menu');
			var headers = $('##guides-content h1, ##guides-content h2, ##guides-content h3');
			
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
		
		#guides-content blockquote {
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