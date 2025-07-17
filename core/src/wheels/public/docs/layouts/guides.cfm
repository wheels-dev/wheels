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
	<div class="content markdown-body">
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
		// Function to parse GitBook-style tabs in Markdown
		function parseGitbookTabs(raw) {
			let tabGroupCounter = 0;
			// Regex to match {% tabs %} ... {% endtabs %}
			return raw.replace(/{% tabs %}([\s\S]*?){% endtabs %}/g, function(match, tabsContent) {
				tabGroupCounter++;
				const groupId = 'tabgroup-' + tabGroupCounter;
				// Find all tab blocks
				const tabRegex = /{% tab title="([^"]+)" %}([\s\S]*?){% endtab %}/g;
				let tabTitles = [];
				let tabContents = [];
				let m;
				let tabIndex = 0;
				while ((m = tabRegex.exec(tabsContent)) !== null) {
					tabTitles.push(m[1]);
					tabContents.push(m[2].trim());
					tabIndex++;
				}
				if (tabTitles.length === 0) return match; // fallback

				// Build tab headers
				let nav = `<ul class="gitbook-tablist" role="tablist" data-tabgroup="${groupId}">`;
				tabTitles.forEach((title, i) => {
					nav += `<li class="gitbook-tabitem" role="presentation">\n<a class="gitbook-tablink${i === 0 ? ' active' : ''}" href="##" data-target="${groupId}-tab-${i}" data-tabgroup="${groupId}" role="tab" aria-selected="${i === 0 ? 'true' : 'false'}"${i === 0 ? '' : ' tabindex=\"-1\"'}>${title}</a>\n</li>`;
				});
				nav += '</ul>';

				// Build tab contents (custom classes)
				let content = `<div class="gitbook-tabcontent" data-tabgroup="${groupId}">`;
				tabContents.forEach((tab, i) => {
					// Always wrap tab content in a code block
					let tabContent = tab;
					if (!/^```/.test(tabContent.trim())) {
						tabContent = '```shell\n' + tabContent + '\n```';
					}
					content += `<div class="gitbook-tabpane${i === 0 ? ' show active' : ''}" id="${groupId}-tab-${i}" role="tabpanel">${tabContent}</div>`;
				});
				content += '</div>';

				return `<div class="gitbooktabs border rounded-3 my-4 p-3" data-tabgroup="${groupId}">${nav}${content}</div>`;
			});
		}

        // Parse {% code title="..." %}...{% endcode %} blocks
        function parseCodeTitleBlocks(raw) {
            return raw.replace(/{% code title="([^"]+)" %}([\s\S]*?){% endcode %}/g, function(match, title, code) {
                // Remove leading/trailing whitespace from code
                code = code.replace(/^\n+|\n+$/g, "");
                // If code is empty or only whitespace, do not render anything
                if (!code.trim()) return "";
                // Always render as code block, auto-detect language if possible
                let codeBlock = code + '\n';
                return `<div class="code-title-block"><div class="code-title-header">${title}</div><div class="code-title-body">${codeBlock}</div></div>`;
            });
        }

        // Parse {% hint style="..." %}...{% endhint %} blocks
        function parseHintBlocks(raw) {
            return raw.replace(/{% hint style="([^"]+)" %}([\s\S]*?){% endhint %}/g, function(match, style, content) {
                content = content.replace(/^\n+|\n+$/g, "");
                if (!content.trim()) return "";
                // Capitalize style for tab
                let styleLabel = style.charAt(0).toUpperCase() + style.slice(1).toLowerCase();
                return `<div class="hint-block hint-${style}"><div class="hint-header hint-${style}">${styleLabel}</div><div class="hint-body">${content}</div></div>`;
            });
        }

		$(document).ready(function() {
			let raw = $('##raw-markdown').val();

			// Preprocess for GitBook tabs
			raw = parseGitbookTabs(raw);
            // Preprocess for code title blocks
            raw = parseCodeTitleBlocks(raw);
            // Preprocess for hint blocks
            raw = parseHintBlocks(raw);

			// Remove everything between --- and --- (inclusive)
			raw = raw.replace(/^\s*---\s*$(?:\r?\n|\r)[\s\S]*?^\s*---\s*$(?:\r?\n|\r)?/gm, '');
			const html = marked.parse(raw);
			$('##rendered-markdown').html(html);

			// After rendering, re-render the tab pane contents as Markdown
			$('.gitbook-tabpane').each(function() {
				const $pane = $(this);
				const rawContent = $pane.text();
				$pane.html(marked.parse(rawContent));
			});
            // After rendering, render code-title blocks as Markdown
            $('.code-title-block').each(function() {
                var $block = $(this);
                var $body = $block.find('.code-title-body');
                $body.html(marked.parse($body.text()));
            });
            // After rendering, render hint blocks as Markdown
            $('.hint-block').each(function() {
                var $block = $(this);
                var $body = $block.find('.hint-body');
                $body.html(marked.parse($body.text()));
            });

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

			// Tab switching
			$(document).on('click', '.gitbooktabs .gitbook-tablink', function(e) {
				e.preventDefault();
				var $tab = $(this);
				var groupId = $tab.data('tabgroup');
				var $container = $tab.closest('.gitbooktabs');
				$container.find('.gitbook-tablink').removeClass('active').attr('aria-selected', 'false');
				$tab.addClass('active').attr('aria-selected', 'true');
				$container.find('.gitbook-tabpane').removeClass('show active');
				$container.find('##' + $tab.data('target')).addClass('show active');
			});

			// Hide loader
			$('.ui.dimmer').removeClass('active');
		});
	</script>
	
	<style>
		.markdown-body {
			font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji";
			line-height: 1.6;
			color: ##24292e;
			background-color: ##fff;
			padding: 1.5rem;
			border-radius: 6px;
			box-shadow: 0 1px 3px rgb(27 31 35 / 0.1);
		}

		.markdown-body h1, .markdown-body h2, .markdown-body h3, .markdown-body h4, .markdown-body h5, .markdown-body h6 {
			margin-top: 1.5em;
			margin-bottom: 1em;
			font-weight: 600;
			line-height: 1.25;
			color: ##ef3b2d;
		}

		.markdown-body h1 {
			border-bottom: 1px solid ##eaecef;
			padding-bottom: 0.3em;
			font-size: 2rem;
		}

		.markdown-body p {
			margin-top: 0;
			margin-bottom: 1em;
		}

		.markdown-body code {
			background-color: rgba(27,31,35,.05);
			padding: 0.2em 0.4em;
			margin: 0;
			font-size: 85%;
			border-radius: 3px;
			font-family: SFMono-Regular, Consolas, Liberation Mono, Menlo, monospace;
		}

		.markdown-body pre {
			background-color: ##f6f8fa;
			padding: 1em;
			overflow: auto;
			font-size: 85%;
			line-height: 1.45;
			border-radius: 6px;
			border: 1px solid ##d1d5da;
		}

		.markdown-body blockquote {
			margin: 0;
			padding-left: 1em;
			color: ##6a737d;
			border-left: 0.25em solid ##dfe2e5;
		}

		.markdown-body table {
			border-collapse: collapse;
			border-spacing: 0;
			display: block;
			width: 100%;
			overflow: auto;
		}

		.markdown-body table th,
		.markdown-body table td {
			padding: 6px 13px;
			border: 1px solid ##dfe2e5;
		}

		.markdown-body table th {
			font-weight: 600;
		}

		.markdown-body img {
			max-width: 100%;
			box-sizing: content-box;
			background-color: ##fff;
			border: 1px solid ##d1d5da;
			border-radius: 6px;
			padding: 0.2em 0.4em;
		}

		.markdown-body figcaption {
			color: ##6a737d;
			font-size: 0.875em;
			text-align: center;
			margin-top: 0.5em;
		}

		.toc-h1 { font-weight: bold; }
		.toc-h2 { margin-left: 10px; }
		.toc-h3 { margin-left: 20px; font-size: 0.9em; }
		
		.active { 
			background-color: ##e0e0e0 !important;
			font-weight: bold;
		}

		/* Tab styles */
		.gitbook-tablist {
			display: flex;
			border-bottom: 1px solid ##ddd;
			margin-bottom: 1rem;
			padding-left: 0;
			list-style: none;
		}
		.gitbook-tabitem {
			margin-bottom: -1px;
		}
		.gitbook-tablink {
			display: block;
			padding: 0.5rem 1rem;
			border: 1px solid transparent;
			border-radius: 0.25rem 0.25rem 0 0;
			background: ##f8f9fa;
			color: ##333;
			text-decoration: none;
			cursor: pointer;
			margin-right: 2px;
			transition: background 0.2s, color 0.2s;
		}
		.gitbook-tablink.active {
			background: ##fff;
			border-color: ##ddd ##ddd ##fff;
			color: ##ef3b2d;
			font-weight: bold;
			z-index: 2;
		}
		.gitbook-tabcontent {
			border: 1px solid ##ddd;
			border-top: none;
			padding: 1rem;
			background: ##fff;
			border-radius: 0 0 0.25rem 0.25rem;
		}
		.gitbook-tabpane {
			display: none;
		}
		.gitbook-tabpane.show.active {
			display: block;
		}
        /* Code title block styles */
        .code-title-block {
            margin: 1.5rem 0;
            border: 1px solid ##e0e0e0;
            border-radius: 6px;
            background: ##f8f9fa;
        }
        .code-title-header {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji";
            font-size: 0.95rem;
            font-weight: 500;
            background: ##f3f4f6;
            color: ##444;
            padding: 0.5rem 1rem;
            border-bottom: 1px solid ##e0e0e0;
            border-radius: 6px 6px 0 0;
        }
        .code-title-body {
            padding: 1rem;
            background: ##fff;
            border-radius: 0 0 6px 6px;
            font-size: 0.95rem;
        }
        /* Hint block styles */
        .hint-block {
            margin: 1.5rem 0;
            border-radius: 6px;
            border: 1px solid ##e0e0e0;
            background: ##f8f9fa;
            box-shadow: 0 1px 2px rgba(0,0,0,0.03);
        }
        .hint-header {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji";
            font-size: 0.95rem;
            font-weight: 500;
            padding: 0.5rem 1rem;
            border-bottom: 1px solid ##e0e0e0;
            border-radius: 6px 6px 0 0;
            background: ##e9ecef;
            color: ##444;
        }
        .hint-body {
            padding: 1rem;
            background: ##fff;
            border-radius: 0 0 6px 6px;
            font-size: 0.97rem;
        }
        /* Info */
        .hint-info .hint-header { background: ##e3f2fd; color: ##1565c0; border-bottom: 1px solid ##90caf9; }
        .hint-info { border-color: ##90caf9; background: ##f5fafd; }
        /* Warning */
        .hint-warning .hint-header { background: ##fff8e1; color: ##b26a00; border-bottom: 1px solid ##ffe082; }
        .hint-warning { border-color: ##ffe082; background: ##fffde7; }
        /* Danger */
        .hint-danger .hint-header { background: ##ffebee; color: ##c62828; border-bottom: 1px solid ##ef9a9a; }
        .hint-danger { border-color: ##ef9a9a; background: ##fff5f5; }
        /* Success */
        .hint-success .hint-header { background: ##e8f5e9; color: ##2e7d32; border-bottom: 1px solid ##a5d6a7; }
        .hint-success { border-color: ##a5d6a7; background: ##f5fcf7; }
        /* Default fallback */
        .hint-block .hint-header { background: ##e9ecef; color: ##444; border-bottom: 1px solid ##e0e0e0; }
        .hint-block { border-color: ##e0e0e0; background: ##f8f9fa; }
	</style>
	<!--- cfformat-ignore-end --->
</cfoutput>