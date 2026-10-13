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
