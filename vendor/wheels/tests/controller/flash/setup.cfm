<cfscript>
params = {controller = "dummy", action = "dummy"};
_controller = controller("dummy", params);
_controller.$setFlashStorage("cookie");
_controller.flashClear();
_controller.$setFlashStorage("session");
_controller.flashClear();
</cfscript>
