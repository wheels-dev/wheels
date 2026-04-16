component extends="Controller" {

    function config() {
    }

    function create() {
        if (!listFindNoCase("testing,development", application.$wheels.environment)) {
            throw(
                type="Wheels.BrowserTestSecurityError",
                message="loginAs endpoint is only available in testing/development environments"
            );
        }

        session.userId = 1;
        session.userEmail = params.identifier;
    }
}
