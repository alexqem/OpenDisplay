#if os(macOS) && arch(arm64)
import Foundation
import CoreGraphics

/// Configuration parameters for generating a Virtual Screen (Dummy Display)
public struct VirtualDisplayConfig: Sendable {
    public let name: String
    public let aspectPreset: DisplayAspectPreset
    public let baseWidth: UInt32
    public let refreshRate: Double
    public let isHiDPI: Bool

    public init(
        name: String,
        aspectPreset: DisplayAspectPreset = .ratio16_9,
        baseWidth: UInt32 = 3840,
        refreshRate: Double = VirtualDisplayLimits.defaultRefreshRate,
        isHiDPI: Bool = true
    ) {
        self.name = name
        self.aspectPreset = aspectPreset
        self.baseWidth = baseWidth
        self.refreshRate = refreshRate
        self.isHiDPI = isHiDPI
    }
}

/// Controller managing the lifecycle of software Virtual Displays (Dummy Screens) via CoreDisplay
public final class VirtualDisplayController: @unchecked Sendable {
    private var virtualDisplayInstance: AnyObject?
    public private(set) var displayID: CGDirectDisplayID = 0
    public let config: VirtualDisplayConfig

    public init?(config: VirtualDisplayConfig) {
        self.config = config

        guard let descriptorClass = DynamicObjCClass.resolve("CGVirtualDisplayDescriptor"),
              let displayClass = DynamicObjCClass.resolve("CGVirtualDisplay"),
              let settingsClass = DynamicObjCClass.resolve("CGVirtualDisplaySettings"),
              let modeClass = DynamicObjCClass.resolve("CGVirtualDisplayMode") else {
            return nil
        }

        let (maxWidth, maxHeight) = config.aspectPreset.dimensions(forWidth: config.baseWidth)

        // 1. Initialize and configure CGVirtualDisplayDescriptor
        let descriptor = descriptorClass.init()
        descriptor.setValue(DispatchQueue.main, forKey: "queue")
        descriptor.setValue(config.name, forKey: "name")
        descriptor.setValue(maxWidth, forKey: "maxPixelsWide")
        descriptor.setValue(maxHeight, forKey: "maxPixelsHigh")
        descriptor.setValue(VirtualDisplayLimits.defaultVendorID, forKey: "vendorID")
        descriptor.setValue(VirtualDisplayLimits.defaultProductID, forKey: "productID")
        descriptor.setValue(UInt32.random(in: 1000...99999), forKey: "serialNumber")

        // 2. Instantiate CGVirtualDisplay
        let displayAlloc = (displayClass as! NSObject.Type).alloc()
        let initSel = Selector(("initWithDescriptor:"))
        guard displayAlloc.responds(to: initSel) else { return nil }
        _ = displayAlloc.perform(initSel, with: descriptor)
        self.virtualDisplayInstance = displayAlloc

        // 3. Construct CGVirtualDisplayModes (generate native + scaled half modes for HiDPI)
        let modeInitSel = Selector(("initWithWidth:height:refreshRate:"))
        let modeAllocProto = (modeClass as! NSObject.Type).alloc()
        guard modeAllocProto.responds(to: modeInitSel) else { return nil }

        typealias ModeInitFunc = @convention(c) (AnyObject, Selector, UInt, UInt, Double) -> AnyObject

        func makeMode(width: UInt32, height: UInt32, rate: Double) -> AnyObject? {
            let alloc = (modeClass as! NSObject.Type).alloc()
            let imp = alloc.method(for: modeInitSel)
            let modeInit = unsafeBitCast(imp, to: ModeInitFunc.self)
            return modeInit(alloc, modeInitSel, UInt(width), UInt(height), rate)
        }

        var generatedModes: [AnyObject] = []
        let rates = VirtualDisplayLimits.standardRefreshRates

        // Native resolution at multiple refresh rates
        for rate in rates {
            if let mode = makeMode(width: maxWidth, height: maxHeight, rate: rate) {
                generatedModes.append(mode)
            }
        }

        // Half-resolution (2x HiDPI scale) modes
        if config.isHiDPI && maxWidth >= 2 && maxHeight >= 2 {
            let halfW = maxWidth / 2
            let halfH = maxHeight / 2
            for rate in rates {
                if let mode = makeMode(width: halfW, height: halfH, rate: rate) {
                    generatedModes.append(mode)
                }
            }
        }

        // 4. Construct and apply CGVirtualDisplaySettings
        let settings = settingsClass.init()
        settings.setValue(generatedModes, forKey: "modes")
        settings.setValue(config.isHiDPI ? VirtualDisplayLimits.hiDPIScaleFactor : 1, forKey: "hiDPI")

        let applySel = Selector(("applySettings:"))
        if (displayAlloc as AnyObject).responds(to: applySel) {
            _ = (displayAlloc as AnyObject).perform(applySel, with: settings)
        }

        // 5. Query assigned CGDirectDisplayID
        if let assignedID = (displayAlloc as AnyObject).value(forKey: "displayID") as? CGDirectDisplayID {
            self.displayID = assignedID
        }
    }

    deinit {
        // CoreDisplay tears down virtual display when reference is released
        virtualDisplayInstance = nil
    }
}
#endif
