import AppKit

/// Opaque clipboard snapshot so callers can restore without knowing the
/// underlying data model.
struct PasteboardSnapshot: Sendable {
    fileprivate let items: [[String: Data]]
    static let empty = PasteboardSnapshot(items: [])
}

/// Abstraction over `NSPasteboard.general` so the selection reader is testable.
protocol Pasteboard: AnyObject, Sendable {
    var changeCount: Int { get }
    func readString() -> String?
    func write(_ string: String)
    func snapshot() -> PasteboardSnapshot
    func restore(_ snapshot: PasteboardSnapshot)
}

final class SystemPasteboard: Pasteboard, @unchecked Sendable {
    private let pb = NSPasteboard.general

    var changeCount: Int { pb.changeCount }

    func readString() -> String? {
        pb.string(forType: .string)
    }

    func write(_ string: String) {
        pb.clearContents()
        pb.setString(string, forType: .string)
    }

    func snapshot() -> PasteboardSnapshot {
        guard let items = pb.pasteboardItems else { return .empty }
        let copied: [[String: Data]] = items.map { item in
            var dict: [String: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    dict[type.rawValue] = data
                }
            }
            return dict
        }
        return PasteboardSnapshot(items: copied)
    }

    func restore(_ snapshot: PasteboardSnapshot) {
        pb.clearContents()
        let restored = snapshot.items.map { dict -> NSPasteboardItem in
            let item = NSPasteboardItem()
            for (typeRaw, data) in dict {
                item.setData(data, forType: NSPasteboard.PasteboardType(typeRaw))
            }
            return item
        }
        if !restored.isEmpty {
            pb.writeObjects(restored)
        }
    }
}
