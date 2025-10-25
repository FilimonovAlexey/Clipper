//
//  PasteboardMonitor.swift
//  Tahoe
//
//  Created by Claude
//

import AppKit
import Combine

/// Monitors the system pasteboard for changes
class PasteboardMonitor: ObservableObject {
    private let pasteboard = NSPasteboard.general
    private var timer: Timer?
    private var lastChangeCount: Int
    private var onContentChange: ((String) -> Void)?

    init() {
        self.lastChangeCount = pasteboard.changeCount
    }

    /// Starts monitoring the pasteboard
    /// - Parameter interval: Polling interval in seconds (default: 0.5)
    /// - Parameter onChange: Callback when new content is detected
    func startMonitoring(interval: TimeInterval = 0.5, onChange: @escaping (String) -> Void) {
        self.onContentChange = onChange

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }

        // Add to RunLoop to ensure it works in background
        RunLoop.main.add(timer!, forMode: .common)
    }

    /// Stops monitoring the pasteboard
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkPasteboard() {
        let currentChangeCount = pasteboard.changeCount

        // Check if pasteboard content has changed
        guard currentChangeCount != lastChangeCount else { return }

        lastChangeCount = currentChangeCount

        // Extract string content
        guard let content = pasteboard.string(forType: .string) else { return }

        // Ignore empty or whitespace-only strings
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Notify about new content
        onContentChange?(trimmed)
    }

    deinit {
        stopMonitoring()
    }
}
