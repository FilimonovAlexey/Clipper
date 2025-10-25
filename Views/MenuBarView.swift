//
//  MenuBarView.swift
//  Tahoe
//
//  Created by Claude
//

import SwiftUI

/// Main menu bar popover content
struct MenuBarView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    @ObservedObject var settings: AppSettings
    @State private var showingSettings = false

    var body: some View {
        ZStack {
            // Main clipboard view
            if !showingSettings {
                mainView
                    .transition(.move(edge: .leading))
            }

            // Settings view
            if showingSettings {
                SettingsView(settings: settings, onDismiss: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingSettings = false
                    }
                })
                .transition(.move(edge: .trailing))
            }
        }
        .frame(width: 380, height: 500)
        .background(.ultraThinMaterial)
    }

    private var mainView: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Search bar
            SearchBar(text: $clipboardManager.searchText)
                .padding(.bottom, 8)

            // Content
            if clipboardManager.filteredItems.isEmpty {
                emptyState
            } else {
                itemsList
            }

            Divider()

            // Footer
            footer
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 16, weight: .medium))
            Text("Clipper")
                .font(.system(size: 14, weight: .semibold))

            Spacer()

            Text("\(clipboardManager.items.count) items")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var itemsList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(clipboardManager.filteredItems) { item in
                    ClipboardItemRow(
                        item: item,
                        onCopy: {
                            clipboardManager.copyItem(id: item.id)
                        },
                        onDelete: {
                            withAnimation {
                                clipboardManager.deleteItem(id: item.id)
                            }
                        },
                        onTogglePin: {
                            withAnimation {
                                clipboardManager.togglePin(id: item.id)
                            }
                        }
                    )
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))

            Text(clipboardManager.searchText.isEmpty ? "No clipboard history" : "No results found")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            if clipboardManager.searchText.isEmpty {
                Text("Copy some text to get started")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.8))
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingSettings = true
                }
            }) {
                Label("Settings", systemImage: "gear")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)

            Spacer()

            if !clipboardManager.items.isEmpty {
                Button(action: {
                    withAnimation {
                        clipboardManager.clearAll()
                    }
                }) {
                    Label("Clear All", systemImage: "trash")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
            }

            Button(action: { NSApp.terminate(nil) }) {
                Text("Quit")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
