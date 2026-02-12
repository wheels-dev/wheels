<cfscript>
		application.$wheels.dataSourceUserName = "";
		application.$wheels.dataSourcePassword = "";
		application.$wheels.transactionMode = "commit";

		// Miscellaneous settings.
		application.$wheels.encodeURLs = true;
		application.$wheels.encodeHtmlTags = true;
		application.$wheels.encodeHtmlAttributes = true;
		application.$wheels.uncountables = "advice,air,blood,deer,equipment,fish,food,furniture,garbage,graffiti,grass,homework,housework,information,knowledge,luggage,mathematics,meat,milk,money,music,pollution,research,rice,sand,series,sheep,soap,software,species,sugar,traffic,transportation,travel,trash,water,feedback";
		application.$wheels.irregulars = {
			child = "children",
			foot = "feet",
			man = "men",
			move = "moves",
			person = "people",
			sex = "sexes",
			tooth = "teeth",
			woman = "women"
		};
		application.$wheels.tableNamePrefix = "";
		application.$wheels.obfuscateURLs = false;
		application.$wheels.reloadPassword = "";
		application.$wheels.redirectAfterReload = false;
		application.$wheels.softDeleteProperty = "deletedAt";
		application.$wheels.timeStampOnCreateProperty = "createdAt";
		application.$wheels.timeStampOnUpdateProperty = "updatedAt";
		application.$wheels.timeStampMode = "utc";
		application.$wheels.ipExceptions = "";
		application.$wheels.overwritePlugins = true;
		application.$wheels.deletePluginDirectories = true;
		application.$wheels.loadIncompatiblePlugins = true;
		application.$wheels.automaticValidations = true;
		application.$wheels.setUpdatedAtOnCreate = true;
		application.$wheels.useExpandedColumnAliases = false;
		application.$wheels.lowerCaseTableNames = false;
		application.$wheels.modelRequireConfig = false;
		application.$wheels.showIncompatiblePlugins = true;
		application.$wheels.booleanAttributes = "allowfullscreen,async,autofocus,autoplay,checked,compact,controls,declare,default,defaultchecked,defaultmuted,defaultselected,defer,disabled,draggable,enabled,formnovalidate,hidden,indeterminate,inert,ismap,itemscope,loop,multiple,muted,nohref,noresize,noshade,novalidate,nowrap,open,pauseonexit,readonly,required,reversed,scoped,seamless,selected,sortable,spellcheck,translate,truespeed,typemustmatch,visible";
		if (ListFindNoCase("production,maintenance", application.$wheels.environment)) {
			application.$wheels.redirectAfterReload = true;
		}
		application.$wheels.resetPropertiesStructKeyCase = true;

		// If session management is enabled in the application we default to storing Flash data in the session scope, if not we use a cookie.
		if (StructKeyExists(application, "sessionManagement") && application.sessionManagement) {
			application.$wheels.sessionManagement = true;
			application.$wheels.flashStorage = "session";
		} else {
			application.$wheels.sessionManagement = false;
			application.$wheels.flashStorage = "cookie";
		}

		// Additional configurable flash options
		application.$wheels.flashAppend = false;
</cfscript>
