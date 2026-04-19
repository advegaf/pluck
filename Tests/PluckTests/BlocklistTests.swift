import Testing
import Foundation
@testable import Pluck

private func freshDefaults() -> UserDefaults {
    UserDefaults(suiteName: "pluck.test.blocklist.\(UUID().uuidString)")!
}

struct BlocklistTests {
    @Test func initWithEmptyDefaultsSeedsDefaults() {
        let defaults = freshDefaults()
        let bl = Blocklist(defaults: defaults, key: "pluck.blocklist")
        #expect(Set(bl.bundleIDs) == Set(Blocklist.defaultBundleIDs))
    }

    @Test func initWithStoredValuesKeepsThem() {
        let defaults = freshDefaults()
        defaults.set(["com.custom.app"], forKey: "pluck.blocklist")
        let bl = Blocklist(defaults: defaults, key: "pluck.blocklist")
        #expect(bl.bundleIDs == ["com.custom.app"])
    }

    @Test func addAndRemoveRoundTrips() {
        let defaults = freshDefaults()
        defaults.set([], forKey: "pluck.blocklist")
        let bl = Blocklist(defaults: defaults, key: "pluck.blocklist")
        bl.add("com.a")
        bl.add("com.b")
        bl.add("com.a")
        #expect(Set(bl.bundleIDs) == Set(["com.a", "com.b"]))
        #expect(bl.contains("com.a"))
        bl.remove("com.a")
        #expect(!bl.contains("com.a"))
        #expect(bl.contains("com.b"))
    }

    @Test func resetToDefaultsRestoresCanonicalList() {
        let defaults = freshDefaults()
        defaults.set(["com.one"], forKey: "pluck.blocklist")
        let bl = Blocklist(defaults: defaults, key: "pluck.blocklist")
        bl.resetToDefaults()
        #expect(Set(bl.bundleIDs) == Set(Blocklist.defaultBundleIDs))
    }
}
