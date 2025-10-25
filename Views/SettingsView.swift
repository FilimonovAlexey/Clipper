//
//  SettingsView.swift
//  Tahoe
//
//  Created by Claude
//

import SwiftUI

/// Settings window
struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    // Local state to avoid publishing during view updates
    @State private var selectedAppearance: AppearanceMode = .system

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider()

            // Settings content
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("History Limit:")
                                .font(.system(size: 13))
                            Spacer()
                            Text("\(settings.itemLimit)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        Slider(value: Binding(
                            get: { Double(settings.itemLimit) },
                            set: { settings.itemLimit = Int($0) }
                        ), in: 50...500, step: 10)
                        .controlSize(.small)

                        Text("Maximum number of clipboard items to keep")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    Divider()
                        .padding(.vertical, 8)

                    Toggle(isOn: $settings.launchAtLogin) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Launch at Login")
                                .font(.system(size: 13))
                            Text("Start Tahoe automatically when you log in")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(.switch)

                    Divider()
                        .padding(.vertical, 8)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Appearance:")
                            .font(.system(size: 13))

                        Picker("", selection: $selectedAppearance) {
                            ForEach(AppearanceMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .onChange(of: selectedAppearance) { newValue in
                            // Apply change asynchronously to avoid publishing during view update
                            DispatchQueue.main.async {
                                settings.appearanceMode = newValue
                            }
                        }

                        Text("Choose the app's color scheme")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    Divider()
                        .padding(.vertical, 8)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Keyboard Shortcuts:")
                            .font(.system(size: 13, weight: .medium))

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("⌘⇧V")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(nsColor: .controlBackgroundColor))
                                    .cornerRadius(4)

                                Text("Toggle Clipper window")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            HStack {
                                Text("⌘⇧C")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(nsColor: .controlBackgroundColor))
                                    .cornerRadius(4)

                                Text("Clear all history")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }

                            HStack {
                                Text("ESC")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(nsColor: .controlBackgroundColor))
                                    .cornerRadius(4)

                                Text("Close window")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .padding(16)

            Spacer()

            // Footer
            Divider()

            HStack {
                Text("Clipper v1.0")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(16)
        }
        .frame(width: 450, height: 550)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            // Sync local state with settings when view appears
            selectedAppearance = settings.appearanceMode
        }
    }
}
