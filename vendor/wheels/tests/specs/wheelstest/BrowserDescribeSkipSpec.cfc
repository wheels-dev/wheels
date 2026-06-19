/**
 * Self-test for browserDescribe()'s skip path. When browserTestSkipped is
 * set (CI gate or Playwright not installed), the aroundEach hook must NOT
 * execute spec bodies — specs don't need hand-written
 * `if (this.browserTestSkipped) return;` guards.
 *
 * beforeAll() here forces the skip deterministically (no launcher, no
 * browser), so the spec body below throwing means the skip path is broken.
 */
component extends="wheels.wheelstest.BrowserTest" {

    function beforeAll() {
        // Deliberately does NOT call super.beforeAll() — simulates the skip
        // outcome (CI gate / missing Playwright JARs) without depending on
        // the environment.
        this.browserTestSkipped = true;
    }

    function run() {
        browserDescribe("browserDescribe skip path", () => {

            it("does not execute spec bodies when browserTestSkipped is set", () => {
                throw(
                    type="Wheels.BrowserTest.SkipPathExecuted",
                    message="browserDescribe() executed a spec body despite browserTestSkipped=true. The aroundEach skip path must return without calling spec.body()."
                );
            });

        });
    }
}
