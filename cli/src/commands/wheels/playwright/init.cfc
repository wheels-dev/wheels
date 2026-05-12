/**
 * Initialize Playwright for end-to-end testing
 *
 * This command wraps `npx create-playwright` to set up Playwright testing
 * in your Wheels application.
 *
 * The command runs interactively and will ask you a few questions:
 * - Language preference (TypeScript or JavaScript)
 * - Where to put your tests
 * - Whether to add GitHub Actions workflow
 * - Whether to install Playwright browsers (default: NO, do this manually)
 *
 * {code:bash}
 * wheels playwright:init
 * {code}
 *
 * Note: Browser installation is skipped by default due to Playwright webkit
 * requiring macOS 14+. After setup, run:
 * {code:bash}
 * wheels playwright install
 * {code}
 */
component aliases="wheels playwright:init, wheels playwright init" extends="../base" {

    property name="detailOutput" inject="DetailOutputService@wheels-cli";

    function run() {
        try {
            requireWheelsApp(getCWD());

            detailOutput.header("Playwright Setup");

            if (!isNodeAvailable()) {
                detailOutput.error("Node.js is required. Please install Node.js first.");
                print.line("Visit https://nodejs.org to download and install Node.js");
                setExitCode(1);
                return;
            }

            runInteractive();

        } catch (any e) {
            detailOutput.error("Setup failed: #e.message#");
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

    private void function runInteractive() {
        detailOutput.output("Launching Playwright setup wizard...")
            .line();
        print.cyanLine("This will initialize Playwright with interactive prompts.")
            .line();
        print.cyanLine("The wizard will ask you about:");
        print.cyanLine("  - TypeScript or JavaScript");
        print.cyanLine("  - Test directory location");
        print.cyanLine("  - GitHub Actions setup");
        print.cyanLine("  - Browser installation (answer NO - use 'wheels playwright install' instead)")
            .line();

        var confirmed = ask(("Proceed with Playwright setup? [y/n]"));
        if (lCase(trim(confirmed)) != "y") {
            detailOutput.output("Operation cancelled by user.");
            return;
        }

        detailOutput.line();
        detailOutput.output("Running: npx create-playwright");
        detailOutput.line();

        try {
            command("!npx create-playwright").run();

            detailOutput.success("Playwright setup complete!");
            detailOutput.line();
            detailOutput.nextSteps([
                "Install browsers: wheels playwright install",
                "Run tests: npx playwright test",
                "Open UI mode: npx playwright test --ui"
            ]);

        } catch (any e) {
            var errorMsg = e.message;
            detailOutput.error("Playwright setup failed: #errorMsg#");
            detailOutput.line();

            if (findNoCase("webkit", errorMsg) || findNoCase("does not support", errorMsg)) {
                print.cyanLine("This usually happens when webkit fails to install on older macOS versions.")
                    .line();
            }

            detailOutput.output("To complete setup without browser installation:")
                .line();
            print.greenLine("  wheels playwright install")
                .line();

            setExitCode(1);
        }
    }
}