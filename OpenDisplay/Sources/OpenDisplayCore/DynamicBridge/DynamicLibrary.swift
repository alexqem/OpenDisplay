import Foundation

/// Safe dynamic library handle loader implementing RAII and typed dlsym resolution
public final class DynamicLibrary: @unchecked Sendable {
    public let path: String?
    private let isDefaultHandle: Bool
    private let handle: UnsafeMutableRawPointer?

    public init?(path: String) {
        self.path = path
        self.isDefaultHandle = false
        self.handle = dlopen(path, RTLD_LAZY)
        guard self.handle != nil else { return nil }
    }

    /// Default RTLD_DEFAULT loader (for already linked symbols)
    public init() {
        self.path = nil
        self.isDefaultHandle = true
        self.handle = UnsafeMutableRawPointer(bitPattern: -2) // RTLD_DEFAULT
    }

    deinit {
        if !isDefaultHandle, let handle = handle {
            dlclose(handle)
        }
    }

    /// Resolve symbol with type safety. T should be an Optional C-function type.
    public func resolve<T>(_ symbol: String, as type: T.Type) -> T? {
        guard let handle = handle,
              let ptr = dlsym(handle, symbol) else {
            return nil
        }
        return unsafeBitCast(ptr, to: type)
    }

    public var isLoaded: Bool {
        return handle != nil
    }
}
