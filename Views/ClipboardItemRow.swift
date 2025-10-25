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

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Pin indicator
            Image(systemName: item.isPinned ? "pin.fill" : "")
                .font(.system(size: 10))
                .foregroundColor(.accentColor)
                .frame(width: 12)
                .opacity(item.isPinned ? 1 : 0)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.content)
                    .font(.system(size: 13))
                    .lineLimit(isHovering ? nil : 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

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
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.green.opacity(0.1))
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? Color(nsColor: .selectedContentBackgroundColor).opacity(0.5) : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
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
