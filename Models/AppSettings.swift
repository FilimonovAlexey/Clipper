//
//  AppSettings.swift
//  Tahoe
//
//  Created by Claude
//

import Foundation
import SwiftUI
import Combine
import AppKit

/// User preferences stored in UserDefaults
class AppSettings: ObservableObject {
    private let defaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()

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

    @Published var appearanceMode: AppearanceMode

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

        // Apply initial appearance
        applyAppearance(self.appearanceMode)

        // Subscribe to appearanceMode changes using Combine
        // This happens OUTSIDE of the view update cycle
        $appearanceMode
            .dropFirst() // Skip initial value (already applied above)
            .sink { [weak self] newMode in
                self?.defaults.set(newMode.rawValue, forKey: Keys.appearanceMode)
                self?.applyAppearance(newMode)
            }
            .store(in: &cancellables)
    }

    private func applyAppearance(_ mode: AppearanceMode) {
        // Apply appearance change on next run loop to avoid publishing during view update
        DispatchQueue.main.async {
            switch mode {
            case .system:
                NSApp.appearance = nil
            case .light:
                NSApp.appearance = NSAppearance(named: .aqua)
            case .dark:
                NSApp.appearance = NSAppearance(named: .darkAqua)
            }
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
