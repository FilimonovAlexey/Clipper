//
//  TahoeApp.swift
//  Tahoe
//
//  Created by Claude
//  macOS Menu Bar Clipboard Manager
//

import SwiftUI
import AppKit

@main
struct TahoeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

/// Application delegate handling menu bar and lifecycle
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?

    private var clipboardManager: ClipboardManager!
    private var settings: AppSettings!
    private var hotKeyManager: HotKeyManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize settings and managers
        settings = AppSettings()
        clipboardManager = ClipboardManager(settings: settings)
        hotKeyManager = HotKeyManager()

        // Setup menu bar
        setupMenuBar()

        // Setup hot keys
        setupHotKeys()

        // Setup ESC key monitor
        setupEventMonitor()

        // Apply appearance
        applyInitialAppearance()
    }

    private func setupMenuBar() {
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipper")
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Create popover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 380, height: 500)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: MenuBarView(
                clipboardManager: clipboardManager,
                settings: settings
            )
        )
    }

    private func setupHotKeys() {
        // ⌘⇧V - Toggle window
        hotKeyManager.register(.toggleWindow) { [weak self] in
            self?.togglePopover()
        }

        // ⌘⇧C - Clear history
        hotKeyManager.register(.clearHistory) { [weak self] in
            Task { @MainActor in
                self?.clipboardManager.clearAll()
            }
        }
    }

    private func setupEventMonitor() {
        // Monitor ESC key to close popover
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC key
                if self?.popover?.isShown == true {
                    self?.closePopover()
                    return nil
                }
            }
            return event
        }
    }

    private func applyInitialAppearance() {
        switch settings.appearanceMode {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    @objc private func togglePopover() {
        if let popover = popover {
            if popover.isShown {
                closePopover()
            } else {
                showPopover()
            }
        }
    }

    private func showPopover() {
        if let button = statusItem?.button, let popover = popover {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func closePopover() {
        popover?.performClose(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        hotKeyManager.unregisterAll()
        clipboardManager.stopMonitoring()
    }
}
