/**
 * Integration tests for the admin generator against live model instances.
 *
 * Tests the full admin generator pipeline using real Wheels models (Author, Post)
 * from the test suite. Exercises: model introspection via classInfo(), admin metadata
 * construction, controller template processing, view template processing, and route
 * injection -- all with data from running model instances rather than mock metadata.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		g = application.wo;

		// Resolve template directory via physical path from webroot
		var webrootDir = getDirectoryFromPath(expandPath("/"));
		variables.repoRoot = createObject("java", "java.io.File").init(webrootDir & "../").getCanonicalPath() & "/";
		variables.templateDir = variables.repoRoot & "cli/src/templates";
		variables.controllerTemplatePath = variables.templateDir & "/admin/AdminControllerContent.txt";

		// Create temp directory for route injection tests
		variables.tempDir = getTempDirectory() & "admin_integ_" & createUUID() & "/";
		directoryCreate(variables.tempDir, true);
		directoryCreate(variables.tempDir & "config/", true);
	}

	function afterAll() {
		if (structKeyExists(variables, "tempDir") && directoryExists(variables.tempDir)) {
			directoryDelete(variables.tempDir, true);
		}
	}

	function run() {

		// ── Model introspection: Author ──────────────

		describe("Author model introspection for admin", function() {

			it("returns model name and table", function() {
				var info = g.model("author").classInfo();
				expect(info.modelName).toBe("author");
				expect(len(info.tableName)).toBeGT(0);
			});

			it("has properties with column metadata", function() {
				var info = g.model("author").classInfo();
				expect(info.properties).toBeStruct();
				expect(info.properties).toHaveKey("firstName");
				expect(info.properties.firstName).toHaveKey("column");
			});

			it("has hasMany and hasOne associations", function() {
				var info = g.model("author").classInfo();
				expect(info.associations).toHaveKey("posts");
				expect(info.associations.posts.type).toBe("hasMany");
				expect(info.associations).toHaveKey("profile");
				expect(info.associations.profile.type).toBe("hasOne");
			});

			it("has firstName presence validation", function() {
				var info = g.model("author").classInfo();
				var foundPresence = false;
				for (var rule in info.validations.onSave) {
					if (structKeyExists(rule, "method") && rule.method == "$validatesPresenceOf"
						&& structKeyExists(rule, "args") && structKeyExists(rule.args, "property")
						&& rule.args.property == "firstName") {
						foundPresence = true;
					}
				}
				expect(foundPresence).toBeTrue();
			});

			it("builds admin metadata with required keys", function() {
				var meta = buildAdminMetadata(g.model("author").classInfo());
				expect(meta).toHaveKey("modelName");
				expect(meta).toHaveKey("pluralName");
				expect(meta).toHaveKey("tableName");
				expect(meta).toHaveKey("primaryKey");
				expect(meta).toHaveKey("fields");
				expect(meta).toHaveKey("associations");
				expect(meta).toHaveKey("validationSummary");
			});

			it("marks PK field as not in form", function() {
				var meta = buildAdminMetadata(g.model("author").classInfo());
				var found = false;
				for (var f in meta.fields) {
					if (f.isPrimaryKey) {
						found = true;
						expect(f.inForm).toBeFalse();
						expect(f.inList).toBeFalse();
					}
				}
				expect(found).toBeTrue();
			});

			it("assigns text input type to firstName", function() {
				var meta = buildAdminMetadata(g.model("author").classInfo());
				var f = findFieldByName(meta.fields, "firstName");
				expect(f).toHaveKey("inputType");
				expect(f.inputType).toBe("text");
				expect(f.inForm).toBeTrue();
			});

			it("detects firstName required via validations", function() {
				var meta = buildAdminMetadata(g.model("author").classInfo());
				expect(meta.validationSummary).toHaveKey("firstName");
				expect(meta.validationSummary.firstName).toHaveKey("presence");
			});

			it("builds hasMany and hasOne in associations", function() {
				var meta = buildAdminMetadata(g.model("author").classInfo());
				var hasMany = false;
				var hasOne = false;
				for (var a in meta.associations) {
					if (a.type == "hasMany") hasMany = true;
					if (a.type == "hasOne") hasOne = true;
				}
				expect(hasMany).toBeTrue();
				expect(hasOne).toBeTrue();
			});
		});

		// ── Model introspection: Post ────────────────

		describe("Post model introspection for admin", function() {

			it("returns correct model name", function() {
				expect(g.model("post").classInfo().modelName).toBe("post");
			});

			it("has belongsTo author association", function() {
				var info = g.model("post").classInfo();
				expect(info.associations).toHaveKey("author");
				expect(info.associations.author.type).toBe("belongsTo");
			});

			it("detects uniqueness validation on title", function() {
				var meta = buildAdminMetadata(g.model("post").classInfo());
				expect(meta.validationSummary).toHaveKey("title");
				expect(meta.validationSummary.title).toHaveKey("uniqueness");
			});

			it("detects foreign key field from belongsTo", function() {
				var meta = buildAdminMetadata(g.model("post").classInfo());
				var fkFound = false;
				for (var f in meta.fields) {
					if (f.isForeignKey) {
						fkFound = true;
						expect(f.inputType).toBe("select");
					}
				}
				expect(fkFound).toBeTrue();
			});

			it("assigns number input type to views field", function() {
				var meta = buildAdminMetadata(g.model("post").classInfo());
				var f = findFieldByName(meta.fields, "views");
				if (structKeyExists(f, "inputType")) {
					expect(f.inputType).toBe("number");
				}
			});

			it("produces different metadata than Author", function() {
				var authorMeta = buildAdminMetadata(g.model("author").classInfo());
				var postMeta = buildAdminMetadata(g.model("post").classInfo());
				expect(postMeta.modelName).notToBe(authorMeta.modelName);
				expect(postMeta.tableName).notToBe(authorMeta.tableName);
			});
		});

		// ── Controller template processing ───────────

		describe("Admin controller template with Author", function() {

			it("has no unresolved placeholders", function() {
				var meta = buildAdminMetadata(g.model("author").classInfo());
				var c = processControllerTemplate("Author", meta);
				expect(c).notToInclude("|ObjectNameSingular|");
				expect(c).notToInclude("|ObjectNamePlural|");
				expect(c).notToInclude("|ObjectNameSingularC|");
				expect(c).notToInclude("|ObjectNamePluralC|");
				expect(c).notToInclude("|SearchWhereClause|");
				expect(c).notToInclude("|ForeignKeyLoaders|");
				expect(c).notToInclude("|DescriptionComment|");
			});

			it("includes CSRF protection", function() {
				var meta = buildAdminMetadata(g.model("author").classInfo());
				expect(processControllerTemplate("Author", meta)).toInclude("protectsFromForgery()");
			});

			it("references model('Author')", function() {
				var meta = buildAdminMetadata(g.model("author").classInfo());
				var c = processControllerTemplate("Author", meta);
				expect(c).toInclude('model("Author")');
				expect(c).toInclude("params.author");
			});

			it("includes all CRUD actions", function() {
				var meta = buildAdminMetadata(g.model("author").classInfo());
				var c = processControllerTemplate("Author", meta);
				expect(c).toInclude("function index()");
				expect(c).toInclude("function show()");
				expect(c).toInclude("function create()");
				expect(c).toInclude("function edit()");
				expect(c).toInclude("function update()");
				expect(c).toInclude("function delete()");
			});

			it("includes search WHERE clause with LIKE", function() {
				var meta = buildAdminMetadata(g.model("author").classInfo());
				var c = processControllerTemplate("Author", meta);
				expect(c).toInclude("LIKE");
				expect(c).toInclude("sanitizedQ");
			});

			it("includes sort and pagination", function() {
				var meta = buildAdminMetadata(g.model("author").classInfo());
				var c = processControllerTemplate("Author", meta);
				expect(c).toInclude("reFindNoCase");
				expect(c).toInclude("params.page");
				expect(c).toInclude("perPage");
			});
		});

		describe("Admin controller template with Post", function() {

			it("references model('Post') and params.post", function() {
				var meta = buildAdminMetadata(g.model("post").classInfo());
				var c = processControllerTemplate("Post", meta);
				expect(c).toInclude('model("Post")');
				expect(c).toInclude("params.post");
			});

			it("includes FK loaders for author", function() {
				var meta = buildAdminMetadata(g.model("post").classInfo());
				var c = processControllerTemplate("Post", meta);
				expect(c).toInclude('model("author")');
			});

			it("has no unresolved placeholders", function() {
				var meta = buildAdminMetadata(g.model("post").classInfo());
				var c = processControllerTemplate("Post", meta);
				expect(c).notToInclude("|ObjectNameSingular|");
				expect(c).notToInclude("|ObjectNamePlural|");
			});
		});

		// ── View template processing ─────────────────

		describe("Admin view templates with live metadata", function() {

			it("generates Author index with search and pagination", function() {
				var meta = buildAdminMetadata(g.model("author").classInfo());
				var c = processViewTemplate("index", "Author", meta);
				expect(len(c)).toBeGT(100);
				expect(c).toInclude("<cfoutput>");
				expect(c).toInclude('name="q"');
				expect(c).toInclude("paginationNav()");
			});

			it("generates Author show with Detail heading", function() {
				var meta = buildAdminMetadata(g.model("author").classInfo());
				var c = processViewTemplate("show", "Author", meta);
				expect(c).toInclude("Detail");
				expect(c).toInclude("Back to List");
				expect(c).toInclude('method="delete"');
			});

			it("generates Post index and show views", function() {
				var meta = buildAdminMetadata(g.model("post").classInfo());
				expect(len(processViewTemplate("index", "Post", meta))).toBeGT(100);
				expect(len(processViewTemplate("show", "Post", meta))).toBeGT(100);
			});

			it("all admin templates exist on disk", function() {
				expect(fileExists(variables.controllerTemplatePath)).toBeTrue();
				expect(fileExists(variables.templateDir & "/admin/index.txt")).toBeTrue();
				expect(fileExists(variables.templateDir & "/admin/show.txt")).toBeTrue();
				expect(fileExists(variables.templateDir & "/admin/_form.txt")).toBeTrue();
				expect(fileExists(variables.templateDir & "/admin/new.txt")).toBeTrue();
				expect(fileExists(variables.templateDir & "/admin/edit.txt")).toBeTrue();
			});
		});

		// ── Route injection ──────────────────────────

		describe("Admin route injection", function() {

			it("creates admin scope for first resource", function() {
				var p = variables.tempDir & "config/routes1.cfm";
				fileWrite(p, buildRoutesFile());
				expect(injectAdminRoute("authors", p)).toBeTrue();
				var updated = fileRead(p);
				expect(updated).toInclude('.scope(path="admin", package="admin")');
				expect(updated).toInclude('.resources("authors")');
			});

			it("adds second resource to existing scope", function() {
				var p = variables.tempDir & "config/routes2.cfm";
				fileWrite(p, buildRoutesFile());
				injectAdminRoute("authors", p);
				expect(injectAdminRoute("posts", p)).toBeTrue();
				var updated = fileRead(p);
				expect(updated).toInclude('.resources("authors")');
				expect(updated).toInclude('.resources("posts")');
			});

			it("prevents duplicate injection", function() {
				var p = variables.tempDir & "config/routes3.cfm";
				fileWrite(p, buildRoutesFile());
				injectAdminRoute("authors", p);
				expect(injectAdminRoute("authors", p)).toBeFalse();
			});
		});

		// ── Cross-model consistency ──────────────────

		describe("Cross-model admin generation", function() {

			it("valid field structure for Author and Post", function() {
				var models = ["author", "post"];
				for (var mn in models) {
					var meta = buildAdminMetadata(g.model(mn).classInfo());
					expect(meta).toHaveKey("fields");
					for (var field in meta.fields) {
						expect(field).toHaveKey("name");
						expect(field).toHaveKey("inputType");
						expect(field).toHaveKey("isPrimaryKey");
						expect(field).toHaveKey("isForeignKey");
						expect(field).toHaveKey("inForm");
						expect(field).toHaveKey("inShow");
					}
				}
			});

			it("complete controller for both models", function() {
				var am = buildAdminMetadata(g.model("author").classInfo());
				var pm = buildAdminMetadata(g.model("post").classInfo());
				var ac = processControllerTemplate("Author", am);
				var pc = processControllerTemplate("Post", pm);
				expect(ac).toInclude("protectsFromForgery()");
				expect(pc).toInclude("protectsFromForgery()");
				expect(ac).notToInclude("|ObjectNameSingular|");
				expect(pc).notToInclude("|ObjectNameSingular|");
			});

			it("renderable views for both models", function() {
				var models = ["author", "post"];
				for (var mn in models) {
					var meta = buildAdminMetadata(g.model(mn).classInfo());
					var idx = processViewTemplate("index", capitalize(mn), meta);
					var shw = processViewTemplate("show", capitalize(mn), meta);
					expect(len(idx)).toBeGT(200);
					expect(len(shw)).toBeGT(200);
					expect(idx).toInclude("<cfoutput>");
					expect(shw).toInclude("<cfoutput>");
				}
			});
		});
	}

	// ── Helpers ──────────────────────────────────

	private struct function buildAdminMetadata(required struct classData) {
		var result = {};
		result.modelName = arguments.classData.modelName;
		result.pluralName = capitalize(pluralizeWord(arguments.classData.modelName));
		result.displayName = humanizeWord(arguments.classData.modelName);
		result.displayNamePlural = humanizeWord(pluralizeWord(arguments.classData.modelName));
		result.tableName = arguments.classData.tableName;
		result.primaryKey = arguments.classData.primaryKeys;
		result.softDeletion = arguments.classData.softDeletion;
		result.validationSummary = buildValidationSummary(arguments.classData.validations);
		result.enums = arguments.classData.enums;
		result.scopes = listToArray(structKeyList(arguments.classData.scopes));
		result.associations = buildAssociationList(arguments.classData.associations);
		result.fields = buildFieldList(arguments.classData.properties, arguments.classData.primaryKeys, arguments.classData.associations, result.validationSummary, arguments.classData.enums);
		return result;
	}

	private array function buildFieldList(required struct properties, required string primaryKeys, required struct associations, required struct validationSummary, required struct enums) {
		var fields = [];
		var fkSet = buildForeignKeySet(arguments.associations);
		for (var propName in arguments.properties) {
			var prop = arguments.properties[propName];
			var field = {};
			field.name = propName;
			field.column = structKeyExists(prop, "column") ? prop.column : propName;
			field.label = structKeyExists(prop, "label") ? prop.label : humanizeWord(propName);
			field.dataType = structKeyExists(prop, "type") ? prop.type : "string";
			field.sqlType = structKeyExists(prop, "dataType") ? prop.dataType : "cf_sql_varchar";
			field.isPrimaryKey = listFindNoCase(arguments.primaryKeys, propName) > 0;
			field.isForeignKey = structKeyExists(fkSet, propName);
			field.foreignKeyTo = field.isForeignKey ? fkSet[propName] : "";
			field.isEnum = structKeyExists(arguments.enums, propName);
			field.enumValues = field.isEnum ? arguments.enums[propName].values : {};
			var pv = structKeyExists(arguments.validationSummary, propName) ? arguments.validationSummary[propName] : {};
			field.required = structKeyExists(pv, "presence");
			field.unique = structKeyExists(pv, "uniqueness");
			field.validations = pv;
			field.inputType = resolveInputType(field.dataType, field.sqlType, propName, field.isEnum, field.isForeignKey);
			field.inList = !field.isPrimaryKey && !listFindNoCase("text,binary", field.dataType);
			field.inForm = !field.isPrimaryKey;
			field.inShow = true;
			arrayAppend(fields, field);
		}
		return fields;
	}

	private string function resolveInputType(required string dataType, required string sqlType, required string propName, required boolean isEnum, required boolean isForeignKey) {
		if (arguments.isForeignKey) return "select";
		if (arguments.isEnum) return "select";
		var nameLower = lCase(arguments.propName);
		if (findNoCase("email", nameLower)) return "email";
		if (findNoCase("password", nameLower)) return "password";
		if (arguments.dataType == "string") return "text";
		if (arguments.dataType == "text") return "textarea";
		if (listFindNoCase("integer,float,decimal,biginteger", arguments.dataType)) return "number";
		if (arguments.dataType == "boolean") return "checkbox";
		if (arguments.dataType == "date") return "date";
		if (arguments.dataType == "datetime" || arguments.dataType == "timestamp") return "datetime-local";
		if (arguments.dataType == "time") return "time";
		if (arguments.dataType == "binary") return "file";
		if (findNoCase("int", arguments.sqlType)) return "number";
		if (findNoCase("bit", arguments.sqlType)) return "checkbox";
		return "text";
	}

	private struct function buildForeignKeySet(required struct associations) {
		var fkSet = {};
		for (var assocName in arguments.associations) {
			var assoc = arguments.associations[assocName];
			if (structKeyExists(assoc, "type") && assoc.type == "belongsTo" && structKeyExists(assoc, "foreignKey")) {
				var mn = structKeyExists(assoc, "modelName") ? assoc.modelName : assocName;
				for (var fk in listToArray(assoc.foreignKey)) {
					fkSet[fk] = mn;
				}
			}
		}
		return fkSet;
	}

	private struct function buildValidationSummary(required struct validations) {
		var summary = {};
		var methodMap = {"$validatesPresenceOf": "presence", "$validatesUniquenessOf": "uniqueness", "$validatesFormatOf": "format", "$validatesLengthOf": "length"};
		for (var trigger in arguments.validations) {
			var rules = arguments.validations[trigger];
			if (!isArray(rules)) continue;
			for (var rule in rules) {
				if (!structKeyExists(rule, "args") || !structKeyExists(rule.args, "property")) continue;
				var vt = structKeyExists(methodMap, rule.method) ? methodMap[rule.method] : rule.method;
				var pn = rule.args.property;
				if (!structKeyExists(summary, pn)) summary[pn] = {};
				summary[pn][vt] = true;
			}
		}
		return summary;
	}

	private array function buildAssociationList(required struct associations) {
		var result = [];
		for (var assocName in arguments.associations) {
			var assoc = arguments.associations[assocName];
			arrayAppend(result, {
				name: assocName,
				type: structKeyExists(assoc, "type") ? assoc.type : "",
				modelName: structKeyExists(assoc, "modelName") ? assoc.modelName : "",
				foreignKey: structKeyExists(assoc, "foreignKey") ? assoc.foreignKey : "",
				dependent: structKeyExists(assoc, "dependent") ? assoc.dependent : ""
			});
		}
		return result;
	}

	private any function findFieldByName(required array fields, required string name) {
		for (var field in arguments.fields) {
			if (field.name == arguments.name) return field;
		}
		return {};
	}

	private string function processControllerTemplate(required string modelName, required struct metadata) {
		var content = fileRead(variables.controllerTemplatePath);
		var pluralName = pluralizeWord(arguments.modelName);
		var searchClauses = [];
		for (var field in arguments.metadata.fields) {
			if (field.isPrimaryKey) continue;
			if (field.dataType == "string" || field.inputType == "text" || field.inputType == "email") {
				arrayAppend(searchClauses, field.name & " LIKE '%" & chr(35) & "sanitizedQ" & chr(35) & "%'");
			}
		}
		var searchWhereClause = arrayLen(searchClauses) ? arrayToList(searchClauses, " OR ") : "1=1";
		var fkLoaders = [];
		for (var field in arguments.metadata.fields) {
			if (field.isForeignKey && len(field.foreignKeyTo)) {
				var fkPlural = lCase(pluralizeWord(field.foreignKeyTo));
				arrayAppend(fkLoaders, fkPlural & ' = model("' & field.foreignKeyTo & '").findAll(order="name");');
			}
		}
		var fkLoaderCode = arrayLen(fkLoaders) ? chr(9) & chr(9) & arrayToList(fkLoaders, chr(10) & chr(9) & chr(9)) : "";
		content = replace(content, "|SearchWhereClause|", searchWhereClause, "all");
		content = replace(content, "|ForeignKeyLoaders|", fkLoaderCode, "all");
		content = replace(content, "|DescriptionComment|", "", "all");
		content = replace(content, "|ObjectNameSingular|", lCase(arguments.modelName), "all");
		content = replace(content, "|ObjectNamePlural|", lCase(pluralName), "all");
		content = replace(content, "|ObjectNameSingularC|", arguments.modelName, "all");
		content = replace(content, "|ObjectNamePluralC|", pluralName, "all");
		return content;
	}

	private string function processViewTemplate(required string viewType, required string modelName, required struct metadata) {
		var templatePath = variables.templateDir & "/admin/" & arguments.viewType & ".txt";
		if (!fileExists(templatePath)) return "";
		var content = fileRead(templatePath);
		var pluralName = pluralizeWord(arguments.modelName);
		content = replace(content, "|ObjectNameSingular|", lCase(arguments.modelName), "all");
		content = replace(content, "|ObjectNamePlural|", lCase(pluralName), "all");
		content = replace(content, "|ObjectNameSingularC|", arguments.modelName, "all");
		content = replace(content, "|ObjectNamePluralC|", pluralName, "all");
		content = replace(content, "{{AdminTableHeaders}}", "<!-- headers -->", "all");
		content = replace(content, "{{AdminTableCells}}", "<!-- cells -->", "all");
		content = replace(content, "{{AdminShowFields}}", "<!-- fields -->", "all");
		content = replace(content, "{{AdminAssociationSections}}", "<!-- assocs -->", "all");
		return content;
	}

	private string function buildRoutesFile() {
		var nl = chr(10);
		var t = chr(9);
		var c = "<cfscript>" & nl;
		c &= t & "mapper()" & nl;
		c &= t & t & "// CLI-Appends-Here" & nl;
		c &= t & t & '.root(to = "main' & chr(35) & chr(35) & 'index", method = "get")' & nl;
		c &= t & ".end();" & nl;
		c &= "</cfscript>";
		return c;
	}

	private boolean function injectAdminRoute(required string resourceName, required string routesPath) {
		if (!fileExists(arguments.routesPath)) return false;
		var content = fileRead(arguments.routesPath);
		var resourceRoute = '.resources("' & arguments.resourceName & '")';
		var nl = chr(10);
		var tab = chr(9);
		if (findNoCase(resourceRoute, content) && findNoCase("admin", content)) return false;
		var adminScopePattern = '.scope(path="admin"';
		if (findNoCase(adminScopePattern, content)) {
			var pos = findNoCase(adminScopePattern, content);
			var endPos = findNoCase(".end()", content, pos);
			if (endPos > 0) {
				content = left(content, endPos - 1) & tab & tab & tab & resourceRoute & nl & tab & tab & mid(content, endPos, len(content) - endPos + 1);
				fileWrite(arguments.routesPath, content);
				return true;
			}
		}
		var marker = "// CLI-Appends-Here";
		var indent = "";
		if (find(tab & tab & marker, content)) indent = tab & tab;
		else if (find(tab & marker, content)) indent = tab;
		var fullMarker = indent & marker;
		if (find(fullMarker, content)) {
			var block = indent & '.scope(path="admin", package="admin")' & nl;
			block &= indent & tab & resourceRoute & nl;
			block &= indent & ".end()" & nl;
			content = replace(content, fullMarker, block & fullMarker, "all");
			fileWrite(arguments.routesPath, content);
			return true;
		}
		return false;
	}

	private string function capitalize(required string str) {
		if (len(arguments.str) == 0) return "";
		return uCase(left(arguments.str, 1)) & mid(arguments.str, 2, len(arguments.str) - 1);
	}

	private string function pluralizeWord(required string word) {
		var w = arguments.word;
		if (right(w, 1) == "s") return w & "es";
		if (right(w, 1) == "y" && !findNoCase(mid(w, len(w) - 1, 1), "aeiou")) return left(w, len(w) - 1) & "ies";
		return w & "s";
	}

	private string function humanizeWord(required string text) {
		var result = reReplace(arguments.text, "([A-Z])", " \1", "all");
		result = trim(result);
		if (len(result) == 0) return "";
		return uCase(left(result, 1)) & mid(result, 2, len(result) - 1);
	}

}
