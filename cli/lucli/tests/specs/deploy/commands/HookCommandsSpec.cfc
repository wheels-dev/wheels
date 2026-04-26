component extends="wheels.wheelstest.system.BaseSpec" {

    function beforeAll() {
        variables.cfg = new cli.lucli.services.deploy.config.ConfigLoader()
            .load(expandPath("/cli/lucli/tests/_fixtures/deploy/configs/minimal.yml"));

        // Isolated project root for hook file manipulation.
        variables.projectRoot = getTempDirectory() & "/wheels-deploy-hook-test-" & createUUID();
        directoryCreate(variables.projectRoot & "/.kamal/hooks", true, true);

        variables.hooks = new cli.lucli.services.deploy.commands.HookCommands(
            variables.cfg,
            {projectRoot: variables.projectRoot}
        );
    }

    function afterAll() {
        if (directoryExists(variables.projectRoot)) {
            directoryDelete(variables.projectRoot, true);
        }
    }

    function run() {
        describe("HookCommands", () => {

            it("forHook() returns exists=false when no hook file present", () => {
                var result = variables.hooks.forHook("pre-deploy", {KAMAL_VERSION: "v1"});
                expect(result.exists).toBeFalse();
                expect(result.hookPath).toInclude(".kamal/hooks/pre-deploy");
            });

            it("forHook() returns exists=true when the file exists", () => {
                var path = variables.projectRoot & "/.kamal/hooks/pre-deploy";
                fileWrite(path, "##!/usr/bin/env bash#chr(10)#echo pre-deploy");
                // chmod +x — Lucee fileSetAccessMode
                fileSetAccessMode(path, "755");
                var result = variables.hooks.forHook("pre-deploy", {KAMAL_VERSION: "v1"});
                expect(result.exists).toBeTrue();
            });

            it("forHook() env always includes the KAMAL_ prefix (never WHEELS_)", () => {
                var result = variables.hooks.forHook("post-deploy",
                    {KAMAL_VERSION: "v1", KAMAL_HOSTS: "1.2.3.4"});
                expect(structKeyExists(result.env, "KAMAL_VERSION")).toBeTrue();
                expect(structKeyExists(result.env, "KAMAL_HOSTS")).toBeTrue();
                for (var key in result.env) {
                    expect(left(key, 6)).toBe("KAMAL_");
                }
            });

            it("forHook() enriches env with built-in KAMAL_PERFORMER and KAMAL_DESTINATION", () => {
                var result = variables.hooks.forHook("pre-deploy", {KAMAL_VERSION: "v1"});
                expect(structKeyExists(result.env, "KAMAL_PERFORMER")).toBeTrue();
                expect(structKeyExists(result.env, "KAMAL_DESTINATION")).toBeTrue();
                // KAMAL_DESTINATION from config — minimal.yml has none, so empty string.
                expect(result.env.KAMAL_DESTINATION).toBe("");
            });

            it("forHook() passes through caller-provided env keys", () => {
                var result = variables.hooks.forHook("pre-deploy",
                    {KAMAL_VERSION: "abc1234", KAMAL_HOSTS: "1.1.1.1,2.2.2.2"});
                expect(result.env.KAMAL_VERSION).toBe("abc1234");
                expect(result.env.KAMAL_HOSTS).toBe("1.1.1.1,2.2.2.2");
            });

            it("hookPath() for a given name is project-rooted", () => {
                expect(variables.hooks.hookPath("post-deploy"))
                    .toBe(variables.projectRoot & "/.kamal/hooks/post-deploy");
            });
        });
    }
}
