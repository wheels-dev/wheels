component extends="Controller" {

    function config() {
    }

    function create() {
        if (application.$wheels.environment != "testing") {
            throw(
                type="Wheels.BrowserTestSecurityError",
                message="loginAs endpoint is only available in testing environment"
            );
        }

        session.userId = 1;
        session.userEmail = params.identifier;
    }
}
