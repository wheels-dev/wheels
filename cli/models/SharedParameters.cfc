/**
 * Shared parameter definitions for CLI commands
 * Provides consistent parameter naming and documentation across all commands
 */
component accessors="true" singleton {

	/**
	 * Common generation parameters used across multiple commands
	 */
	public struct function getGenerationParams() {
		return {
			"name": {
				"hint": "Name of the item to generate",
				"type": "string",
				"required": true
			},
			"force": {
				"hint": "Overwrite existing files without prompting",
				"type": "boolean",
				"required": false,
				"default": false
			},
			"dry-run": {
				"hint": "Preview what would be generated without creating files",
				"type": "boolean",
				"required": false,
				"default": false
			},
			"template": {
				"hint": "Custom template to use for generation",
				"type": "string",
				"required": false
			}
		};
	}

	/**
	 * Database column parameters
	 */
	public struct function getDatabaseColumnParams() {
		return {
			"column-name": {
				"hint": "Name of the database column",
				"type": "string",
				"required": true
			},
			"data-type": {
				"hint": "SQL data type (string, integer, float, boolean, date, datetime, time, timestamp, binary, uuid)",
				"type": "string",
				"required": true
			},
			"default": {
				"hint": "Default value for the column",
				"type": "string",
				"required": false
			},
			"null": {
				"hint": "Whether the column allows NULL values",
				"type": "boolean",
				"required": false,
				"default": true
			},
			"limit": {
				"hint": "Maximum length for string/binary columns",
				"type": "numeric",
				"required": false
			},
			"precision": {
				"hint": "Total number of digits for decimal columns",
				"type": "numeric",
				"required": false
			},
			"scale": {
				"hint": "Number of decimal places for decimal columns",
				"type": "numeric",
				"required": false
			}
		};
	}

	/**
	 * Model relationship parameters
	 */
	public struct function getRelationshipParams() {
		return {
			"belongs-to": {
				"hint": "Comma-separated list of parent model names for belongsTo relationships",
				"type": "string",
				"required": false
			},
			"has-many": {
				"hint": "Comma-separated list of child model names for hasMany relationships",
				"type": "string",
				"required": false
			},
			"has-one": {
				"hint": "Comma-separated list of child model names for hasOne relationships",
				"type": "string",
				"required": false
			}
		};
	}

	/**
	 * Model configuration parameters
	 */
	public struct function getModelParams() {
		return {
			"primary-key": {
				"hint": "Primary key column name(s)",
				"type": "string",
				"required": false,
				"default": "id"
			},
			"table-name": {
				"hint": "Custom database table name",
				"type": "string",
				"required": false
			},
			"data-source": {
				"hint": "Data source name to use",
				"type": "string",
				"required": false
			}
		};
	}

	/**
	 * Testing parameters
	 */
	public struct function getTestParams() {
		return {
			"target": {
				"hint": "Name of the component, model, or controller to test",
				"type": "string",
				"required": false
			},
			"test-type": {
				"hint": "Type of test to generate (unit, integration, functional)",
				"type": "string",
				"required": false,
				"default": "unit"
			},
			"methods": {
				"hint": "Comma-separated list of methods to test",
				"type": "string",
				"required": false
			}
		};
	}

	/**
	 * Output formatting parameters
	 */
	public struct function getOutputParams() {
		return {
			"format": {
				"hint": "Output format (json, table, csv, xml)",
				"type": "string",
				"required": false,
				"default": "table"
			},
			"verbose": {
				"hint": "Show detailed output",
				"type": "boolean",
				"required": false,
				"default": false
			},
			"quiet": {
				"hint": "Suppress all non-essential output",
				"type": "boolean",
				"required": false,
				"default": false
			},
			"output-file": {
				"hint": "File path to write output to",
				"type": "string",
				"required": false
			}
		};
	}

	/**
	 * API/REST parameters
	 */
	public struct function getApiParams() {
		return {
			"api": {
				"hint": "Generate API-style controller (JSON responses)",
				"type": "boolean",
				"required": false,
				"default": false
			},
			"rest": {
				"hint": "Generate RESTful routes and actions",
				"type": "boolean",
				"required": false,
				"default": false
			},
			"resource": {
				"hint": "Generate as a resource with standard CRUD actions",
				"type": "boolean",
				"required": false,
				"default": false
			}
		};
	}

	/**
	 * Migration parameters
	 */
	public struct function getMigrationParams() {
		return {
			"migration": {
				"hint": "Generate a database migration file",
				"type": "boolean",
				"required": false,
				"default": true
			},
			"migration-only": {
				"hint": "Only generate the migration file, skip other files",
				"type": "boolean",
				"required": false,
				"default": false
			},
			"skip-migration": {
				"hint": "Skip generating the migration file",
				"type": "boolean",
				"required": false,
				"default": false
			}
		};
	}

	/**
	 * Environment parameters
	 */
	public struct function getEnvironmentParams() {
		return {
			"environment": {
				"hint": "Environment to use (development, testing, production, maintenance)",
				"type": "string",
				"required": false,
				"default": "development"
			},
			"reload-password": {
				"hint": "Password required for reloading the application",
				"type": "string",
				"required": false
			}
		};
	}

	/**
	 * Helper to merge multiple parameter sets
	 */
	public struct function mergeParams() {
		var merged = {};
		for (var paramSet in arguments) {
			structAppend(merged, arguments[paramSet], true);
		}
		return merged;
	}

}