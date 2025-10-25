//
//  HotKeyManager.swift
//  Tahoe
//
//  Created by Claude
//

import AppKit
import Carbon

/// Manages global hot key registration and handling
class HotKeyManager {
    private var eventHandlers: [Int: () -> Void] = [:]
    private var installedHandlers: [EventHotKeyRef?] = []
    private var eventHandler: EventHandlerRef?

    enum HotKey {
        case toggleWindow  // ⌘⇧V
        case clearHistory  // ⌘⇧C

        var signature: OSType {
            switch self {
            case .toggleWindow: return OSType(fourCharCode: "tglw")
            case .clearHistory: return OSType(fourCharCode: "clrh")
            }
        }

        var id: UInt32 {
            switch self {
            case .toggleWindow: return 1
            case .clearHistory: return 2
            }
        }

        var intId: Int {
            return Int(id)
        }

        var keyCode: UInt32 {
            switch self {
            case .toggleWindow: return UInt32(kVK_ANSI_V)
            case .clearHistory: return UInt32(kVK_ANSI_C)
            }
        }

        var modifiers: UInt32 {
            // ⌘⇧ = Command + Shift
            return UInt32(cmdKey + shiftKey)
        }
    }

    /// Registers a hot key with a handler
    /// - Parameters:
    ///   - hotKey: The hot key to register
    ///   - handler: Closure to execute when hot key is pressed
    func register(_ hotKey: HotKey, handler: @escaping () -> Void) {
        var eventHotKeyID = EventHotKeyID(signature: hotKey.signature, id: hotKey.id)
        var eventHotKeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(
            hotKey.keyCode,
            hotKey.modifiers,
            eventHotKeyID,
            GetEventDispatcherTarget(),
            0,
            &eventHotKeyRef
        )

        guard status == noErr else {
            print("Failed to register hot key: \(hotKey)")
            return
        }

        // Store handler using Int key instead of EventHotKeyID
        eventHandlers[hotKey.intId] = handler
        installedHandlers.append(eventHotKeyRef)

        // Install event handler only once
        if eventHandler == nil {
            installGlobalEventHandler()
        }
    }

    private func installGlobalEventHandler() {
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        InstallEventHandler(
            GetEventDispatcherTarget(),
            { (_, inEvent, userData) -> OSStatus in
                var hotKeyID = EventHotKeyID() // var needed for GetEventParameter
                let status = GetEventParameter(
                    inEvent,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard status == noErr else {
                    return OSStatus(eventNotHandledErr)
                }

                // Get manager from userData
                guard let userData = userData else {
                    return OSStatus(eventNotHandledErr)
                }

                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()

                // Find handler by ID
                let keyId = Int(hotKeyID.id)
                guard let handler = manager.eventHandlers[keyId] else {
                    return OSStatus(eventNotHandledErr)
                }

                DispatchQueue.main.async {
                    handler()
                }

                return noErr
            },
            1,
            &eventSpec,
            selfPtr,
            &eventHandler
        )
    }

    /// Unregisters all hot keys
    func unregisterAll() {
        for ref in installedHandlers {
            if let ref = ref {
                UnregisterEventHotKey(ref)
            }
        }
        installedHandlers.removeAll()
        eventHandlers.removeAll()

        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    deinit {
        unregisterAll()
    }
}

// Helper to create OSType from string
extension OSType {
    init(fourCharCode: String) {
        precondition(fourCharCode.count == 4, "FourCharCode must be exactly 4 characters")
        var result: OSType = 0
        for char in fourCharCode.utf8 {
            result = (result << 8) | OSType(char)
        }
        self = result
    }
}
