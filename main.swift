import Cocoa
import CoreGraphics

typealias CGSConnectionID = UInt32

@_silgen_name("CGSMainConnectionID")
func CGSMainConnectionID() -> CGSConnectionID

@_silgen_name("CGSCopyManagedDisplaySpaces")
func CGSCopyManagedDisplaySpaces(_ connection: CGSConnectionID) -> CFArray

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem!
    let defaultsKey = "CustomNamesBySpaceID"

    let names = [
        "BIO86",
        "CHEM33",
        "Consulting",
        "MARVL",
        "Personal",
        "Soh"
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "⌘ Space"

        buildMenu()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(spaceChanged),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )

        updateMenuBar()
    }

    func buildMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Assign Current Desktop", action: nil, keyEquivalent: ""))

        for name in names {
            let item = NSMenuItem(title: name, action: #selector(assignName(_:)), keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        let customItem = NSMenuItem(title: "Set Custom Name...", action: #selector(setCustomName), keyEquivalent: "")
        customItem.target = self
        menu.addItem(customItem)

        let refreshItem = NSMenuItem(title: "Refresh", action: #selector(refresh), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc func assignName(_ sender: NSMenuItem) {
        saveNameForCurrentSpace(sender.title)
        updateMenuBar()
    }

    @objc func setCustomName() {
        let alert = NSAlert()
        alert.messageText = "Name this Desktop"
        alert.informativeText = "This name will be saved for the current Mac desktop/Space."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        input.stringValue = currentSavedName() ?? ""
        alert.accessoryView = input

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            let name = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

            if !name.isEmpty {
                saveNameForCurrentSpace(name)
                updateMenuBar()
            }
        }
    }

    @objc func spaceChanged() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateMenuBar()
        }
    }

    @objc func refresh() {
        updateMenuBar()
    }

    func updateMenuBar() {
        let name = currentSavedName() ?? "Unlabeled"
        statusItem.button?.title = "⌘ \(name)"
    }

    func currentSavedName() -> String? {
        guard let spaceID = currentSpaceID() else {
            return nil
        }

        let savedNames = UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: String] ?? [:]
        return savedNames[spaceID]
    }

    func saveNameForCurrentSpace(_ name: String) {
        guard let spaceID = currentSpaceID() else {
            statusItem.button?.title = "⌘ Cannot detect Space"
            return
        }

        var savedNames = UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: String] ?? [:]
        savedNames[spaceID] = name
        UserDefaults.standard.set(savedNames, forKey: defaultsKey)
    }

    func currentSpaceID() -> String? {
        let connection = CGSMainConnectionID()
        let displays = CGSCopyManagedDisplaySpaces(connection) as NSArray

        for display in displays {
            guard let displayDict = display as? NSDictionary else {
                continue
            }

            if let currentSpace = displayDict["Current Space"] as? NSDictionary,
               let uuid = currentSpace["uuid"] as? String {
                return uuid
            }

            if let currentSpace = displayDict["Current Space"] as? NSDictionary,
               let managedSpaceID = currentSpace["ManagedSpaceID"] {
                return "\(managedSpaceID)"
            }
        }

        return nil
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()