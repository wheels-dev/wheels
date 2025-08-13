<cfscript>
//=====================================================================
//=     Installation
//=====================================================================
/**
* Gets Called onApplicationStart, and loads database settings, default roles + permissions etc.
*
* [section: Application]
* [category: Miscellaneous]
*
**/
public function createApplicationSettings(){

    // Load Application Settings
    local.settings=model("setting").findAll();
    for(var setting in local.settings){
        application.settings[setting.name]=deserializeJSON(setting.value);
    }

    // Anon Level Permissions: these are the application level defaults
    local.permissions=model("permission").findAll(include="rolepermissions", where="roleid=4");
    for(var permission in local.permissions){
        application.permissions[permission.name]=true;
    }

    // Role Level Permissions also cached in application scope for easier lookup
    local.allpermissions=model("permission").findAll( order="name", include="role");
    local.allroles= model("role").findAll(select="name", order="name");
    local.rolepermissions={};

    for( var role in local.allroles){
      local.rolepermissions[role.name]={};
      cfloop(query=local.allpermissions, group="id"){
        if(rolename != ""){
          cfloop(){
            local.rolepermissions[rolename][name]=true;
          }
        }
      }
    }

    application.rolepermissions=local.rolepermissions;
}

</cfscript>
