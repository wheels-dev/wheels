<!---
  The Main Header + Navigation
--->
<cfoutput>
<header>
  <nav class="navbar navbar-expand-lg navbar-light bg-white shadow-sm py-2 px-2 px-md-4 mb-4">
    #linkTo(route="root", class="navbar-brand fw-bold", text=getSetting('general_sitename'))#
    <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="##navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
      <span class="navbar-toggler-icon"></span>
    </button>

    <div class="collapse navbar-collapse justify-content-between" id="navbarSupportedContent">
      <ul class="navbar-nav me-auto mb-2 mb-lg-0">
        <!---
          These links should show and hide depending on the Users permissions
          The only catch with this approach is that they might have a permission "lower" down the chain
          than the one you're testing for.
        --->
        <cfif hasPermission("admin.users.index")>
          <li class="nav-item">
            #linkTo(route="users", class="nav-link", text="Users")#
          </li>
        </cfif>
        <cfif hasPermission("admin.settings.index")>
          <li class="nav-item">
            #linkTo(route="settings", class="nav-link", text="Settings")#
          </li>
        </cfif>
        <cfif hasPermission("admin.permissions.index")>
          <li class="nav-item">
            #linkTo(route="permissions", class="nav-link", text="Permissions")#
          </li>
        </cfif>
        <cfif hasPermission("admin.roles.index")>
          <li class="nav-item">
            #linkTo(route="roles", class="nav-link", text="Roles")#
          </li>
        </cfif>
        <cfif hasPermission("admin.auditlogs.index")>
          <li class="nav-item">
            #linkTo(route="logs", class="nav-link", text="Logs")#
          </li>
        </cfif>
      </ul>
      <ul class="navbar-nav ms-auto mb-2 mb-lg-0 align-items-center">
        <!---
            If the user's logged in, show their Account Link etc
            Otherwise show a login btn
        --->
        <cfif isAuthenticated()>
          <li class="nav-item dropdown">
            <a class="nav-link dropdown-toggle d-flex align-items-center" id="navbarDropdown" data-bs-toggle="dropdown" href="##" role="button" aria-haspopup="true" aria-expanded="false">
              <span class="me-2">
                #gravatar(getSession().user.properties.email, 32, "pg", "rounded-circle shadow-sm")#
              </span>
              <span class="fw-semibold">
                <cfif len(getSession().user.properties.firstname)>#e(getSession().user.properties.firstname)#<cfelse>#e(getSession().user.properties.email)#</cfif>
              </span>
            </a>
            <div class="dropdown-menu dropdown-menu-end" aria-labelledby="navbarDropdown">
              <cfif hasPermission("accounts.show")>
                #linkTo(route="account", class="dropdown-item", text="Account")#
                <div class="dropdown-divider"></div>
              </cfif>
              #linkTo(route="logout", class="dropdown-item", text="Logout")#
            </div>
          </li>
        <cfelse>
          <li class="nav-item">#linkTo(route="login", class="btn btn-outline-primary px-3", text="Login")#</li>
        </cfif>
      </ul>
    </div>
  </nav>
</header>
</cfoutput>
