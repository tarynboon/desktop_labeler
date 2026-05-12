import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem!
    var currentSpaceName: String = "Desktop"
    let defaultsKey = "CustomSpaceNames"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🖥 Desktop"

        buildMenu()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(spaceChanged),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appChanged),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )

        updateLabelFromFrontmostApp()
    }

    func buildMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Choose Space Name", action: nil, keyEquivalent: ""))

        let names = [
            "BIO86",
            "CHEM33",
            "Consulting",
            "MARVL",
            "Personal",
            "Soh"
        ]

        for name in names {
            let item = NSMenuItem(title: name, action: #selector(setSpaceName(_:)), keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        let customItem = NSMenuItem(title: "Set Custom Name...", action: #selector(setCustomName), keyEquivalent: "")
        customItem.target = self
        menu.addItem(customItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc func setSpaceName(_ sender: NSMenuItem) {
        currentSpaceName = sender.title
        updateMenuBar()
        saveNameForCurrentApp(sender.title)
    }

    @objc func setCustomName() {
        let alert = NSAlert()
        alert.messageText = "Name this Desktop"
        alert.informativeText = "Example: Clinic, Real Estate, Email/Admin"
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        input.stringValue = currentSpaceName
        alert.accessoryView = input

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            let name = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                currentSpaceName = name
                updateMenuBar()
                saveNameForCurrentApp(name)
            }
        }
    }

    @objc func spaceChanged() {
        updateLabelFromFrontmostApp()
    }

    @objc func appChanged() {
        updateLabelFromFrontmostApp()
    }

    func updateMenuBar() {
        statusItem.button?.title = "🖥 \(currentSpaceName)"
    }

    func updateLabelFromFrontmostApp() {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleID = app.bundleIdentifier else {
            currentSpaceName = "Desktop"
            updateMenuBar()
            return
        }

        let savedNames = UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: String] ?? [:]

        if let savedName = savedNames[bundleID] {
            currentSpaceName = savedName
        } else {
            currentSpaceName = app.localizedName ?? "Desktop"
        }

        updateMenuBar()
    }

    func saveNameForCurrentApp(_ name: String) {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleID = app.bundleIdentifier else {
            return
        }

        var savedNames = UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: String] ?? [:]
        savedNames[bundleID] = name
        UserDefaults.standard.set(savedNames, forKey: defaultsKey)
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()