component extends="wirebox.system.ioc.config.Binder" {
    function configure() {
        // wireBox = {
        //     scanLocations = ["wheels"]
        // };
        map('global').to('wheels.Global');

        map('eventmethods').to('wheels.events.EventMethods');

        map('ViewObj').to('wheels.view');

				map('Plugins').to('wheels.Plugins');

        // map('Controller').to('wheels.controller').mixins("/wheels/controller/processing");
        // map('Controller').to('wheels.controller').mixins("/wheels/global/cfml");
        // map('Controller').to('wheels.controller').virtualInheritance('Processing');
        // map('Controller').to('wheels.controller');
        // mapDirectory('wheels.controller').mixins("/wheels/controller/csrf");
    }
}
