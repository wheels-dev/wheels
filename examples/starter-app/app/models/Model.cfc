/**
 * This is the parent model file that all your models should extend.
 * You can add functions to this file to make them available in all your models.
 * Do not delete this file.
 */
component extends="wheels.Model" {

	function config(boolean logChanges=false){
		if(arguments.logChanges){
			afterValidationOnUpdate("logChangedValues");
		}
	}

	/**
	 * Attempt to log which values have changed
	 */
	private function logChangedValues() {

		local["changed"] = {
			"properties" = this.allChanges(),
			"model" = getCallingModelName(),
			"key" = this.key()
		};

		// If the calling model doesn't want us to log a sensitive value, remove it.
		if(structKeyExists(this, "ignoreLogProperties")){
			for(var property in listToArray(this.ignoreLogProperties)){
				if(structKeyExists(local.changed.properties, property))
					structDelete(local.changed.properties, property);
			}
		}

		if(!structIsEmpty(local.changed.properties))
			addLogLine(type="database", severity="warning", message="#local.changed.model# : #local.changed.key# Change Data", data=local.changed);
	}

	/**
	* Simple sanitization: this could probably be improved somewhat.
	**/
	private function sanitizeInput(string){
		local.rv = REReplaceNoCase(arguments.string, "<\ *[a-z].*?>", "", "all");
		local.rv = REReplaceNoCase(local.rv, "<\ */\ *[a-z].*?>", "", "all");
		local.rv = trim(htmleditFormat(local.rv));
		return local.rv;
	}

	/**
	 * Attempt to work out which model is calling a function
	 */
	private function getCallingModelName() {
		return replace(getMetaData(this)['fullname'], "wheels....models.", "", "all");
	}

}
