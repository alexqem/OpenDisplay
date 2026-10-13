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
    private typealias IOAVServiceCreateFunc = @convention(c) (CFAllocator?, io_service_t) -> UnsafeMutableRawPointer?
    private typealias IOAVServiceSetVirtualEDIDModeFunc = @convention(c) (UnsafeMutableRawPointer, CFData) -> kern_return_t

    /// Apply patched EDID on Apple Silicon on the fly without rebooting
    public static func applyLiveVirtualEDID(service: io_service_t, patchedEDID: [UInt8]) -> Bool {
        let library = DynamicLibrary()
        guard let createFn = library.resolve("_IOAVServiceCreateWithService", as: IOAVServiceCreateFunc.self),
              let setVirtualEDIDFn = library.resolve("_IOAVServiceSetVirtualEDIDMode", as: IOAVServiceSetVirtualEDIDModeFunc.self),
              let avHandle = createFn(kCFAllocatorDefault, service) else {
            return false
        }

        let cfData = Data(patchedEDID) as CFData
        let kr = setVirtualEDIDFn(avHandle, cfData)
        return kr == KERN_SUCCESS
    }
    #endif
}
