- `wheels generate auth`: the generated `Sessions.delete()` (logout) now ends the session only for a POST (the logout form, which sends `_method=delete`) or a real `DELETE` request. A `GET` or `HEAD`, which the default wildcard route also maps to `/sessions/delete`, redirects to the login page without logging out. **Apps generated with an earlier version should add the same guard** at the top of `delete()` in `app/controllers/Sessions.cfc`:
  ```cfm
  if (!isPost() && !isDelete()) {
  	redirectTo(route="login");
  	return;
  }
  ```
