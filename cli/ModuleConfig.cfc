component {

    // Module Properties
    this.autoMapModels  = true;
    this.modelNamespace = "wheels";

    function configure(){
        interceptors = [
            { class='#moduleMapping#.interceptors.postInstall' }
        ];
        settings = {
            "modulePath": modulePath
        }
        
        // Register StyleHelper as a singleton
        binder.map("StyleHelper@wheels")
            .to("#moduleMapping#.models.StyleHelper")
            .asSingleton();
    }

    // Runs when module is loaded
    function onLoad(){
        log.info('Wheels Module loaded successfully.' );
    }

    // Runs when module is unloaded
    function onUnLoad(){
        log.info('Wheels Module unloaded successfully.' );
    }

}
