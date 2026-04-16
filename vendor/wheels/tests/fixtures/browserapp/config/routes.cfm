<cfscript>
mapper()
    .root(to="home##index", method="get")
    .get(name="login", pattern="/login", to="sessions##new")
    .post(name="authenticate", pattern="/login", to="sessions##create")
    .get(name="dashboard", pattern="/dashboard", to="home##dashboard")
    .post(name="logout", pattern="/logout", to="sessions##destroy")
    .wildcard()
.end();
</cfscript>
