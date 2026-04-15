component extends="wheels.WheelsTest" {

    function beforeAll() {
        variables.launcher = CreateObject("component", "wheels.wheelstest.BrowserLauncher");
    }

    function run() {
        describe("BrowserLauncher path discovery", () => {

            it("resolveInstallDir() returns WHEELS_BROWSER_HOME env var when set", () => {
                var stubbed = variables.launcher.$resolveInstallDir(
                    envVar="/tmp/custom-browser-home",
                    homeDir="/Users/someone"
                );
                expect(stubbed).toBe("/tmp/custom-browser-home");
            });

            it("resolveInstallDir() falls back to ~/.wheels/browser when env var empty", () => {
                var resolved = variables.launcher.$resolveInstallDir(
                    envVar="",
                    homeDir="/Users/someone"
                );
                expect(resolved).toBe("/Users/someone/.wheels/browser");
            });

            it("resolveInstallDir() handles home dir with trailing slash", () => {
                var resolved = variables.launcher.$resolveInstallDir(
                    envVar="",
                    homeDir="/Users/someone/"
                );
                expect(resolved).toBe("/Users/someone/.wheels/browser");
            });

            it("jarPath() returns installDir + /lib/playwright-VERSION.jar", () => {
                var p = variables.launcher.$jarPath(
                    installDir="/tmp/browser",
                    version="1.45.0"
                );
                expect(p).toBe("/tmp/browser/lib/playwright-1.45.0.jar");
            });

            it("verifyInstall() throws when JAR missing", () => {
                expect(() => {
                    variables.launcher.$verifyInstall(jarPath="/does/not/exist.jar");
                }).toThrow(type="Wheels.BrowserNotInstalled");
            });

            it("verifyInstall() returns true when JAR exists", () => {
                var tmpJar = getTempDirectory() & "dummy-" & createUUID() & ".jar";
                fileWrite(tmpJar, "");
                try {
                    expect(variables.launcher.$verifyInstall(jarPath=tmpJar)).toBeTrue();
                } finally {
                    fileDelete(tmpJar);
                }
            });
        });
    }
}
