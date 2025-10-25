//
//  ClipboardManager.swift
//  Tahoe
//
//  Created by Claude
//

import AppKit
import Combine
import SwiftUI

/// Main view model managing clipboard history and operations
@MainActor
class ClipboardManager: ObservableObject {
    @Published var items: [ClipboardItem] = []
    @Published var searchText: String = ""

    private let pasteboardMonitor = PasteboardMonitor()
    private let storageManager = StorageManager()
    private var settings: AppSettings
    private var cancellables = Set<AnyCancellable>()

    // Flag to ignore clipboard changes made by Tahoe itself
    private var isIgnoringNextChange = false
    private var lastCopiedContent: String?

    /// Filtered items based on search text, with pinned items at the top
    var filteredItems: [ClipboardItem] {
        let filtered: [ClipboardItem]

        if searchText.isEmpty {
            filtered = items
        } else {
            filtered = items.filter { item in
                item.content.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Sort: pinned items first, then by timestamp (newest first)
        return filtered.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned
            }
            return lhs.timestamp > rhs.timestamp
        }
    }

    init(settings: AppSettings) {
        self.settings = settings
        loadHistory()
        startMonitoring()

        // Observe settings changes
        settings.$itemLimit
            .sink { [weak self] limit in
                self?.enforceItemLimit(limit)
            }
            .store(in: &cancellables)
    }

    /// Starts monitoring the pasteboard
    func startMonitoring() {
        pasteboardMonitor.startMonitoring { [weak self] content in
            Task { @MainActor in
                self?.addItem(content)
            }
        }
    }

    /// Stops monitoring the pasteboard
    nonisolated func stopMonitoring() {
        pasteboardMonitor.stopMonitoring()
    }

    /// Adds a new item to the history
    /// - Parameter content: The text content to add
    func addItem(_ content: String) {
        // Ignore if this change was made by Tahoe itself (copying from history)
        if isIgnoringNextChange && content == lastCopiedContent {
            isIgnoringNextChange = false
            lastCopiedContent = nil
            return
        }

        // Reset flag just in case
        isIgnoringNextChange = false
        lastCopiedContent = nil

        // Prevent consecutive duplicates
        if let lastItem = items.first, lastItem.content == content {
            return
        }

        let newItem = ClipboardItem(content: content)
        items.insert(newItem, at: 0)

        enforceItemLimit(settings.itemLimit)
        saveHistory()
    }

    /// Copies an item back to the pasteboard
    /// - Parameter id: The ID of the item to copy
    func copyItem(id: UUID) {
        guard let item = items.first(where: { $0.id == id }) else { return }

        // Mark that we're copying from Tahoe, so ignore the next clipboard change
        isIgnoringNextChange = true
        lastCopiedContent = item.content

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)

        // Provide haptic feedback
        NSHapticFeedbackManager.defaultPerformer.perform(
            .alignment,
            performanceTime: .default
        )
    }

    /// Deletes an item from history
    /// - Parameter id: The ID of the item to delete
    func deleteItem(id: UUID) {
        items.removeAll { $0.id == id }
        saveHistory()
    }

    /// Toggles the pinned state of an item
    /// - Parameter id: The ID of the item to toggle
    func togglePin(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isPinned.toggle()
        saveHistory()
    }

    /// Clears all items from history
    func clearAll() {
        items.removeAll()
        storageManager.clearAll()
    }

    /// Saves history to persistent storage
    private func saveHistory() {
        storageManager.save(items)
    }

    /// Loads history from persistent storage
    private func loadHistory() {
        items = storageManager.load()
    }

    /// Enforces the maximum item limit by removing oldest non-pinned items
    private func enforceItemLimit(_ limit: Int) {
        guard items.count > limit else { return }

        // Keep all pinned items + newest items up to limit
        let pinned = items.filter { $0.isPinned }
        let unpinned = items.filter { !$0.isPinned }

        let allowedUnpinned = max(0, limit - pinned.count)
        let trimmedUnpinned = Array(unpinned.prefix(allowedUnpinned))

        items = pinned + trimmedUnpinned
        saveHistory()
    }

    nonisolated deinit {
        stopMonitoring()
    }
}
