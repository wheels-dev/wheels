- `wheels new`: the scaffolded session cookie is now `Secure` whenever the request that creates the session arrives over HTTPS, directly or through a TLS-terminating proxy that sends `X-Forwarded-Proto: https`, as well as for `WHEELS_ENV=production`. It used to depend on `WHEELS_ENV=production` alone. An app switched to production through `config/environment.cfm` (the scaffolded `.env` still says `development`) therefore issued its session cookie without `Secure`. **Apps created with 4.0.6-4.1.1 should update `this.sessionCookie.secure` in `public/Application.cfc`** to:
  ```cfm
  secure: (structKeyExists(variables, "currentEnv") && currentEnv == "production")
  	|| (IsBoolean(cgi.server_port_secure) && cgi.server_port_secure)
  	|| cgi.https == "on"
  	|| cgi.http_x_forwarded_proto == "https"
  ```
  (or set `this.sessionCookie.secure = true;` in `config/app.cfm` when the site is HTTPS-only). `wheels generate auth` also adds a spec that a `GET` to the logout action does not end the session.
