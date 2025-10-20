import Cocoa

class WheelsInstallerApp: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var progressWindow: NSWindow?
    var progressIndicator: NSProgressIndicator?
    var progressLabel: NSTextField?
    var outputTextView: NSTextView?
    var deleteDMGCheckbox: NSButton?
    var dmgPath: String?

    // Configuration fields
    var installPathField: NSTextField!
    var appNameField: NSTextField!
    var reloadPasswordField: NSTextField!
    var datasourceNameField: NSTextField!
    var templatePopup: NSPopUpButton!
    var enginePopup: NSPopUpButton!
    var h2Checkbox: NSButton!
    var bootstrapCheckbox: NSButton!
    var packageCheckbox: NSButton!
    var appBasePathField: NSTextField!
    var forceCheckbox: NSButton!
    var skipPathCheckbox: NSButton!

    func applicationDidFinishLaunching(_ notification: Notification) {
        detectDMGPath()
        createMainWindow()
    }

    func detectDMGPath() {
        // Check if running from a DMG by looking at the bundle path
        if let bundlePath = Bundle.main.bundlePath as String? {
            // Check if path contains /Volumes/ which indicates a mounted DMG
            if bundlePath.contains("/Volumes/") {
                // Try to find the DMG file that corresponds to this volume
                let volumeName = bundlePath.components(separatedBy: "/Volumes/")[1].components(separatedBy: "/")[0]

                // Common locations for DMG files
                let possibleDMGLocations = [
                    NSHomeDirectory() + "/Downloads/\(volumeName).dmg",
                    NSHomeDirectory() + "/Desktop/\(volumeName).dmg",
                    "/tmp/\(volumeName).dmg"
                ]

                for location in possibleDMGLocations {
                    if FileManager.default.fileExists(atPath: location) {
                        dmgPath = location
                        break
                    }
                }

                // If not found in common locations, try to find any DMG with similar name
                if dmgPath == nil {
                    let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
                    if let downloadsPath = downloadsURL?.path {
                        do {
                            let files = try FileManager.default.contentsOfDirectory(atPath: downloadsPath)
                            for file in files {
                                if file.lowercased().contains("wheels") && file.hasSuffix(".dmg") {
                                    dmgPath = downloadsPath + "/" + file
                                    break
                                }
                            }
                        } catch {
                            // Silently fail - DMG deletion is optional
                        }
                    }
                }
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func createMainWindow() {
        // Create window
        let windowRect = NSRect(x: 0, y: 0, width: 600, height: 720)
        window = NSWindow(contentRect: windowRect,
                         styleMask: [.titled, .closable, .miniaturizable],
                         backing: .buffered,
                         defer: false)
        window.title = "Wheels Application Installer"
        window.center()

        // Set icon if available
        if let iconPath = Bundle.main.path(forResource: "wheels_logo", ofType: "icns"),
           let icon = NSImage(contentsOfFile: iconPath) {
            NSApp.applicationIconImage = icon
        }

        // Create content view
        let contentView = NSView(frame: windowRect)
        window.contentView = contentView

        var yPosition: CGFloat = windowRect.height - 40

        // Title
        let titleLabel = createLabel("Wheels Application Installer", fontSize: 18, bold: true)
        titleLabel.frame = NSRect(x: 20, y: yPosition, width: 560, height: 30)
        contentView.addSubview(titleLabel)
        yPosition -= 35

        let subtitleLabel = createLabel("Configure your Wheels installation", fontSize: 12, bold: false)
        subtitleLabel.frame = NSRect(x: 20, y: yPosition, width: 560, height: 20)
        contentView.addSubview(subtitleLabel)
        yPosition -= 35

        // CommandBox Configuration Section
        let commandboxLabel = createLabel("CommandBox Configuration", fontSize: 14, bold: true)
        commandboxLabel.frame = NSRect(x: 20, y: yPosition, width: 560, height: 20)
        contentView.addSubview(commandboxLabel)
        yPosition -= 30

        // Install Path
        installPathField = NSTextField(frame: NSRect(x: 180, y: yPosition - 3, width: 320, height: 22))
        installPathField.stringValue = NSHomeDirectory() + "/Desktop/commandbox"
        yPosition = addLabeledFieldWithBrowse(to: contentView, label: "Installation Path:", y: yPosition, textField: installPathField, isDirectory: true)
        yPosition -= 25

        // Force reinstall
        forceCheckbox = NSButton(checkboxWithTitle: "Force reinstall if already installed", target: nil, action: nil)
        forceCheckbox.frame = NSRect(x: 20, y: yPosition, width: 560, height: 20)
        forceCheckbox.state = .off
        contentView.addSubview(forceCheckbox)
        yPosition -= 25

        // Skip PATH
        skipPathCheckbox = NSButton(checkboxWithTitle: "Skip adding to PATH", target: nil, action: nil)
        skipPathCheckbox.frame = NSRect(x: 20, y: yPosition, width: 560, height: 20)
        skipPathCheckbox.state = .off
        contentView.addSubview(skipPathCheckbox)
        yPosition -= 35

        // Application Configuration Section
        let appLabel = createLabel("Application Configuration", fontSize: 14, bold: true)
        appLabel.frame = NSRect(x: 20, y: yPosition, width: 560, height: 20)
        contentView.addSubview(appLabel)
        yPosition -= 30

        // App Name
        yPosition = addLabeledField(to: contentView, label: "Application Name:", y: yPosition, defaultValue: "MyWheelsApp")
        appNameField = contentView.subviews.last as? NSTextField
        yPosition -= 25

        // Reload Password
        yPosition = addLabeledField(to: contentView, label: "Reload Password:", y: yPosition, defaultValue: "changeMe")
        reloadPasswordField = contentView.subviews.last as? NSTextField
        yPosition -= 25

        // Datasource Name
        yPosition = addLabeledField(to: contentView, label: "Datasource Name:", y: yPosition, defaultValue: "MyWheelsApp")
        datasourceNameField = contentView.subviews.last as? NSTextField
        yPosition -= 35

        // Template Selection
        let templateLabel = createLabel("Template:", fontSize: 12, bold: false)
        templateLabel.frame = NSRect(x: 20, y: yPosition, width: 150, height: 20)
        contentView.addSubview(templateLabel)

        templatePopup = NSPopUpButton(frame: NSRect(x: 180, y: yPosition - 3, width: 400, height: 25))
        templatePopup.addItems(withTitles: [
            "wheels-base-template@BE (3.0.x Bleeding Edge)",
            "wheels-base-template@stable (2.5.x Stable)",
            "wheels-htmx-template (HTMX + Alpine.js)",
            "wheels-starter-template (Starter App)",
            "wheels-todomvc-template (TodoMVC Demo)"
        ])
        contentView.addSubview(templatePopup)
        yPosition -= 35

        // Engine Selection
        let engineLabel = createLabel("CFML Engine:", fontSize: 12, bold: false)
        engineLabel.frame = NSRect(x: 20, y: yPosition, width: 150, height: 20)
        contentView.addSubview(engineLabel)

        enginePopup = NSPopUpButton(frame: NSRect(x: 180, y: yPosition - 3, width: 400, height: 25))
        enginePopup.addItems(withTitles: [
            "Lucee (Latest)",
            "Adobe ColdFusion (Latest)",
            "Lucee 6.x",
            "Lucee 5.x",
            "Adobe ColdFusion 2023",
            "Adobe ColdFusion 2021",
            "Adobe ColdFusion 2018"
        ])
        enginePopup.target = self
        enginePopup.action = #selector(engineChanged)
        contentView.addSubview(enginePopup)
        yPosition -= 35

        // Options Section
        let optionsLabel = createLabel("Additional Options", fontSize: 14, bold: true)
        optionsLabel.frame = NSRect(x: 20, y: yPosition, width: 560, height: 20)
        contentView.addSubview(optionsLabel)
        yPosition -= 25

        // H2 Database
        h2Checkbox = NSButton(checkboxWithTitle: "Setup H2 embedded database (Lucee only)", target: nil, action: nil)
        h2Checkbox.frame = NSRect(x: 20, y: yPosition, width: 560, height: 20)
        h2Checkbox.state = .off
        contentView.addSubview(h2Checkbox)
        yPosition -= 25

        // Bootstrap
        bootstrapCheckbox = NSButton(checkboxWithTitle: "Include Bootstrap CSS framework", target: nil, action: nil)
        bootstrapCheckbox.frame = NSRect(x: 20, y: yPosition, width: 560, height: 20)
        bootstrapCheckbox.state = .on
        contentView.addSubview(bootstrapCheckbox)
        yPosition -= 25

        // Package
        packageCheckbox = NSButton(checkboxWithTitle: "Initialize as package (create box.json)", target: nil, action: nil)
        packageCheckbox.frame = NSRect(x: 20, y: yPosition, width: 560, height: 20)
        packageCheckbox.state = .on
        contentView.addSubview(packageCheckbox)
        yPosition -= 30

        // App Base Path
        appBasePathField = NSTextField(frame: NSRect(x: 180, y: yPosition - 3, width: 320, height: 22))
        appBasePathField.stringValue = NSHomeDirectory() + "/Desktop/Sites"
        yPosition = addLabeledFieldWithBrowse(to: contentView, label: "Application Directory:", y: yPosition, textField: appBasePathField, isDirectory: true)
        yPosition -= 40

        // Install Button
        let installButton = NSButton(frame: NSRect(x: 430, y: 20, width: 150, height: 32))
        installButton.title = "Install"
        installButton.bezelStyle = .rounded
        installButton.keyEquivalent = "\r"
        installButton.target = self
        installButton.action = #selector(installButtonClicked)
        contentView.addSubview(installButton)

        // Cancel Button
        let cancelButton = NSButton(frame: NSRect(x: 340, y: 20, width: 80, height: 32))
        cancelButton.title = "Cancel"
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}"
        cancelButton.target = self
        cancelButton.action = #selector(cancelButtonClicked)
        contentView.addSubview(cancelButton)

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func createLabel(_ text: String, fontSize: CGFloat, bold: Bool) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = bold ? NSFont.boldSystemFont(ofSize: fontSize) : NSFont.systemFont(ofSize: fontSize)
        label.alignment = .left
        return label
    }

    func addLabeledField(to view: NSView, label: String, y: CGFloat, defaultValue: String) -> CGFloat {
        let labelField = createLabel(label, fontSize: 12, bold: false)
        labelField.frame = NSRect(x: 20, y: y, width: 150, height: 20)
        view.addSubview(labelField)

        let textField = NSTextField(frame: NSRect(x: 180, y: y - 3, width: 400, height: 22))
        textField.stringValue = defaultValue
        view.addSubview(textField)

        return y - 25
    }

    func addLabeledFieldWithBrowse(to view: NSView, label: String, y: CGFloat, textField: NSTextField, isDirectory: Bool) -> CGFloat {
        let labelField = createLabel(label, fontSize: 12, bold: false)
        labelField.frame = NSRect(x: 20, y: y, width: 150, height: 20)
        view.addSubview(labelField)

        textField.tag = 1000 + view.subviews.count  // Unique tag for text field
        view.addSubview(textField)

        let browseButton = NSButton(frame: NSRect(x: 510, y: y - 5, width: 70, height: 24))
        browseButton.title = "Browse"
        browseButton.bezelStyle = .rounded
        browseButton.target = self
        browseButton.action = #selector(browseButtonClicked(_:))
        browseButton.tag = textField.tag  // Same tag to link button to field
        view.addSubview(browseButton)

        return y - 25
    }

    @objc func browseButtonClicked(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select"

        if panel.runModal() == .OK {
            if let url = panel.url {
                // Find the text field with matching tag
                if let contentView = window.contentView {
                    if let textField = contentView.viewWithTag(sender.tag) as? NSTextField {
                        textField.stringValue = url.path
                    }
                }
            }
        }
    }

    @objc func engineChanged() {
        // Enable H2 only for Lucee engines
        let selectedEngine = enginePopup.titleOfSelectedItem ?? ""
        h2Checkbox.isEnabled = selectedEngine.contains("Lucee")
        if !h2Checkbox.isEnabled {
            h2Checkbox.state = .off
        }
    }

    @objc func cancelButtonClicked() {
        NSApp.terminate(nil)
    }

    @objc func installButtonClicked() {
        // Validate inputs
        guard !installPathField.stringValue.isEmpty else {
            showAlert("Installation path cannot be empty")
            return
        }

        guard !appNameField.stringValue.isEmpty else {
            showAlert("Application name cannot be empty")
            return
        }

        guard !appBasePathField.stringValue.isEmpty else {
            showAlert("Application directory cannot be empty")
            return
        }

        // Close main window
        window.close()

        // Show progress window
        showProgressWindow()

        // Run installation
        runInstallation()
    }

    func showProgressWindow() {
        let windowRect = NSRect(x: 0, y: 0, width: 600, height: 400)
        progressWindow = NSWindow(contentRect: windowRect,
                                 styleMask: [.titled, .closable],
                                 backing: .buffered,
                                 defer: false)
        progressWindow?.title = "Installing Wheels Application"
        progressWindow?.center()

        let contentView = NSView(frame: windowRect)
        progressWindow?.contentView = contentView

        // Progress label
        progressLabel = NSTextField(labelWithString: "Preparing installation...")
        progressLabel?.frame = NSRect(x: 20, y: 340, width: 560, height: 20)
        progressLabel?.alignment = .center
        contentView.addSubview(progressLabel!)

        // Progress indicator
        progressIndicator = NSProgressIndicator(frame: NSRect(x: 50, y: 300, width: 500, height: 20))
        progressIndicator?.style = .bar
        progressIndicator?.isIndeterminate = false
        progressIndicator?.minValue = 0
        progressIndicator?.maxValue = 100
        progressIndicator?.doubleValue = 0
        contentView.addSubview(progressIndicator!)

        // Output text view
        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 60, width: 560, height: 220))
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder

        outputTextView = NSTextView(frame: scrollView.bounds)
        outputTextView?.isEditable = false
        outputTextView?.font = NSFont.userFixedPitchFont(ofSize: 11)
        outputTextView?.backgroundColor = NSColor.black  // Black background like terminal
        outputTextView?.textColor = NSColor.white  // White text
        outputTextView?.insertionPointColor = NSColor.white
        scrollView.documentView = outputTextView
        contentView.addSubview(scrollView)

        // Delete DMG checkbox (initially hidden) - aligned with button
        deleteDMGCheckbox = NSButton(checkboxWithTitle: "Delete installer DMG file", target: nil, action: nil)
        deleteDMGCheckbox?.frame = NSRect(x: 20, y: 24, width: 300, height: 24)
        deleteDMGCheckbox?.state = .on
        deleteDMGCheckbox?.isHidden = true
        deleteDMGCheckbox?.tag = 998
        contentView.addSubview(deleteDMGCheckbox!)

        // Close button (initially hidden) - aligned with checkbox
        let closeButton = NSButton(frame: NSRect(x: 500, y: 20, width: 80, height: 32))
        closeButton.title = "Close"
        closeButton.bezelStyle = .rounded
        closeButton.isHidden = true
        closeButton.tag = 999
        closeButton.target = self
        closeButton.action = #selector(closeProgressWindow)
        contentView.addSubview(closeButton)

        progressWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func runInstallation() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Get script path
            let scriptPath = self.getScriptPath()

            // Build arguments
            var args: [String] = []
            args.append("--install-path")
            args.append(self.installPathField.stringValue)
            args.append("--app-name")
            args.append(self.appNameField.stringValue)
            args.append("--reload-password")
            args.append(self.reloadPasswordField.stringValue)
            args.append("--datasource-name")
            args.append(self.datasourceNameField.stringValue)
            args.append("--template")
            args.append(self.getTemplateValue())
            args.append("--engine")
            args.append(self.getEngineValue())
            args.append("--app-base-path")
            args.append(self.appBasePathField.stringValue)

            if self.h2Checkbox.state == .on {
                args.append("--use-h2")
            }
            if self.bootstrapCheckbox.state == .on {
                args.append("--use-bootstrap")
            }
            if self.packageCheckbox.state == .on {
                args.append("--init-package")
            }
            if self.forceCheckbox.state == .on {
                args.append("--force")
            }
            if self.skipPathCheckbox.state == .on {
                args.append("--skip-path")
            }

            // Run script
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/bash")
            task.arguments = [scriptPath] + args

            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe

            let outHandle = pipe.fileHandleForReading
            outHandle.readabilityHandler = { handle in
                let data = handle.availableData
                if let output = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.appendOutput(output)
                        self.updateProgress(from: output)
                    }
                }
            }

            do {
                try task.run()
                task.waitUntilExit()

                DispatchQueue.main.async {
                    let success = task.terminationStatus == 0
                    self.installationCompleted(success: success)
                }
            } catch {
                DispatchQueue.main.async {
                    self.appendOutput("\nERROR: Failed to run installation script: \(error.localizedDescription)\n")
                    self.installationCompleted(success: false)
                }
            }
        }
    }

    func getScriptPath() -> String {
        // Try to find script in bundle
        if let bundlePath = Bundle.main.resourcePath {
            let scriptPath = bundlePath + "/install-wheels.sh"
            if FileManager.default.fileExists(atPath: scriptPath) {
                return scriptPath
            }
        }

        // Fall back to script next to app
        if let appPath = Bundle.main.bundlePath as String? {
            let parentDir = (appPath as NSString).deletingLastPathComponent
            let scriptPath = parentDir + "/install-wheels.sh"
            if FileManager.default.fileExists(atPath: scriptPath) {
                return scriptPath
            }
        }

        return "./install-wheels.sh"
    }

    func getTemplateValue() -> String {
        let title = templatePopup.titleOfSelectedItem ?? ""
        if title.contains("Bleeding Edge") { return "wheels-base-template@BE" }
        if title.contains("Stable") { return "wheels-base-template@stable" }
        if title.contains("HTMX") { return "wheels-htmx-template" }
        if title.contains("Starter") { return "wheels-starter-template" }
        if title.contains("TodoMVC") { return "wheels-todomvc-template" }
        return "wheels-base-template@BE"
    }

    func getEngineValue() -> String {
        let title = enginePopup.titleOfSelectedItem ?? ""
        if title == "Lucee (Latest)" { return "lucee" }
        if title == "Adobe ColdFusion (Latest)" { return "adobe" }
        if title == "Lucee 6.x" { return "lucee@6" }
        if title == "Lucee 5.x" { return "lucee@5" }
        if title == "Adobe ColdFusion 2023" { return "adobe@2023" }
        if title == "Adobe ColdFusion 2021" { return "adobe@2021" }
        if title == "Adobe ColdFusion 2018" { return "adobe@2018" }
        return "lucee"
    }

    func appendOutput(_ text: String) {
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.userFixedPitchFont(ofSize: 11) ?? NSFont.systemFont(ofSize: 11)
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        outputTextView?.textStorage?.append(attributedString)
        outputTextView?.scrollToEndOfDocument(nil)
    }

    func updateProgress(from output: String) {
        // Update progress based on output
        if output.contains("COMMANDBOX INSTALLATION") {
            progressIndicator?.doubleValue = 20
            progressLabel?.stringValue = "Installing CommandBox..."
        } else if output.contains("WHEELS CLI") {
            progressIndicator?.doubleValue = 50
            progressLabel?.stringValue = "Installing Wheels CLI..."
        } else if output.contains("APPLICATION CREATION") {
            progressIndicator?.doubleValue = 70
            progressLabel?.stringValue = "Creating application..."
        } else if output.contains("DEVELOPMENT SERVER") {
            progressIndicator?.doubleValue = 90
            progressLabel?.stringValue = "Starting server..."
        } else if output.contains("INSTALLATION COMPLETE") {
            progressIndicator?.doubleValue = 100
            progressLabel?.stringValue = "Installation complete!"
        }
    }

    func installationCompleted(success: Bool) {
        progressIndicator?.doubleValue = 100

        if success {
            progressLabel?.stringValue = "✓ Installation completed successfully!"
            appendOutput("\n\n✓ Installation completed successfully!\n")

            // Show delete DMG checkbox only if installation was successful and DMG was detected
            if dmgPath != nil {
                deleteDMGCheckbox?.isHidden = false
            }

            // Open browser to Wheels docs
            if let url = URL(string: "https://wheels.dev/guides") {
                NSWorkspace.shared.open(url)
            }
        } else {
            progressLabel?.stringValue = "✗ Installation failed"
            appendOutput("\n\n✗ Installation failed. Please check the output above.\n")
        }

        // Show close button
        if let closeButton = progressWindow?.contentView?.viewWithTag(999) as? NSButton {
            closeButton.isHidden = false
        }
    }

    @objc func closeProgressWindow() {
        // Check if user wants to delete DMG
        if deleteDMGCheckbox?.state == .on, let dmgPath = dmgPath {
            deleteDMGFile(at: dmgPath)
        }
        NSApp.terminate(nil)
    }

    func deleteDMGFile(at path: String) {
        do {
            // First, try to unmount the DMG volume if it's still mounted
            if let bundlePath = Bundle.main.bundlePath as String? {
                if bundlePath.contains("/Volumes/") {
                    let volumeName = bundlePath.components(separatedBy: "/Volumes/")[1].components(separatedBy: "/")[0]
                    let volumePath = "/Volumes/\(volumeName)"

                    // Schedule unmount and delete for after app quits
                    let script = """
                    #!/bin/bash
                    sleep 1
                    diskutil unmount "\(volumePath)" 2>/dev/null
                    sleep 1
                    rm -f "\(path)"
                    rm -f "$0"
                    """

                    let scriptPath = NSTemporaryDirectory() + "cleanup-wheels-dmg.sh"
                    try script.write(toFile: scriptPath, atomically: true, encoding: .utf8)

                    // Make script executable
                    let chmod = Process()
                    chmod.executableURL = URL(fileURLWithPath: "/bin/chmod")
                    chmod.arguments = ["+x", scriptPath]
                    try chmod.run()
                    chmod.waitUntilExit()

                    // Execute cleanup script in background
                    let task = Process()
                    task.executableURL = URL(fileURLWithPath: "/bin/bash")
                    task.arguments = [scriptPath]
                    task.launch()

                    appendOutput("\nScheduled deletion of installer DMG: \(path)\n")
                }
            }
        } catch {
            appendOutput("\nWarning: Could not delete DMG file: \(error.localizedDescription)\n")
        }
    }

    func showAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Validation Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// Main entry point
let app = NSApplication.shared
let delegate = WheelsInstallerApp()
app.delegate = delegate
app.run()
