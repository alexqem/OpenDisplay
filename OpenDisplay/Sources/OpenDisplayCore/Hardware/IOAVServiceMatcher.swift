#if os(macOS) && arch(arm64)
import Foundation
import IOKit
import CoreGraphics

/// Service descriptor pairing an IOKit service with a display location and EDID IDs
public struct DiscoveredAVService: Sendable {
    public let service: io_service_t
    public let location: String
    public let serviceClass: String
    public let vendorID: UInt32?
    public let productID: UInt32?

    public init(
        service: io_service_t,
        location: String,
        serviceClass: String,
        vendorID: UInt32? = nil,
        productID: UInt32? = nil
    ) {
        self.service = service
        self.location = location
        self.serviceClass = serviceClass
        self.vendorID = vendorID
        self.productID = productID
    }
}

/// Matches Apple Silicon IOKit display services (DCPAVServiceProxy & AppleCLCD2)
public enum IOAVServiceMatcher {
    private static let candidateClasses = ["DCPAVServiceProxy", "AppleCLCD2"]
    private static let maxParentLevels = 8

    /// Discover all active display coprocessor services on Apple Silicon
    public static func discoverServices() -> [DiscoveredAVService] {
        var results: [DiscoveredAVService] = []

        for className in candidateClasses {
            guard let matchingDict = IOServiceMatching(className) else { continue }
            var iterator: io_iterator_t = 0
            let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator)
            guard kr == KERN_SUCCESS else { continue }
            defer { IOObjectRelease(iterator) }

            while case let service = IOIteratorNext(iterator), service != 0 {
                let location = extractLocation(for: service) ?? "Display_\(service)"
                let (vendor, product) = extractVendorAndProduct(for: service)
                results.append(DiscoveredAVService(
                    service: service,
                    location: location,
                    serviceClass: className,
                    vendorID: vendor,
                    productID: product
                ))
            }
        }

        return results
    }

    /// Resolve the IOKit AV service backing a specific CoreGraphics display via EDID vendor/model matching
    public static func service(for displayID: CGDirectDisplayID) -> io_service_t? {
        let vendor = CGDisplayVendorNumber(displayID)
        let model = CGDisplayModelNumber(displayID)
        guard vendor != 0, model != 0 else { return nil }
        return discoverServices().first(where: { candidate in
            guard let candidateVendor = candidate.vendorID, let candidateProduct = candidate.productID else {
                return false
            }
            return candidateVendor == vendor && candidateProduct == model
        })?.service
    }

    /// Walk parent chain up to 8 levels to extract DisplayVendorID and DisplayProductID
    public static func extractVendorAndProduct(for service: io_service_t) -> (vendorID: UInt32?, productID: UInt32?) {
        var current = service
        IOObjectRetain(current)
        defer { IOObjectRelease(current) }

        for _ in 0..<maxParentLevels {
            if let vendor = readRegistryUInt32(entry: current, key: "DisplayVendorID"),
               let product = readRegistryUInt32(entry: current, key: "DisplayProductID") {
                return (vendor, product)
            }

            var parent: io_service_t = 0
            let kr = IORegistryEntryGetParentEntry(current, kIOServicePlane, &parent)
            guard kr == KERN_SUCCESS, parent != 0 else { break }
            IOObjectRelease(current)
            current = parent
        }

        return (nil, nil)
    }

    private typealias IOAVServiceCreateFunc = @convention(c) (CFAllocator?, io_service_t) -> UnsafeMutableRawPointer?
    private typealias IOAVServiceCopyEDIDFunc = @convention(c) (UnsafeMutableRawPointer, UnsafeMutablePointer<CFData?>) -> kern_return_t

    /// Extract raw EDID bytes from IOAVService or IOKit registry property "IODisplayEDID"
    public static func extractEDIDBytes(for service: io_service_t) -> [UInt8]? {
        // First attempt: read EDID directly from IOAVServiceCopyEDID (works on Apple Silicon DCPAVServiceProxy)
        let library = DynamicLibrary()
        if let createFn = library.resolve("_IOAVServiceCreateWithService", as: IOAVServiceCreateFunc.self) ??
                          library.resolve("IOAVServiceCreateWithService", as: IOAVServiceCreateFunc.self),
           let copyEDIDFn = library.resolve("_IOAVServiceCopyEDID", as: IOAVServiceCopyEDIDFunc.self) ??
                            library.resolve("IOAVServiceCopyEDID", as: IOAVServiceCopyEDIDFunc.self),
           let avHandle = createFn(kCFAllocatorDefault, service) {
            var edidData: CFData?
            let kr = copyEDIDFn(avHandle, &edidData)
            if kr == KERN_SUCCESS, let data = edidData as Data?, data.count >= 128 {
                return [UInt8](data)
            }
        }

        // Fallback: registry parent walk
        var current = service
        IOObjectRetain(current)
        defer { IOObjectRelease(current) }

        for _ in 0..<maxParentLevels {
            if let edidData = readRegistryData(entry: current, key: "IODisplayEDID") ?? readRegistryData(entry: current, key: "EDID") {
                return [UInt8](edidData)
            }

            var parent: io_service_t = 0
            let kr = IORegistryEntryGetParentEntry(current, kIOServicePlane, &parent)
            guard kr == KERN_SUCCESS, parent != 0 else { break }
            IOObjectRelease(current)
            current = parent
        }

        return nil
    }

    private static func readRegistryData(entry: io_service_t, key: String) -> Data? {
        guard let prop = IORegistryEntryCreateCFProperty(entry, key as CFString, kCFAllocatorDefault, 0) else {
            return nil
        }
        let val = prop.takeRetainedValue()
        if let data = val as? Data {
            return data
        }
        return nil
    }

    private static func readRegistryUInt32(entry: io_service_t, key: String) -> UInt32? {
        guard let prop = IORegistryEntryCreateCFProperty(entry, key as CFString, kCFAllocatorDefault, 0) else {
            return nil
        }
        let val = prop.takeRetainedValue()
        if let num = val as? NSNumber {
            return num.uint32Value
        }
        return nil
    }

    /// Extract display location string from IOKit registry
    private static func extractLocation(for service: io_service_t) -> String? {
        let key = "IODisplayLocation" as CFString
        guard let prop = IORegistryEntryCreateCFProperty(service, key, kCFAllocatorDefault, 0) else {
            return nil
        }
        let val = prop.takeRetainedValue()
        return val as? String
    }
}
#endif
