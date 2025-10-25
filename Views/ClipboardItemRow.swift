//
//  ClipboardItemRow.swift
//  Tahoe
//
//  Created by Claude
//

import SwiftUI

/// Individual clipboard item row
struct ClipboardItemRow: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    let onDelete: () -> Void
    let onTogglePin: () -> Void

    @State private var isHovering = false
    @State private var showCopiedBadge = false
    @State private var showFullTextPopover = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Pin indicator
            Group {
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.accentColor)
                } else {
                    Color.clear
                }
            }
            .frame(width: 12)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.content)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: false)
                    .popover(isPresented: $showFullTextPopover, arrowEdge: .trailing) {
                        ScrollView {
                            Text(item.content)
                                .font(.system(size: 13))
                                .padding(12)
                                .textSelection(.enabled)
                        }
                        .frame(maxWidth: 300, maxHeight: 400)
                        .background(.ultraThinMaterial)
                    }

                Text(item.relativeTime)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            // Action buttons (visible on hover)
            if isHovering {
                HStack(spacing: 4) {
                    Button(action: onTogglePin) {
                        Image(systemName: item.isPinned ? "pin.slash" : "pin")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(item.isPinned ? "Unpin" : "Pin")

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Delete")
                }
                .transition(.opacity)
            }

            // "Скопировано!" badge - appears when copied
            if showCopiedBadge {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 12))
                    Text("Скопировано!")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
                .shadow(color: .green.opacity(0.2), radius: 4, x: 0, y: 2)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Group {
                if isHovering {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                } else {
                    Color.clear
                }
            }
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }

            // Handle popover for long text
            if hovering && item.content.count > 100 {
                // Show popover after delay only for long text
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if isHovering && !showCopiedBadge {
                        showFullTextPopover = true
                    }
                }
            } else {
                showFullTextPopover = false
            }
        }
        .onTapGesture {
            showFullTextPopover = false
            onCopy()
            showCopiedBadge(duration: 1.5)
        }
    }

    private func showCopiedBadge(duration: Double = 1.5) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showCopiedBadge = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.easeOut(duration: 0.2)) {
                showCopiedBadge = false
            }
        }
    }
}
