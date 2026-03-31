/**
 * Generates admin index and show view files from model introspection metadata.
 *
 * Consumes the output of AdminIntrospectionService.introspect() and produces
 * type-aware admin views with sortable columns, search, pagination, and
 * association display.
 *
 * Usage (WireBox):
 *   adminViewService.generateIndexView(metadata=introspectionResult, baseDirectory=appRoot)
 *
 * Usage (standalone / testing):
 *   var svc = new AdminViewService(helpers=helpersInstance, templateDir="/path/to/templates")
 *   var content = svc.renderIndexContent(metadata=introspectionResult)
 */
component {

	property name="templateService" inject="TemplateService@wheels-cli";
	property name="helpers" inject="helpers@wheels-cli";

	/**
	 * Initialize for standalone usage (testing, lucli).
	 */
	public function init(any helpers, any templateService, string templateDir = "") {
		if (!isNull(arguments.helpers)) variables.helpers = arguments.helpers;
		if (!isNull(arguments.templateService)) variables.templateService = arguments.templateService;
		if (len(arguments.templateDir)) variables.templateDir = arguments.templateDir;
		return this;
	}

	// ── Public API: file generation ──────────────

	/**
	 * Generate admin index view file from introspection metadata.
	 *
	 * @metadata Struct from AdminIntrospectionService.introspect()
	 * @baseDirectory Application root directory
	 * @return {success: boolean, path: string, message|error: string}
	 */
	public struct function generateIndexView(
		required struct metadata,
		string baseDirectory = ""
	) {
		var context = buildIndexContext(arguments.metadata);
		var pluralLower = lCase(pluralizeWord(arguments.metadata.modelName));
		try {
			var path = variables.templateService.generateFromTemplate(
				template = "admin/index.txt",
				destination = "views/admin/#pluralLower#/index.cfm",
				context = context,
				baseDirectory = arguments.baseDirectory
			);
			return {success: true, path: path, message: "Admin index view generated"};
		} catch (any e) {
			return {success: false, error: e.message, path: ""};
		}
	}

	/**
	 * Generate admin show view file from introspection metadata.
	 *
	 * @metadata Struct from AdminIntrospectionService.introspect()
	 * @baseDirectory Application root directory
	 * @return {success: boolean, path: string, message|error: string}
	 */
	public struct function generateShowView(
		required struct metadata,
		string baseDirectory = ""
	) {
		var context = buildShowContext(arguments.metadata);
		var pluralLower = lCase(pluralizeWord(arguments.metadata.modelName));
		try {
			var path = variables.templateService.generateFromTemplate(
				template = "admin/show.txt",
				destination = "views/admin/#pluralLower#/show.cfm",
				context = context,
				baseDirectory = arguments.baseDirectory
			);
			return {success: true, path: path, message: "Admin show view generated"};
		} catch (any e) {
			return {success: false, error: e.message, path: ""};
		}
	}

	// ── Public API: content rendering (testing) ──

	/**
	 * Render admin index view content as string without writing to disk.
	 */
	public string function renderIndexContent(required struct metadata) {
		var context = buildIndexContext(arguments.metadata);
		var templateContent = readTemplate("admin/index.txt");
		return processAdminTemplate(templateContent, context, arguments.metadata.modelName);
	}

	/**
	 * Render admin show view content as string without writing to disk.
	 */
	public string function renderShowContent(required struct metadata) {
		var context = buildShowContext(arguments.metadata);
		var templateContent = readTemplate("admin/show.txt");
		return processAdminTemplate(templateContent, context, arguments.metadata.modelName);
	}

	// ── Context builders ────────────────────────

	private struct function buildIndexContext(required struct metadata) {
		return {
			modelName: capitalize(arguments.metadata.modelName),
			AdminTableHeaders: buildSortableHeaders(arguments.metadata.fields),
			AdminTableCells: buildTypedTableCells(arguments.metadata.fields)
		};
	}

	private struct function buildShowContext(required struct metadata) {
		return {
			modelName: capitalize(arguments.metadata.modelName),
			AdminShowFields: buildShowFieldRows(arguments.metadata.fields),
			AdminAssociationSections: buildAssociationSections(arguments.metadata.associations)
		};
	}

	// ── Index view: sortable headers ────────────

	/**
	 * Build sortable table header columns.
	 * Uses the _sortLink() helper defined in admin/index.txt.
	 */
	private string function buildSortableHeaders(required array fields) {
		var h = chr(35);
		var nl = chr(10);
		var indent = repeatString(chr(9), 7);
		var headers = [];

		for (var field in arguments.fields) {
			if (!field.inList || field.isPrimaryKey) continue;
			arrayAppend(headers,
				indent & "<th>" & h & '_sortLink("' & field.name & '", "' & field.label & '")' & h & "</th>"
			);
		}

		return arrayToList(headers, nl);
	}

	// ── Index view: typed table cells ───────────

	/**
	 * Build type-aware table cells for the admin index view.
	 * Each cell renders the field value with appropriate formatting.
	 */
	private string function buildTypedTableCells(required array fields) {
		var nl = chr(10);
		var indent = repeatString(chr(9), 7);
		var cells = [];

		for (var field in arguments.fields) {
			if (!field.inList || field.isPrimaryKey) continue;
			arrayAppend(cells, indent & "<td>" & formatCellForType(field) & "</td>");
		}

		return arrayToList(cells, nl);
	}

	/**
	 * Render a single table cell based on field type metadata.
	 */
	private string function formatCellForType(required struct field) {
		var h = chr(35);
		var qv = "|ObjectNamePlural|." & field.name;

		// Foreign key — show associated model name
		if (field.isForeignKey && len(field.foreignKeyTo)) {
			return h & "encodeForHTML(|ObjectNamePlural|." & lCase(field.foreignKeyTo) & ".name)" & h;
		}

		// Enum — badge
		if (field.isEnum) {
			return '<span class="badge bg-info">' & h & "encodeForHTML(" & qv & ")" & h & "</span>";
		}

		// Boolean — Yes/No badges
		if (field.dataType == "boolean" || field.inputType == "checkbox") {
			return chr(60) & 'cfif |ObjectNamePlural|.' & field.name
				& '><span class="badge bg-success">Yes</span>'
				& chr(60) & 'cfelse><span class="badge bg-secondary">No</span>' & chr(60) & '/cfif>';
		}

		// Email — mailto link
		if (field.inputType == "email") {
			return '<a href="mailto:' & h & "encodeForHTML(" & qv & ")" & h & '">'
				& h & "encodeForHTML(" & qv & ")" & h & "</a>";
		}

		// Date
		if (field.inputType == "date") {
			return h & 'dateFormat(' & qv & ', "yyyy-mm-dd")' & h;
		}

		// Datetime / timestamp
		if (field.inputType == "datetime-local" || field.dataType == "datetime" || field.dataType == "timestamp") {
			return h & 'dateTimeFormat(' & qv & ', "yyyy-mm-dd HH:nn")' & h;
		}

		// Time
		if (field.inputType == "time") {
			return h & 'timeFormat(' & qv & ', "HH:nn:ss")' & h;
		}

		// Text / textarea — truncate in list view (encode after truncating to avoid splitting HTML entities)
		if (field.inputType == "textarea" || field.dataType == "text") {
			return h & "encodeForHTML(left(" & qv & ", 100))" & h;
		}

		// Default — encode for safety
		return h & "encodeForHTML(" & qv & ")" & h;
	}

	// ── Show view: detail field rows ────────────

	/**
	 * Build detail table rows for the admin show view.
	 * Each row displays a label and type-aware value.
	 */
	private string function buildShowFieldRows(required array fields) {
		var nl = chr(10);
		var indent = repeatString(chr(9), 5);
		var rows = [];

		for (var field in arguments.fields) {
			if (!field.inShow) continue;
			var row = indent & "<tr>" & nl;
			row &= indent & chr(9) & '<th class="w-25">' & field.label & "</th>" & nl;
			row &= indent & chr(9) & "<td>" & formatShowValueForType(field) & "</td>" & nl;
			row &= indent & "</tr>";
			arrayAppend(rows, row);
		}

		return arrayToList(rows, nl);
	}

	/**
	 * Render a single show value based on field type metadata.
	 */
	private string function formatShowValueForType(required struct field) {
		var h = chr(35);
		var ov = "|ObjectNameSingular|." & field.name;

		// Primary key — display as-is
		if (field.isPrimaryKey) {
			return h & ov & h;
		}

		// Foreign key — show associated model name
		if (field.isForeignKey && len(field.foreignKeyTo)) {
			return h & "encodeForHTML(|ObjectNameSingular|." & lCase(field.foreignKeyTo) & ".name)" & h;
		}

		// Enum — badge
		if (field.isEnum) {
			return '<span class="badge bg-info">' & h & "encodeForHTML(" & ov & ")" & h & "</span>";
		}

		// Boolean — yesNoFormat
		if (field.dataType == "boolean" || field.inputType == "checkbox") {
			return h & "yesNoFormat(" & ov & ")" & h;
		}

		// Email — mailto link
		if (field.inputType == "email") {
			return '<a href="mailto:' & h & "encodeForHTML(" & ov & ")" & h & '">'
				& h & "encodeForHTML(" & ov & ")" & h & "</a>";
		}

		// URL — hyperlink
		if (field.inputType == "url") {
			return '<a href="' & h & "encodeForHTML(" & ov & ")" & h & '" target="_blank">'
				& h & "encodeForHTML(" & ov & ")" & h & "</a>";
		}

		// Date
		if (field.inputType == "date") {
			return h & 'dateFormat(' & ov & ', "yyyy-mm-dd")' & h;
		}

		// Datetime / timestamp
		if (field.inputType == "datetime-local" || field.dataType == "datetime" || field.dataType == "timestamp") {
			return h & 'dateTimeFormat(' & ov & ', "yyyy-mm-dd HH:nn:ss")' & h;
		}

		// Time
		if (field.inputType == "time") {
			return h & 'timeFormat(' & ov & ', "HH:nn:ss")' & h;
		}

		// Text — full display with word break
		if (field.inputType == "textarea" || field.dataType == "text") {
			return '<div class="text-break">' & h & "encodeForHTML(" & ov & ")" & h & "</div>";
		}

		// Default — encode for safety
		return h & "encodeForHTML(" & ov & ")" & h;
	}

	// ── Show view: association sections ──────────

	/**
	 * Build association display sections for the show view.
	 * HasMany/HasOne associations get card placeholders.
	 * BelongsTo associations are already displayed as fields via foreign key handling.
	 */
	private string function buildAssociationSections(required array associations) {
		var nl = chr(10);
		var sections = [];

		for (var assoc in arguments.associations) {
			if (assoc.type == "hasMany") {
				arrayAppend(sections, buildHasManySection(assoc));
			} else if (assoc.type == "hasOne") {
				arrayAppend(sections, buildHasOneSection(assoc));
			}
		}

		return arrayToList(sections, nl & nl);
	}

	private string function buildHasManySection(required struct assoc) {
		var nl = chr(10);
		var t = chr(9);
		var label = humanizeWord(assoc.name);
		var section = t & '<div class="card mb-4">' & nl;
		section &= t & t & '<div class="card-header d-flex justify-content-between align-items-center">' & nl;
		section &= t & t & t & '<h5 class="mb-0">' & label & '</h5>' & nl;
		section &= t & t & '</div>' & nl;
		section &= t & t & '<div class="card-body">' & nl;
		section &= t & t & t & '<p class="text-muted">Associated ' & lCase(label) & ' records. Customize this section to display related data.</p>' & nl;
		section &= t & t & '</div>' & nl;
		section &= t & '</div>';
		return section;
	}

	private string function buildHasOneSection(required struct assoc) {
		var nl = chr(10);
		var t = chr(9);
		var label = humanizeWord(assoc.name);
		var section = t & '<div class="card mb-4">' & nl;
		section &= t & t & '<div class="card-header">' & nl;
		section &= t & t & t & '<h5 class="mb-0">' & label & '</h5>' & nl;
		section &= t & t & '</div>' & nl;
		section &= t & t & '<div class="card-body">' & nl;
		section &= t & t & t & '<p class="text-muted">Associated ' & lCase(label) & ' record. Customize this section to display related data.</p>' & nl;
		section &= t & t & '</div>' & nl;
		section &= t & '</div>';
		return section;
	}

	// ── Template processing (standalone mode) ───

	/**
	 * Read template file from the configured template directory.
	 */
	private string function readTemplate(required string templateName) {
		if (structKeyExists(variables, "templateDir") && len(variables.templateDir)) {
			var path = variables.templateDir;
			if (right(path, 1) != "/" && right(path, 1) != "\") path &= "/";
			path &= arguments.templateName;
			if (fileExists(path)) return fileRead(path);
		}
		throw(type="AdminViewService.TemplateNotFound", message="Template not found: #arguments.templateName#");
	}

	/**
	 * Process admin template: replace admin markers and |ObjectName| placeholders.
	 * Used by render*Content() methods for standalone operation.
	 */
	private string function processAdminTemplate(
		required string content,
		required struct context,
		required string modelName
	) {
		var processed = arguments.content;

		// Replace {{key}} markers with generated content
		for (var key in arguments.context) {
			var value = arguments.context[key];
			if (isSimpleValue(value)) {
				processed = replace(processed, "{{" & key & "}}", value, "all");
			}
		}

		// Replace |ObjectName| pipe placeholders
		var name = capitalize(arguments.modelName);
		var plural = pluralizeWord(name);
		processed = replace(processed, "|ObjectNameSingular|", lCase(name), "all");
		processed = replace(processed, "|ObjectNamePlural|", lCase(plural), "all");
		processed = replace(processed, "|ObjectNameSingularC|", name, "all");
		processed = replace(processed, "|ObjectNamePluralC|", plural, "all");

		return processed;
	}

	// ── Utility methods (with injection fallbacks) ──

	private string function capitalize(required string str) {
		if (structKeyExists(variables, "helpers") && isObject(variables.helpers)) {
			return variables.helpers.capitalize(arguments.str);
		}
		if (len(arguments.str) == 0) return "";
		return uCase(left(arguments.str, 1)) & mid(arguments.str, 2, len(arguments.str) - 1);
	}

	private string function pluralizeWord(required string word) {
		if (structKeyExists(variables, "helpers") && isObject(variables.helpers)) {
			return variables.helpers.pluralize(arguments.word);
		}
		return arguments.word & "s";
	}

	private string function humanizeWord(required string text) {
		if (structKeyExists(variables, "helpers") && isObject(variables.helpers)) {
			return variables.helpers.humanize(arguments.text);
		}
		var result = reReplace(arguments.text, "([A-Z])", " \1", "all");
		result = trim(result);
		if (len(result) == 0) return "";
		return uCase(left(result, 1)) & mid(result, 2, len(result) - 1);
	}

}
