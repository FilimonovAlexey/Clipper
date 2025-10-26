//
//  AppSettings.swift
//  Tahoe
//
//  Created by Claude
//

import Foundation
import SwiftUI
import Combine

/// User preferences stored in UserDefaults
class AppSettings: ObservableObject {
    private let defaults = UserDefaults.standard

    // Keys
    private enum Keys {
        static let itemLimit = "itemLimit"
        static let launchAtLogin = "launchAtLogin"
        static let appearanceMode = "appearanceMode"
    }

    @Published var itemLimit: Int {
        didSet {
            defaults.set(itemLimit, forKey: Keys.itemLimit)
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            updateLaunchAtLogin(launchAtLogin)
        }
    }

    @Published var appearanceMode: AppearanceMode {
        didSet {
            defaults.set(appearanceMode.rawValue, forKey: Keys.appearanceMode)
        }
    }

    init() {
        // Load saved values
        self.itemLimit = defaults.integer(forKey: Keys.itemLimit) == 0
            ? 100
            : defaults.integer(forKey: Keys.itemLimit)
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)

        if let modeString = defaults.string(forKey: Keys.appearanceMode),
           let mode = AppearanceMode(rawValue: modeString) {
            self.appearanceMode = mode
        } else {
            self.appearanceMode = .system
        }
    }

    /// Computed property for SwiftUI's preferredColorScheme
    var colorScheme: ColorScheme? {
        switch appearanceMode {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        // Note: Launch at login requires SMAppService (macOS 13+)
        // This is a placeholder - full implementation would use SMAppService
        // For now, we just store the preference
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }
}
