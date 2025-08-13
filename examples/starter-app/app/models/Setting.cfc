component extends="Model" {

	function config() {
		// Properties
		validatesPresenceOf("name,description,type,value,editable");
		validatesUniquenessOf(properties="name", message="Setting name must be unique");
		validatesFormatOf(property="editable", type="boolean");
		validatesInclusionOf(property="type", list="select,boolean,textfield", message="Invalid Setting Type" );

		beforeValidation("serializeValue");
		afterFind("deserializeValue");
	}

	// If updating a setting, serialize its value
	function serializeValue(){
		if(structKeyExists(this, "value") && !isJSON(this.value))
			this.value=serializeJSON(this.value);
	}

	// Deserialize Setting Value after find - used in when updating application settings
	function deserializeValue(){
		if(structKeyExists(this, "value") && isJSON(this.value))
			this.value=deserializeJSON(this.value);
	}

	function getSetting(){
		return findAll(order="name");
	}
	
	function getSettingById(required string key){
		return findByKey(key=arguments.key, where="editable = 1");
	}

	function updateSettingByKey(required string key, required struct settingData) {
		setting=findByKey(arguments.key);
		if (setting.update(arguments.settingData)) {
			return true;
		} else {
		  return false;
		}
	}
}
