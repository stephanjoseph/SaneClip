import SwiftUI
import Combine

@MainActor
@Observable
class SettingsModel {
    static let shared = SettingsModel()

    var maxHistorySize: Int {
        didSet {
            UserDefaults.standard.set(maxHistorySize, forKey: "maxHistorySize")
        }
    }

    var showInDock: Bool {
        didSet {
            UserDefaults.standard.set(showInDock, forKey: "showInDock")
            applyDockVisibility()
        }
    }

    var protectPasswords: Bool {
        didSet {
            UserDefaults.standard.set(protectPasswords, forKey: "protectPasswords")
        }
    }

    var requireTouchID: Bool {
        didSet {
            UserDefaults.standard.set(requireTouchID, forKey: "requireTouchID")
        }
    }

    var excludedApps: [String] {
        didSet {
            UserDefaults.standard.set(excludedApps, forKey: "excludedApps")
        }
    }

    var playSounds: Bool {
        didSet {
            UserDefaults.standard.set(playSounds, forKey: "playSounds")
        }
    }

    var menuBarIcon: String {
        didSet {
            UserDefaults.standard.set(menuBarIcon, forKey: "menuBarIcon")
            NotificationCenter.default.post(name: .menuBarIconChanged, object: menuBarIcon)
        }
    }

    func isAppExcluded(_ bundleID: String?) -> Bool {
        guard let bundleID = bundleID else { return false }
        return excludedApps.contains(bundleID)
    }

    func addExcludedApp(_ bundleID: String) {
        if !excludedApps.contains(bundleID) {
            excludedApps.append(bundleID)
        }
    }

    func removeExcludedApp(_ bundleID: String) {
        excludedApps.removeAll { $0 == bundleID }
    }

    init() {
        self.maxHistorySize = UserDefaults.standard.object(forKey: "maxHistorySize") as? Int ?? 50
        self.showInDock = UserDefaults.standard.object(forKey: "showInDock") as? Bool ?? true
        self.protectPasswords = UserDefaults.standard.object(forKey: "protectPasswords") as? Bool ?? true
        self.requireTouchID = UserDefaults.standard.object(forKey: "requireTouchID") as? Bool ?? false
        self.excludedApps = UserDefaults.standard.object(forKey: "excludedApps") as? [String] ?? []
        self.playSounds = UserDefaults.standard.object(forKey: "playSounds") as? Bool ?? false
        self.menuBarIcon = UserDefaults.standard.object(forKey: "menuBarIcon") as? String ?? "list.clipboard.fill"
        applyDockVisibility()
    }

    private func applyDockVisibility() {
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
    }
}
