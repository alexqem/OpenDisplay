import Foundation

/// Safe runtime Objective-C class resolver ensuring graceful fallbacks
public enum DynamicObjCClass {
    /// Safely resolve an Objective-C class by name
    public static func resolve(_ className: String) -> NSObject.Type? {
        return NSClassFromString(className) as? NSObject.Type
    }

    /// Check if a selector is implemented by an instance
    public static func checkSelector(_ selectorName: String, on instance: AnyObject) -> Bool {
        return instance.responds(to: Selector(selectorName))
    }
}
