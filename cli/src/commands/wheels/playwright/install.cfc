/**
 * Install Playwright browsers
 *
 * Use this command after running `wheels playwright:init` if:
 * - Browser installation failed during the wizard
 * - You need to install specific browsers
 *
 * {code:bash}
 * wheels playwright install
 * {code}
 *
 * Install specific browsers:
 * {code:bash}
 * wheels playwright install --chromium --firefox
 * {code}
 *
 * Note: On macOS 13 or earlier, webkit will be skipped automatically
 * as it requires macOS 14+.
 */
component aliases="wheels playwright:install, wheels playwright install" extends="../base" {

    property name="detailOutput" inject="DetailOutputService@wheels-cli";

    /**
     * @chromium Install Chromium browser (default: true)
     * @firefox Install Firefox browser (default: true)
     * @webkit Install Webkit browser (default: false, macOS 14+ only)
     */
    function run(
        boolean chromium = true,
        boolean firefox = true,
        boolean webkit = false
    ) {
        try {
            requireWheelsApp(getCWD());

            detailOutput.header("Playwright Browser Installation");

            if (!isNodeAvailable()) {
                detailOutput.error("Node.js is required. Please install Node.js first.");
                print.line("Visit https://nodejs.org to download and install Node.js");
                setExitCode(1);
                return;
            }

            var browsers = [];
            if (arguments.chromium) {
                arrayAppend(browsers, "chromium");
            }
            if (arguments.firefox) {
                arrayAppend(browsers, "firefox");
            }
            if (arguments.webkit) {
                if (isMacOS13OrEarlier()) {
                    detailOutput.statusWarning("Webkit requires macOS 14+. Skipping webkit installation.");
                } else {
                    arrayAppend(browsers, "webkit");
                }
            }

            if (arrayIsEmpty(browsers)) {
                detailOutput.output("No browsers selected for installation.")
                    .line();
                return;
            }

            detailOutput.output("Installing browsers: " & arrayToList(browsers, ", "))
                .line();

            local.browserList = browsers.toList(" ");
            detailOutput.output("Running: npx playwright install #local.browserList#")
                .line();

            try {
                command("!npx playwright install #local.browserList#").run();

                detailOutput.success("Playwright browsers installed successfully!");
                detailOutput.nextSteps([
                    "Run tests: npx playwright test",
                    "Open UI mode: npx playwright test --ui"
                ]);

            } catch (any e) {
                handleInstallError(e);
            }

        } catch (any e) {
            detailOutput.error("Installation failed: #e.message#");
            setExitCode(1);
        }
    }

    private boolean function isNodeAvailable() {
        try {
            command("!node -v").run();
            return true;
        } catch (any e) {
            return false;
        }
    }

    private boolean function isMacOS13OrEarlier() {
        try {
            var result = command("!sw_vers -productVersion").run(returnOutput=true);
            var version = trim(result);

            var major = listFirst(version, ".");
            var minor = 0;
            if (listLen(version, ".") >= 2) {
                minor = listGetAt(version, 2, ".");
            }

            if (major < 14) {
                return true;
            }
            return false;
        } catch (any e) {
            return false;
        }
    }

    private void function handleInstallError(required any e) {
        var errorMsg = arguments.e.message;

        if (findNoCase("webkit", errorMsg) && findNoCase("macOS", errorMsg)) {
            detailOutput.error("Webkit installation failed: requires macOS 14+");
            detailOutput.line();
            detailOutput.output("To install only Chromium and Firefox:");
            detailOutput.output("  wheels playwright install --chromium --firefox")
                .line();
        } else if (findNoCase("does not support", errorMsg)) {
            detailOutput.error("Browser installation failed due to system compatibility.");
            detailOutput.line();
            print.cyanLine("Tip: Check https://playwright.dev/docs/browsers for system requirements.");
        } else {
            detailOutput.error("Browser installation failed: #errorMsg#");
        }

        setExitCode(1);
    }
}