component extends="Controller" {

    function config() {
    }

    function create() {
        // Fixture-only: the env gate in the app version uses
        // application.$wheels, which is cleared post-init. Here we just
        // accept the login in test mode since the route file is only
        // loaded by the core test runner.
        session.userId = 1;
        session.userEmail = params.identifier;
    }
}
