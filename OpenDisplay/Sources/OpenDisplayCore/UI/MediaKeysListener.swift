#if os(macOS) && arch(arm64)
import AppKit
import CoreGraphics

/// Global media key action types
public enum MediaKeyAction: Sendable {
    case brightnessUp
    case brightnessDown
    case volumeUp
    case volumeDown
    case mute
}

/// Global media key monitor supporting both CGEvent.tapCreate (NX_SYSDEFINED) and NSEvent globalMonitor
public final class MediaKeysListener {
    private var globalMonitor: Any?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    public var onAction: (@Sendable (MediaKeyAction) -> Void)?

    public init() {}

    /// Parse media key data word into MediaKeyAction (pure function, 100% testable offline)
    public static func parseMediaKeyAction(data1: Int) -> MediaKeyAction? {
        let keyCode = (data1 & MediaKeyConstants.keyCodeMask) >> MediaKeyConstants.keyCodeShift
        let keyFlags = data1 & MediaKeyConstants.keyFlagsMask
        let keyState = (keyFlags & MediaKeyConstants.keyStateMask) >> MediaKeyConstants.keyStateShift

        guard keyState == MediaKeyConstants.keyStateDown else {
            return nil
        }

        if keyCode == MediaKeyConstants.keyTypeBrightnessUp {
            return .brightnessUp
        } else if keyCode == MediaKeyConstants.keyTypeBrightnessDown {
            return .brightnessDown
        }
        return nil
    }

    /// Start listening for global key combinations with CGEvent tap fallback to NSEvent
    public func startListening() {
        startEventTap()
        if eventTap == nil {
            startNSEventMonitor()
        }
    }

    /// Primary event tap handler for NX_SYSDEFINED system media keys
    private func startEventTap() {
        guard eventTap == nil else { return }

        let mask = CGEventMask(1 << MediaKeyConstants.sysDefinedEventTypeRaw)
        let observer = Unmanaged.passUnretained(self).toOpaque()

        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { (_, _, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                let listener = Unmanaged<MediaKeysListener>.fromOpaque(refcon).takeUnretainedValue()

                if let nsEvent = NSEvent(cgEvent: event), nsEvent.subtype.rawValue == MediaKeyConstants.auxControlButtonsSubtype {
                    if let action = MediaKeysListener.parseMediaKeyAction(data1: nsEvent.data1) {
                        listener.onAction?(action)
                    }
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: observer
        )

        guard let tap else { return }
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        self.eventTap = tap
        self.runLoopSource = source
    }

    /// Secondary fallback monitor using NSEvent for standard keyboard F1/F2 keys
    private func startNSEventMonitor() {
        guard globalMonitor == nil else { return }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Carbon / AppKit key codes: F1 = 122 (0x7A), F2 = 120 (0x78)
            switch event.keyCode {
            case 122: // F1
                self?.onAction?(.brightnessDown)
            case 120: // F2
                self?.onAction?(.brightnessUp)
            default:
                break
            }
        }
    }

    /// Stop all listeners
    public func stopListening() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
            eventTap = nil
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
    }

    deinit {
        stopListening()
    }
}
#endif
