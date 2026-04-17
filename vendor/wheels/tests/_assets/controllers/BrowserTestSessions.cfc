component extends="Controller" {

    function new() {
        flashError = flash("error") ?: "";
    }

    function create() {
        if (params.email == "alice@example.com" && params.password == "secret") {
            session.userId = 1;
            session.userEmail = params.email;
            redirectTo(route="browserTestDashboard");
        } else {
            flashInsert(error="Invalid credentials");
            redirectTo(route="browserTestLogin");
        }
    }

    function destroy() {
        structClear(session);
        redirectTo(route="browserTestLogin");
    }
}
