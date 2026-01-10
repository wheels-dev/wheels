component extends="app.controllers.Controller" {

	function config() {
		super.config(restrictAccess=true);
		verifies(except="index", params="key", paramsTypes="integer", handler="objectNotFound");
	}

	/**
	* View all settings
	**/
	function index() {
		try{
			settings=model("setting").getSetting();
			settingCategories=[];
			for(setting in settings){
				var s=listFirst(setting.name, "_");
				if(!arrayFind(settingCategories, s)){
					arrayAppend(settingCategories, s);
				}
			}
		}catch (any e) {
			redirectTo(action="index", error="Error: #e.message#");
		}
	}

	/**
	* Edit setting
	**/
	function edit() {
		try{
			setting=model("setting").getSettingById(params.key);
		}catch (any e) {
			redirectTo(action="index", error="Error: #e.message#");
		}
		
	}

	/**
	* Update setting
	**/
	function update() {
		try {
			updated=model("setting").updateSettingByKey(params.key, params.setting);
			if(updated){
				redirectTo(action="index", success="Setting successfully updated: you must reload the application for these to take effect.");
			} else {
				renderView(action="edit");
			}
		} catch (any e) {
			redirectTo(action="edit", error="Error: #e.message#");
		}	
	}

	/**
	* Redirect away if verifies fails, or if an object can't be found
	**/
	private function objectNotFound() {
		redirectTo(action="index", error="That Setting wasn't found");
	}

}
