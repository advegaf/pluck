import Testing
@testable import Pluck

struct CopiedPillTests {
    @Test func labelNamesTheCount() {
        #expect(CopiedPill.label(characterCount: 42) == "Copied 42 characters")
    }

    @Test func labelUsesTheSingularForOne() {
        #expect(CopiedPill.label(characterCount: 1) == "Copied 1 character")
    }

    /// The count is of what a person sees: an emoji with a skin-tone
    /// modifier is one character, though it is two Unicode scalars.
    @Test func countIsOfGraphemeClusters() {
        let text = "hi \u{1F44B}\u{1F3FD}"
        #expect(text.unicodeScalars.count == 5)
        #expect(CopiedPill.label(characterCount: text.count) == "Copied 4 characters")
    }
}
