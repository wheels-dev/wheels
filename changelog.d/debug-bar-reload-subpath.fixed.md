- Debug bar reload link (and the CFML error page's displayed URL) now honors the `subpath`
  setting: the base URL is composed from the resolved `webPath` plus the front-controller
  filename — the same idiom as `urlFor()` — instead of raw `cgi.script_name`, so subfolder
  deployments emit `/myapp/posts?reload=` instead of the unroutable
  `/myapp/public/index.cfm/posts?reload=`. Root installs render byte-identical to before.
  Extracted into the unit-tested `$buildDebugReloadUrl()` helper in `Global.cfc` ([#3344](https://github.com/wheels-dev/wheels/issues/3344))
