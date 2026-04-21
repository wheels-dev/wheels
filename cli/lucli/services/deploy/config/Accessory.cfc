/**
 * Accessory config accessor.
 * Source of truth: Kamal 2.4.0 lib/kamal/configuration/accessory.rb
 *
 * Each accessory is a single sidecar container (db/redis/search/etc.) pinned
 * to one or more hosts, outside the app rollover rhythm. An accessory's
 * labels are service=<app_service>-<accessory_name>, role=<accessory_name>.
 *
 * YAML accepts either `host: 1.2.3.4` (scalar or array) or `hosts: [...]`.
 * Volumes can be declared via `volumes:` or `directories:` (Kamal accepts
 * both; `directories:` is the canonical accessory form).
 */
component {

    public any function init(required string name, required struct raw, required string serviceName) {
        variables.name = arguments.name;
        variables.raw = arguments.raw;
        variables.serviceName = arguments.serviceName;
        return this;
    }

    public string function name() {
        return variables.name;
    }

    public string function image() {
        return variables.raw.image ?: "";
    }

    public array function hosts() {
        if (structKeyExists(variables.raw, "host")) {
            var h = variables.raw.host;
            return isArray(h) ? h : [h];
        }
        if (structKeyExists(variables.raw, "hosts")) {
            var hs = variables.raw.hosts;
            return isArray(hs) ? hs : [hs];
        }
        return [];
    }

    public string function port() {
        return variables.raw.port ?: "";
    }

    public array function volumes() {
        if (structKeyExists(variables.raw, "volumes") && isArray(variables.raw.volumes)) {
            return variables.raw.volumes;
        }
        if (structKeyExists(variables.raw, "directories") && isArray(variables.raw.directories)) {
            return variables.raw.directories;
        }
        return [];
    }

    public array function files() {
        return (structKeyExists(variables.raw, "files") && isArray(variables.raw.files))
            ? variables.raw.files
            : [];
    }

    public any function env() {
        var e = (structKeyExists(variables.raw, "env") && isStruct(variables.raw.env))
            ? variables.raw.env
            : {};
        return new Env(e);
    }

    public string function cmd() {
        return variables.raw.cmd ?: "";
    }

    public string function containerName() {
        return variables.serviceName & "-" & variables.name;
    }

    public string function labelService() {
        return variables.serviceName & "-" & variables.name;
    }

}
