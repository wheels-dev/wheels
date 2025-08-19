component {
    /*
        After installation of a wheels plugin, ensure we've got the .zip named properly.

        interceptData
          installArgs - Struct containing the following keys used in installation of the package.
            ID - The ID of the package to install
            directory - Directory to install to. May be null, if none supplied.
            save - Flag to save box.json dependency
            saveDev - Flag to save box.json dev dependency
            production - Flag to perform a production install
            currentWorkingDirectory - Original working directory that requested installation
            verbose - Flag to print verbose output
            force - Flag to force installation
            packagePathRequestingInstallation - Path to package requesting installing. This climbs the folders structure for nested dependencies.

    */
    property name='fileSystemUtil'     inject='FileSystem';
    property name='Formatter'     inject='Formatter';
    property name='packageService' inject='packageService';

    function postInstall( required struct interceptData ) {
       var pluginFolder                 = fileSystemUtil.resolvePath("plugins");
       var isValidWheelsInstallation    = directoryExists( fileSystemUtil.resolvePath("vendor/wheels")) ? true:false;
       var isValidPluginsDirectory      = directoryExists( pluginFolder ) ? true:false;

       if(isValidWheelsInstallation && isValidPluginsDirectory){
          var pluginList=DirectoryList( pluginFolder, false, "query" );

          for(plugin in pluginList){
            var pluginDirectory   = pluginFolder & '/' & plugin.name;
            if(plugin.type == 'Dir' && fileExists(pluginDirectory & "/box.json")){

              var pluginBoxJson     = packageService.readPackageDescriptorRaw( pluginDirectory );

              if(structKeyExists(pluginBoxJson, "VERSION")){
                var pluginVersion     = pluginBoxJson.version;
                var packageDirectory  = pluginBoxJson.packageDirectory;
                var sourceFolder      = pluginFolder & '/' & packageDirectory;
                var zipString         = pluginFolder & '/' & packageDirectory & '-' & pluginVersion & ".zip";
                if(!fileExists(zipString)){
                systemOutput("Creating #zipString#", true);
                zip
                      action="zip"
                      recurse="yes"
                      showDirectory="yes"
                      source="#sourceFolder#"
                      file="#zipString#";
                }
              }
            }
          }
       }
    }
}
