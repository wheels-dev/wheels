/**
 * wheels-basecoat Plugin
 * Basecoat UI component helpers for Wheels.
 * Generates shadcn/ui-quality HTML using Basecoat CSS classes.
 * Works with or without wheels-hotwire.
 */
component mixin="controller,view" output="false" {

	function init() {
		this.version = "3.0";
		return this;
	}

	// ==============================================
	// INCLUDES
	// ==============================================

	/**
	 * Outputs Basecoat CSS and Alpine.js (for interactive components) tags for the layout <head>.
	 */
	public string function basecoatIncludes(
		boolean alpine = true,
		string alpineVersion = "3",
		string basecoatCSSPath = "/plugins/basecoat/assets/basecoat/basecoat.min.css",
		boolean turboAware = true
	) {
		var local = {};
		savecontent variable="local.html" {
			writeOutput(
				(arguments.turboAware ? '<meta name="turbo-cache-control" content="no-preview">' & chr(10) : '')
				& '<link rel="stylesheet" href="#arguments.basecoatCSSPath#">' & chr(10)
				& (arguments.alpine ? '<script defer src="https://cdn.jsdelivr.net/npm/alpinejs@#arguments.alpineVersion#/dist/cdn.min.js"></script>' & chr(10) : '')
			);
		}
		return trim(local.html);
	}

	// ==============================================
	// BUTTONS
	// ==============================================

	/**
	 * Basecoat button. Variants: primary, secondary, destructive, outline, ghost, link. Sizes: sm, md, lg.
	 */
	public string function uiButton(
		string text = "",
		string variant = "primary",
		string size = "md",
		string icon = "",
		string href = "",
		string type = "button",
		boolean disabled = false,
		boolean loading = false,
		boolean close = false,
		string class = "",
		string id = "",
		string ariaLabel = "",
		string turboConfirm = "",
		string turboMethod = ""
	) {
		var local = {};

		// Build Basecoat compound class: btn[-size][-icon][-variant]
		local.isIconOnly = len(arguments.icon) && !len(arguments.text);
		local.parts = [];
		if (arguments.size != "md") arrayAppend(local.parts, arguments.size);
		if (local.isIconOnly) arrayAppend(local.parts, "icon");
		if (arguments.variant != "primary") arrayAppend(local.parts, arguments.variant);

		local.cls = arrayLen(local.parts) ? "btn-" & arrayToList(local.parts, "-") : "btn";
		if (len(arguments.class)) local.cls &= " " & arguments.class;

		// Inner content: icon + text
		local.inner = "";
		if (arguments.loading) {
			local.inner = $uiLucideIcon("loader", 24, 2, "animate-spin");
		} else if (len(arguments.icon)) {
			local.inner = $uiLucideIcon(arguments.icon, 24);
		}
		if (len(arguments.text)) {
			if (len(local.inner)) local.inner &= " ";
			local.inner &= arguments.text;
		}

		// Attributes
		local.attrs = 'class="#local.cls#"';
		if (len(arguments.id)) local.attrs &= ' id="#arguments.id#"';
		if (arguments.disabled || arguments.loading) local.attrs &= " disabled";
		if (len(arguments.ariaLabel)) local.attrs &= ' aria-label="#arguments.ariaLabel#"';
		if (arguments.close) local.attrs &= " onclick=""this.closest('dialog').close()""";
		if (len(arguments.turboConfirm)) local.attrs &= ' data-turbo-confirm="#arguments.turboConfirm#"';
		if (len(arguments.turboMethod)) local.attrs &= ' data-turbo-method="#arguments.turboMethod#"';

		if (len(arguments.href))
			return '<a href="#arguments.href#" #local.attrs#>#local.inner#</a>';
		return '<button type="#arguments.type#" #local.attrs#>#local.inner#</button>';
	}

	// ==============================================
	// BADGES
	// ==============================================

	/** Basecoat badge. Variants: default, secondary, destructive, outline. */
	public string function uiBadge(required string text, string variant = "default", string class = "") {
		var cls = (arguments.variant == "default") ? "badge" : "badge-#arguments.variant#";
		if (len(arguments.class)) cls &= " " & arguments.class;
		return '<span class="#cls#">#arguments.text#</span>';
	}

	// ==============================================
	// ICONS
	// ==============================================

	/** Renders a Lucide SVG icon by name. */
	public string function uiIcon(required string name, numeric size = 24, numeric strokeWidth = 2, string class = "") {
		return $uiLucideIcon(arguments.name, arguments.size, arguments.strokeWidth, arguments.class);
	}

	// ==============================================
	// SIMPLE COMPONENTS
	// ==============================================

	/** Basecoat loading spinner. */
	public string function uiSpinner(string class = "") {
		var cls = "spinner";
		if (len(arguments.class)) cls &= " " & arguments.class;
		return '<div class="#cls#"></div>';
	}

	/** Basecoat skeleton loading placeholder. Specify lines for multiple, or use height/width for custom. */
	public string function uiSkeleton(numeric lines = 1, string height = "h-4", string width = "w-full", string class = "") {
		var cls = "skeleton #arguments.height# #arguments.width#";
		if (len(arguments.class)) cls &= " " & arguments.class;

		if (arguments.lines == 1)
			return '<div class="#cls#"></div>';

		var html = "";
		for (var i = 1; i <= arguments.lines; i++) {
			html &= '<div class="#cls#"></div>';
			if (i < arguments.lines) html &= chr(10);
		}
		return html;
	}

	/** Basecoat progress bar. */
	public string function uiProgress(required numeric value, string class = "") {
		var cls = "progress";
		if (len(arguments.class)) cls &= " " & arguments.class;
		return '<div class="#cls#"><div class="progress-indicator" style="width: #arguments.value#%"></div></div>';
	}

	/** Basecoat horizontal separator. */
	public string function uiSeparator(string class = "") {
		var cls = "separator";
		if (len(arguments.class)) cls &= " " & arguments.class;
		return '<hr class="#cls#" />';
	}

	/** Opens a Basecoat tooltip wrapper. Place trigger element inside, close with uiTooltipEnd(). */
	public string function uiTooltip(required string tip, string class = "") {
		var cls = "tooltip";
		if (len(arguments.class)) cls &= " " & arguments.class;
		return '<span class="#cls#" data-tip="#arguments.tip#">';
	}

	public string function uiTooltipEnd() {
		return '</span>';
	}

	// ==============================================
	// ALERTS
	// ==============================================

	/**
	 * Basecoat alert. Self-closing (returns complete element). Variants: default, destructive.
	 */
	public string function uiAlert(
		string title = "",
		string description = "",
		string variant = "default",
		string icon = "",
		string class = ""
	) {
		var local = {};
		local.cls = "alert";
		if (arguments.variant == "destructive") local.cls &= " alert-destructive";
		if (len(arguments.class)) local.cls &= " " & arguments.class;

		// Default icons by variant
		local.iconName = len(arguments.icon) ? arguments.icon : (arguments.variant == "destructive" ? "alert-triangle" : "info");

		savecontent variable="local.html" {
			writeOutput(
				'<div class="#local.cls#" role="alert">' & chr(10)
				& $uiLucideIcon(local.iconName, 16) & chr(10)
				& '<div>' & chr(10)
				& (len(arguments.title) ? '<h5>#arguments.title#</h5>' & chr(10) : '')
				& (len(arguments.description) ? '<div>#arguments.description#</div>' & chr(10) : '')
				& '</div>' & chr(10)
				& '</div>'
			);
		}
		return trim(local.html);
	}

	// ==============================================
	// CARDS
	// ==============================================

	/** Opens a Basecoat card. Close with uiCardEnd(). */
	public string function uiCard(string class = "") {
		var cls = "card";
		if (len(arguments.class)) cls &= " " & arguments.class;
		return '<div class="#cls#">';
	}

	/** Card header with optional title and description. Self-closing. */
	public string function uiCardHeader(string title = "", string description = "", string class = "") {
		var local = {};
		local.cls = "card-header";
		if (len(arguments.class)) local.cls &= " " & arguments.class;

		savecontent variable="local.html" {
			writeOutput(
				'<div class="#local.cls#">' & chr(10)
				& (len(arguments.title) ? '<h3>#arguments.title#</h3>' & chr(10) : '')
				& (len(arguments.description) ? '<p>#arguments.description#</p>' & chr(10) : '')
				& '</div>'
			);
		}
		return trim(local.html);
	}

	/** Opens card content section. Close with uiCardContentEnd(). */
	public string function uiCardContent(string class = "") {
		var cls = "card-content";
		if (len(arguments.class)) cls &= " " & arguments.class;
		return '<div class="#cls#">';
	}

	public string function uiCardContentEnd() {
		return '</div>';
	}

	/** Opens card footer section. Close with uiCardFooterEnd(). */
	public string function uiCardFooter(string class = "") {
		var cls = "card-footer";
		if (len(arguments.class)) cls &= " " & arguments.class;
		return '<div class="#cls#">';
	}

	public string function uiCardFooterEnd() {
		return '</div>';
	}

	public string function uiCardEnd() {
		return '</div>';
	}

	// ==============================================
	// PRIVATE: LUCIDE ICON SVG HELPER
	// ==============================================

	/** Returns SVG markup for a Lucide icon. Extend the icon map as needed. */
	private string function $uiLucideIcon(required string name, numeric size = 24, numeric strokeWidth = 2, string class = "") {
		var icons = {
			"plus": '<line x1="12" x2="12" y1="5" y2="19"/><line x1="5" x2="19" y1="12" y2="12"/>',
			"trash": '<path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/>',
			"pencil": '<path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"/><path d="m15 5 4 4"/>',
			"x": '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>',
			"check": '<path d="M20 6 9 17l-5-5"/>',
			"chevron-right": '<path d="m9 18 6-6-6-6"/>',
			"chevron-left": '<path d="m15 18-6-6 6-6"/>',
			"search": '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
			"loader": '<path d="M12 2v4"/><path d="m16.2 7.8 2.9-2.9"/><path d="M18 12h4"/><path d="m16.2 16.2 2.9 2.9"/><path d="M12 18v4"/><path d="m4.9 19.1 2.9-2.9"/><path d="M2 12h4"/><path d="m4.9 4.9 2.9 2.9"/>',
			"alert-triangle": '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/><path d="M12 9v4"/><path d="M12 17h.01"/>',
			"info": '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>',
			"check-circle": '<path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><path d="m9 11 3 3L22 4"/>',
			"send": '<path d="M14.536 21.686a.5.5 0 0 0 .937-.024l6.5-19a.496.496 0 0 0-.635-.635l-19 6.5a.5.5 0 0 0-.024.937l7.93 3.18a2 2 0 0 1 1.112 1.11z"/><path d="m21.854 2.147-10.94 10.939"/>',
			"ellipsis": '<circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/><circle cx="5" cy="12" r="1"/>',
			"external-link": '<path d="M15 3h6v6"/><path d="M10 14 21 3"/><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/>'
		};

		var paths = structKeyExists(icons, arguments.name) ? icons[arguments.name] : '<circle cx="12" cy="12" r="10"/>';
		var classAttr = len(arguments.class) ? ' class="#arguments.class#"' : "";
		return '<svg xmlns="http://www.w3.org/2000/svg" width="#arguments.size#" height="#arguments.size#" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="#arguments.strokeWidth#" stroke-linecap="round" stroke-linejoin="round"#classAttr#>#paths#</svg>';
	}

	// ==============================================
	// PRIVATE: ID GENERATION
	// ==============================================

	/** Generates a short unique ID if none provided. */
	private string function $uiBuildId(string providedId = "", string prefix = "ui") {
		if (len(arguments.providedId))
			return arguments.providedId;
		return arguments.prefix & "-" & replace(left(createUUID(), 8), "-", "", "all");
	}

	// ==============================================
	// DIALOGS
	// ==============================================

	/**
	 * Opens a Basecoat dialog (native <dialog> element). Close with uiDialogEnd().
	 * Optionally renders a trigger button.
	 */
	public string function uiDialog(
		required string title,
		string description = "",
		string triggerText = "",
		string triggerClass = "btn-outline",
		string id = "",
		string maxWidth = "sm:max-w-[425px]",
		string class = ""
	) {
		var local = {};
		local.id = $uiBuildId(arguments.id, "dlg");
		local.cls = "dialog w-full #arguments.maxWidth# max-h-[612px]";
		if (len(arguments.class)) local.cls &= " " & arguments.class;

		savecontent variable="local.html" {
			writeOutput(
				(len(arguments.triggerText) ? '<button type="button" onclick="document.getElementById(''#local.id#'').showModal()" class="#arguments.triggerClass#">#arguments.triggerText#</button>' & chr(10) : '')
				& '<dialog id="#local.id#" class="#local.cls#" aria-labelledby="#local.id#-title"'
				& (len(arguments.description) ? ' aria-describedby="#local.id#-desc"' : '')
				& ' onclick="if (event.target === this) this.close()">' & chr(10)
				& '<div>' & chr(10)
				& '<header>' & chr(10)
				& '<h2 id="#local.id#-title">#arguments.title#</h2>' & chr(10)
				& (len(arguments.description) ? '<p id="#local.id#-desc">#arguments.description#</p>' & chr(10) : '')
				& '</header>' & chr(10)
				& '<section>'
			);
		}
		return trim(local.html);
	}

	/** Closes the dialog content section and opens the footer section. */
	public string function uiDialogFooter() {
		return '</section><footer>';
	}

	/** Closes the dialog footer, adds the close (X) button, and closes the dialog element. */
	public string function uiDialogEnd() {
		var xIcon = $uiLucideIcon("x", 24, 2);
		return '</footer><button type="button" aria-label="Close dialog" onclick="this.closest(''dialog'').close()">#xIcon#</button></div></dialog>';
	}

	// ==============================================
	// FORM FIELDS
	// ==============================================

	/**
	 * Basecoat form field. Handles text, email, password, number, tel, url, textarea, select, checkbox, switch.
	 */
	public string function uiField(
		required string label,
		required string name,
		string type = "text",
		string value = "",
		string id = "",
		string placeholder = "",
		string description = "",
		string errorMessage = "",
		boolean required = false,
		boolean disabled = false,
		boolean checked = false,
		string options = "",
		numeric rows = 4,
		string class = ""
	) {
		var local = {};
		local.id = $uiBuildId(arguments.id, "fld");
		local.hasError = len(arguments.errorMessage);
		local.isToggle = (arguments.type == "checkbox" || arguments.type == "switch");

		// Build input attrs common to all types
		local.commonAttrs = 'id="#local.id#" name="#arguments.name#"';
		if (arguments.required) local.commonAttrs &= " required";
		if (arguments.disabled) local.commonAttrs &= " disabled";

		savecontent variable="local.html" {
			// Wrapper
			if (local.isToggle) {
				writeOutput('<div class="flex items-center gap-2">' & chr(10));
			} else {
				writeOutput('<div class="grid gap-2">' & chr(10));
			}

			// Label before input (non-toggle types)
			if (!local.isToggle)
				writeOutput('<label for="#local.id#">#arguments.label#</label>' & chr(10));

			// Input element by type
			if (arguments.type == "textarea") {
				writeOutput('<textarea #local.commonAttrs# class="textarea#local.hasError ? " border-destructive" : ""#"');
				if (len(arguments.placeholder)) writeOutput(' placeholder="#arguments.placeholder#"');
				writeOutput(' rows="#arguments.rows#"');
				if (local.hasError) writeOutput(' aria-invalid="true" aria-describedby="#local.id#-error"');
				writeOutput('>#arguments.value#</textarea>' & chr(10));
			} else if (arguments.type == "select") {
				writeOutput('<select #local.commonAttrs# class="select#local.hasError ? " border-destructive" : ""#"');
				if (local.hasError) writeOutput(' aria-invalid="true" aria-describedby="#local.id#-error"');
				writeOutput('>' & chr(10));
				if (len(arguments.options)) {
					for (var opt in listToArray(arguments.options)) {
						var optParts = listToArray(opt, ":");
						var optVal = optParts[1];
						var optLabel = (arrayLen(optParts) > 1) ? optParts[2] : optParts[1];
						writeOutput('<option value="#optVal#"#arguments.value == optVal ? " selected" : ""#>#optLabel#</option>' & chr(10));
					}
				}
				writeOutput('</select>' & chr(10));
			} else if (arguments.type == "checkbox") {
				writeOutput('<input type="checkbox" #local.commonAttrs# class="checkbox#len(arguments.class) ? " " & arguments.class : ""#"');
				if (arguments.checked) writeOutput(' checked');
				if (local.hasError) writeOutput(' aria-invalid="true" aria-describedby="#local.id#-error"');
				writeOutput(' />' & chr(10));
			} else if (arguments.type == "switch") {
				writeOutput('<input type="checkbox" #local.commonAttrs# class="switch#len(arguments.class) ? " " & arguments.class : ""#" role="switch"');
				if (arguments.checked) writeOutput(' checked');
				if (local.hasError) writeOutput(' aria-invalid="true" aria-describedby="#local.id#-error"');
				writeOutput(' />' & chr(10));
			} else {
				writeOutput('<input type="#arguments.type#" #local.commonAttrs# class="input#local.hasError ? " border-destructive" : ""#"');
				if (len(arguments.value)) writeOutput(' value="#arguments.value#"');
				if (len(arguments.placeholder)) writeOutput(' placeholder="#arguments.placeholder#"');
				if (local.hasError) writeOutput(' aria-invalid="true" aria-describedby="#local.id#-error"');
				if (len(arguments.class)) writeOutput(' #arguments.class#');
				writeOutput(' />' & chr(10));
			}

			// Label after input (toggle types)
			if (local.isToggle)
				writeOutput('<label for="#local.id#">#arguments.label#</label>' & chr(10));

			// Description (only when no error)
			if (len(arguments.description) && !local.hasError)
				writeOutput('<p class="text-sm text-muted-foreground">#arguments.description#</p>' & chr(10));

			// Error message
			if (local.hasError)
				writeOutput('<p id="#local.id#-error" class="text-sm text-destructive">#arguments.errorMessage#</p>' & chr(10));

			writeOutput('</div>');
		}
		return trim(local.html);
	}

	// ==============================================
	// TABLES
	// ==============================================

	/** Opens a Basecoat table (table-container + table). Close with uiTableEnd(). */
	public string function uiTable(string class = "") {
		var cls = "table";
		if (len(arguments.class)) cls &= " " & arguments.class;
		return '<div class="table-container"><table class="#cls#">';
	}

	/** Opens the table thead and a tr. Close with uiTableHeaderEnd(). */
	public string function uiTableHeader() {
		return '<thead><tr>';
	}

	public string function uiTableHeaderEnd() {
		return '</tr></thead>';
	}

	/** Opens the table tbody. Close with uiTableBodyEnd(). */
	public string function uiTableBody() {
		return '<tbody>';
	}

	public string function uiTableBodyEnd() {
		return '</tbody>';
	}

	/** Opens a table tr. Close with uiTableRowEnd(). */
	public string function uiTableRow(string class = "") {
		if (len(arguments.class))
			return '<tr class="#arguments.class#">';
		return '<tr>';
	}

	public string function uiTableRowEnd() {
		return '</tr>';
	}

	/** Renders a th cell. */
	public string function uiTableHead(string text = "", string class = "") {
		if (len(arguments.class))
			return '<th class="#arguments.class#">#arguments.text#</th>';
		return '<th>#arguments.text#</th>';
	}

	/** Renders a td cell. */
	public string function uiTableCell(string text = "", string class = "") {
		if (len(arguments.class))
			return '<td class="#arguments.class#">#arguments.text#</td>';
		return '<td>#arguments.text#</td>';
	}

	public string function uiTableEnd() {
		return '</table></div>';
	}

	// ==============================================
	// TABS
	// ==============================================

	/** Opens a Basecoat tabs container. Close with uiTabsEnd(). */
	public string function uiTabs(string defaultTab = "", string class = "") {
		var cls = "tabs";
		if (len(arguments.class)) cls &= " " & arguments.class;
		var dataDefault = len(arguments.defaultTab) ? ' data-default="#arguments.defaultTab#"' : "";
		return '<div class="#cls#"#dataDefault#>';
	}

	/** Opens the tabs-list container. Close with uiTabListEnd(). */
	public string function uiTabList(string class = "") {
		var cls = "tabs-list";
		if (len(arguments.class)) cls &= " " & arguments.class;
		return '<div class="#cls#">';
	}

	public string function uiTabListEnd() {
		return '</div>';
	}

	/** Renders a tab trigger button. */
	public string function uiTabTrigger(required string value, required string text, string class = "") {
		var cls = "tabs-trigger";
		if (len(arguments.class)) cls &= " " & arguments.class;
		return '<button class="#cls#" data-value="#arguments.value#">#arguments.text#</button>';
	}

	/** Opens a tab content panel. Close with uiTabContentEnd(). */
	public string function uiTabContent(required string value, string class = "") {
		var cls = "tabs-content";
		if (len(arguments.class)) cls &= " " & arguments.class;
		return '<div class="#cls#" data-value="#arguments.value#">';
	}

	public string function uiTabContentEnd() {
		return '</div>';
	}

	public string function uiTabsEnd() {
		return '</div>';
	}

	// ==============================================
	// DROPDOWNS
	// ==============================================

	/** Opens a CSS-only dropdown (details/summary). Close with uiDropdownEnd(). */
	public string function uiDropdown(required string text, string triggerClass = "btn-outline", string class = "") {
		var cls = "dropdown";
		if (len(arguments.class)) cls &= " " & arguments.class;
		return '<details class="#cls#"><summary class="#arguments.triggerClass#">#arguments.text#</summary><ul>';
	}

	/** Renders a dropdown menu item. */
	public string function uiDropdownItem(required string text, string href = "##", string class = "") {
		var clsAttr = len(arguments.class) ? ' class="#arguments.class#"' : "";
		return '<li><a href="#arguments.href#"#clsAttr#>#arguments.text#</a></li>';
	}

	/** Renders a separator line inside a dropdown. */
	public string function uiDropdownSeparator() {
		return '<li><hr class="separator" /></li>';
	}

	public string function uiDropdownEnd() {
		return '</ul></details>';
	}

	// ==============================================
	// PAGINATION
	// ==============================================

	/**
	 * Renders a pagination nav with prev/next, page window, and ellipsis.
	 */
	public string function uiPagination(
		required numeric currentPage,
		required numeric totalPages,
		required string baseUrl,
		string pageParam = "page",
		numeric windowSize = 2,
		string class = ""
	) {
		var local = {};
		local.cls = "pagination";
		if (len(arguments.class)) local.cls &= " " & arguments.class;

		// URL builder helper
		local.sep = (find("?", arguments.baseUrl) > 0) ? "&" : "?";
		local.prevIcon = $uiLucideIcon("chevron-left", 16, 2);
		local.nextIcon = $uiLucideIcon("chevron-right", 16, 2);

		savecontent variable="local.html" {
			writeOutput('<nav class="#local.cls#" aria-label="Pagination">' & chr(10));

			// Previous
			if (arguments.currentPage <= 1) {
				writeOutput('<span class="pagination-item opacity-50" aria-disabled="true">#local.prevIcon#</span>' & chr(10));
			} else {
				writeOutput('<a href="#arguments.baseUrl##local.sep##arguments.pageParam#=#arguments.currentPage - 1#" class="pagination-item" aria-label="Previous page">#local.prevIcon#</a>' & chr(10));
			}

			// Page window
			local.windowStart = max(1, arguments.currentPage - arguments.windowSize);
			local.windowEnd = min(arguments.totalPages, arguments.currentPage + arguments.windowSize);

			// First page + ellipsis
			if (local.windowStart > 1) {
				writeOutput('<a href="#arguments.baseUrl##local.sep##arguments.pageParam#=1" class="pagination-item">1</a>');
				if (local.windowStart > 2)
					writeOutput('<span class="pagination-item" aria-hidden="true">&hellip;</span>' & chr(10));
			}

			// Page numbers
			for (var p = local.windowStart; p <= local.windowEnd; p++) {
				if (p == arguments.currentPage) {
					writeOutput('<span class="pagination-item pagination-item-active" aria-current="page">#p#</span>' & chr(10));
				} else {
					writeOutput('<a href="#arguments.baseUrl##local.sep##arguments.pageParam#=#p#" class="pagination-item">#p#</a>' & chr(10));
				}
			}

			// Last page + ellipsis
			if (local.windowEnd < arguments.totalPages) {
				if (local.windowEnd < arguments.totalPages - 1)
					writeOutput('<span class="pagination-item" aria-hidden="true">&hellip;</span>' & chr(10));
				writeOutput('<a href="#arguments.baseUrl##local.sep##arguments.pageParam#=#arguments.totalPages#" class="pagination-item">#arguments.totalPages#</a>' & chr(10));
			}

			// Next
			if (arguments.currentPage >= arguments.totalPages) {
				writeOutput('<span class="pagination-item opacity-50" aria-disabled="true">#local.nextIcon#</span>' & chr(10));
			} else {
				writeOutput('<a href="#arguments.baseUrl##local.sep##arguments.pageParam#=#arguments.currentPage + 1#" class="pagination-item" aria-label="Next page">#local.nextIcon#</a>' & chr(10));
			}

			writeOutput('</nav>');
		}
		return trim(local.html);
	}

	// ==============================================
	// BREADCRUMB
	// ==============================================

	/** Opens a Basecoat breadcrumb nav. Close with uiBreadcrumbEnd(). */
	public string function uiBreadcrumb(string class = "") {
		var cls = "breadcrumb";
		if (len(arguments.class)) cls &= " " & arguments.class;
		return '<nav aria-label="Breadcrumb" class="#cls#"><ol>';
	}

	/** Renders a breadcrumb item. Omit href for the current (last) page. */
	public string function uiBreadcrumbItem(required string text, string href = "") {
		if (len(arguments.href))
			return '<li><a href="#arguments.href#">#arguments.text#</a></li>';
		return '<li><span aria-current="page">#arguments.text#</span></li>';
	}

	/** Renders a breadcrumb separator (chevron-right icon). */
	public string function uiBreadcrumbSeparator() {
		var icon = $uiLucideIcon("chevron-right", 14, 2);
		return '<li aria-hidden="true">#icon#</li>';
	}

	public string function uiBreadcrumbEnd() {
		return '</ol></nav>';
	}

	// ==============================================
	// SIDEBAR
	// ==============================================

	/** Opens a Basecoat sidebar (aside + nav). Close with uiSidebarEnd(). */
	public string function uiSidebar(string class = "") {
		var cls = "sidebar";
		if (len(arguments.class)) cls &= " " & arguments.class;
		return '<aside class="#cls#"><nav>';
	}

	/** Opens a sidebar section with optional heading. Close with uiSidebarSectionEnd(). */
	public string function uiSidebarSection(string title = "", string class = "") {
		var cls = "sidebar-section";
		if (len(arguments.class)) cls &= " " & arguments.class;
		var heading = len(arguments.title) ? '<h4>#arguments.title#</h4>' : "";
		return '<div class="#cls#">#heading#<ul>';
	}

	public string function uiSidebarSectionEnd() {
		return '</ul></div>';
	}

	/** Renders a sidebar navigation item. */
	public string function uiSidebarItem(
		required string text,
		string href = "##",
		string icon = "",
		boolean active = false,
		string class = ""
	) {
		var cls = "sidebar-item";
		if (arguments.active) cls &= " sidebar-item-active";
		if (len(arguments.class)) cls &= " " & arguments.class;
		var iconHtml = len(arguments.icon) ? $uiLucideIcon(arguments.icon, 16, 2) & " " : "";
		return '<li><a href="#arguments.href#" class="#cls#">#iconHtml##arguments.text#</a></li>';
	}

	public string function uiSidebarEnd() {
		return '</nav></aside>';
	}

}
