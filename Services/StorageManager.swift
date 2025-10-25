//
//  StorageManager.swift
//  Tahoe
//
//  Created by Claude
//

import Foundation

/// Manages persistent storage of clipboard history
class StorageManager {
    private let fileManager = FileManager.default
    private let fileName = "clipboard_history.json"

    private var fileURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupport.appendingPathComponent("Clipper", isDirectory: true)

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: appDirectory.path) {
            try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        }

        return appDirectory.appendingPathComponent(fileName)
    }

    /// Saves clipboard items to disk
    /// - Parameter items: Array of ClipboardItem to save
    func save(_ items: [ClipboardItem]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Error saving clipboard history: \(error.localizedDescription)")
        }
    }

    /// Loads clipboard items from disk
    /// - Returns: Array of ClipboardItem, or empty array if none exist
    func load() -> [ClipboardItem] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let items = try decoder.decode([ClipboardItem].self, from: data)
            return items
        } catch {
            print("Error loading clipboard history: \(error.localizedDescription)")
            return []
        }
    }

    /// Clears all saved data
    func clearAll() {
        try? fileManager.removeItem(at: fileURL)
    }
}
