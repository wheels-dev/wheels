component extends="Controller" {

    function config() {
        filters(through="$requireLogin", except="index");
    }

    function index() {
    }

    function dashboard() {
        user = {email: session.userEmail ?: ""};
    }

    private function $requireLogin() {
        if (!structKeyExists(session, "userId")) {
            redirectTo(route="browserTestLogin");
        }
    }
}
