<cfscript>
/**
 * DI container registrations.
 *
 * This file is loaded at application start (fail-closed: an error here
 * aborts boot as `Wheels.ConfigIncludeFailed`). Register services here
 * with the fluent binder:
 *
 *     local.di = injector();
 *     local.di.map("emailService").to("app.lib.EmailService").asSingleton();
 *     local.di.map("currentUser").to("app.lib.CurrentUserResolver").asRequestScoped();
 *     local.di.bind("INotifier").to("app.lib.SlackNotifier").asSingleton();
 *
 * Resolve anywhere with `service("emailService")`, or inject into a
 * controller with `inject("emailService, currentUser")` in `config()`.
 * Scopes: transient (default), `.asSingleton()`, `.asRequestScoped()`.
 *
 * Environment overrides are supported via the same `environment.cfm`
 * include pattern used by `config/app.cfm`.
 *
 * Add your registrations below this comment.
 */
</cfscript>
