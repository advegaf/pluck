import Foundation

/// User-editable set of bundle IDs where Pluck should stay silent.
/// Backed by `UserDefaults` so changes are immediate across the app.
final class Blocklist: @unchecked Sendable {
    static let defaultBundleIDs: [String] = [
        "com.figma.Desktop",
        "com.figma.DesktopBeta",
        "com.bohemiancoding.sketch3",
        "com.adobe.Photoshop",
        "com.adobe.illustrator",
        "org.blenderfoundation.blender",
        "com.unity3d.UnityEditor5.x",
        "com.unity.UnityHub",
        "com.epicgames.UnrealEditor",
        "com.microsoft.Excel",
        "com.apple.iWork.Numbers",
        "com.apple.Finder",
    ]

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "pluck.blocklist") {
        self.defaults = defaults
        self.key = key
        if defaults.array(forKey: key) == nil {
            defaults.set(Self.defaultBundleIDs, forKey: key)
        }
    }

    var bundleIDs: [String] {
        get { (defaults.array(forKey: key) as? [String]) ?? [] }
        set {
            let cleaned = Array(Set(newValue.map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty })).sorted()
            defaults.set(cleaned, forKey: key)
        }
    }

    func contains(_ bundleID: String) -> Bool {
        Set(bundleIDs).contains(bundleID)
    }

    func add(_ bundleID: String) {
        var current = bundleIDs
        if !current.contains(bundleID) {
            current.append(bundleID)
            bundleIDs = current
        }
    }

    func remove(_ bundleID: String) {
        bundleIDs = bundleIDs.filter { $0 != bundleID }
    }

    func resetToDefaults() {
        bundleIDs = Self.defaultBundleIDs
    }
}
