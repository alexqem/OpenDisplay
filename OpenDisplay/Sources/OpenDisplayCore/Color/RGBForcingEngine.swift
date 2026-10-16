import Foundation
#if os(macOS) && arch(arm64)
import IOKit
#endif

/// Engine responsible for fixing washed-out / pink screens by forcing RGB 4:4:4 color output
public enum RGBForcingEngine {

    /// Pure function patching a 256-byte EDID to clear YCbCr capabilities in CTA-861 extension block
    public static func patchEDIDForRGBOnly(edidBytes: [UInt8]) -> [UInt8]? {
        guard edidBytes.count >= (EDIDConstants.extensionBlockOffset + EDIDConstants.baseBlockLength) else {
            return nil
        }

        // Verify CTA-861 tag at offset 128
        let extStart = EDIDConstants.extensionBlockOffset
        guard edidBytes[extStart] == EDIDConstants.cta861ExtensionTag else {
            return nil
        }

        var patched = edidBytes

        // Byte 3 of CTA-861 (offset 128 + 3): Flags
        let flagsIndex = extStart + EDIDConstants.CTA861Flags.byteIndexInBlock
        patched[flagsIndex] &= ~EDIDConstants.CTA861Flags.ycbcr444Mask
        patched[flagsIndex] &= ~EDIDConstants.CTA861Flags.ycbcr422Mask

        // Recalculate Extension Block Checksum at byte 255
        let checksumIndex = extStart + EDIDConstants.baseBlockLength - 1
        var sum: UInt32 = 0
        for i in extStart..<checksumIndex {
            sum += UInt32(patched[i])
        }
        patched[checksumIndex] = UInt8((256 - (sum % 256)) % 256)

        return patched
    }

    /// Generate macOS Display Override XML plist content
    public static func generateDisplayOverridePlist(vendorID: UInt16, productID: UInt16, edidBytes: [UInt8]) -> String {
        let base64EDID = Data(edidBytes).base64EncodedString(options: .lineLength64Characters)
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>DisplayProductID</key>
            <integer>\(productID)</integer>
            <key>DisplayVendorID</key>
            <integer>\(vendorID)</integer>
            <key>IODisplayEDID</key>
            <data>
            \(base64EDID)
            </data>
        </dict>
        </plist>
        """
    }

    #if os(macOS) && arch(arm64)
    private typealias IOMFBOpenFunc = @convention(c) (io_service_t, mach_port_t, UInt32, UnsafeMutablePointer<UnsafeMutableRawPointer?>) -> kern_return_t
    private typealias IOMFBSetColorRemapModeFunc = @convention(c) (UnsafeMutableRawPointer, UInt32) -> kern_return_t

    /// Set low-level hardware display connection mode via QuartzCore CADisplay (BetterDisplay parity)
    /// Switches physical digital link between RGB Full Range and YCbCr 4:4:4 Limited Range in real-time.
    public static func setConnectionMode(displayID: UInt32, forceRGB: Bool) -> Bool {
        guard let caDisplayClass = NSClassFromString("CADisplay") as AnyObject as? NSObjectProtocol else {
            return false
        }
        let selDisplays = Selector(("displays"))
        guard caDisplayClass.responds(to: selDisplays),
              let displays = caDisplayClass.perform(selDisplays)?.takeUnretainedValue() as? [NSObject] else {
            return false
        }

        guard let targetDisplay = displays.first(where: {
            ($0.value(forKey: "displayId") as? UInt32) == displayID
        }) else {
            return false
        }

        guard let modes = targetDisplay.value(forKey: "availableModes") as? [NSObject],
              let currentMode = targetDisplay.value(forKey: "currentMode") as? NSObject else {
            return false
        }

        let curW = currentMode.value(forKey: "width") as? Int ?? 0
        let curH = currentMode.value(forKey: "height") as? Int ?? 0
        let curRate = currentMode.value(forKey: "refreshRate") as? Double ?? 0.0

        let matched = modes.first { mode in
            let w = mode.value(forKey: "width") as? Int ?? 0
            let h = mode.value(forKey: "height") as? Int ?? 0
            let rate = mode.value(forKey: "refreshRate") as? Double ?? 0.0
            let colorMode = mode.value(forKey: "colorMode") as? String ?? ""
            let isYCbCr = mode.value(forKey: "colorModeIsYCbCr") as? Bool ?? false

            guard w == curW && h == curH && abs(rate - curRate) < 1.0 else { return false }

            if forceRGB {
                return !isYCbCr && colorMode.contains("RGBFull")
            } else {
                return isYCbCr && (colorMode.contains("YCbCr444") || colorMode.contains("444"))
            }
        }

        guard let targetMode = matched else {
            return false
        }

        targetDisplay.setValue(targetMode, forKey: "currentMode")
        return true
    }

    /// Apply Appearance and Color Remap modes directly to the Apple Silicon Framebuffer (BetterDisplay parity)
    /// mode 0 = Standard, 1 = Inverted, 2 = Grayscale, 4 = Inverted Grayscale
    public static func setColorRemapMode(_ mode: UInt32) -> Bool {
        let path = "/System/Library/PrivateFrameworks/IOMobileFramebuffer.framework/IOMobileFramebuffer"
        guard let handle = dlopen(path, RTLD_NOW) else { return false }
        defer { dlclose(handle) }

        guard let openImp = dlsym(handle, "IOMobileFramebufferOpen"),
              let setRemapImp = dlsym(handle, "IOMobileFramebufferSetColorRemapMode") else {
            return false
        }

        let openFn = unsafeBitCast(openImp, to: IOMFBOpenFunc.self)
        let setRemapFn = unsafeBitCast(setRemapImp, to: IOMFBSetColorRemapModeFunc.self)

        guard let matching = IOServiceMatching("IOMobileFramebufferShim") else { return false }
        var iterator: io_iterator_t = 0
        let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        guard kr == KERN_SUCCESS else { return false }
        defer { IOObjectRelease(iterator) }

        var success = false
        while case let service = IOIteratorNext(iterator), service != 0 {
            var fb: UnsafeMutableRawPointer?
            if openFn(service, mach_task_self_, 0, &fb) == KERN_SUCCESS, let validFb = fb {
                let status = setRemapFn(validFb, mode)
                if status == KERN_SUCCESS {
                    success = true
                }
            }
        }
        return success
    }
    #endif
}
