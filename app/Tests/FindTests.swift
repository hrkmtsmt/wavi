import Foundation
import Testing

@testable import Wavi

struct TextSearchTests {
    @Test func findsEveryMatchIgnoringCase() {
        let ranges = TextSearch.ranges(of: "error", in: "Error: x\nerror again\nERROR")
        #expect(ranges == [NSRange(location: 0, length: 5), NSRange(location: 9, length: 5), NSRange(location: 21, length: 5)])
    }

    @Test func doesNotOverlap() {
        #expect(TextSearch.ranges(of: "aa", in: "aaaa").count == 2)
    }

    @Test func countsInUTF16LikeTheTextView() {
        // 🌊 is two UTF-16 units, so the match after it starts at 3, as NSTextView counts.
        #expect(TextSearch.ranges(of: "b", in: "🌊ab") == [NSRange(location: 3, length: 1)])
        #expect(TextSearch.ranges(of: "ログ", in: "貼ったログ") == [NSRange(location: 3, length: 2)])
    }

    @Test func emptyQueryFindsNothing() {
        #expect(TextSearch.ranges(of: "", in: "abc").isEmpty)
    }

    @Test func stopsAtTheLimit() {
        #expect(TextSearch.ranges(of: "a", in: String(repeating: "a", count: 50), limit: 10).count == 10)
    }

    @Test func startsFromTheCursorAndWrapsRound() {
        let ranges = [NSRange(location: 2, length: 1), NSRange(location: 8, length: 1)]
        #expect(TextSearch.index(from: 0, in: ranges) == 0)
        #expect(TextSearch.index(from: 5, in: ranges) == 1)
        #expect(TextSearch.index(from: 9, in: ranges) == 0)
        #expect(TextSearch.index(from: 0, in: []) == nil)
    }
}

@MainActor
struct FindStateTests {
    @Test func nextAndPreviousWrapRound() {
        let find = FindState()
        find.query = "x"
        find.search(in: "x x x", from: 0)
        #expect(find.current == 0)
        find.next()
        find.next()
        #expect(find.current == 2)
        find.next()
        #expect(find.current == 0)
        find.previous()
        #expect(find.current == 2)
    }

    @Test func editingKeepsThePositionWithoutRevealing() {
        let find = FindState()
        find.query = "x"
        find.search(in: "x x x", from: 0)
        find.next()
        find.next()
        let request = find.revealRequest
        find.refresh(in: "x x")
        #expect(find.current == 1)
        #expect(find.revealRequest == request)
    }

    @Test func typingKeepsSearchingFromWhereTheBarOpened() {
        let text = "request ok\nERROR one\nERROR two"
        let find = FindState()
        find.open(from: 0)
        for query in ["e", "er", "err", "erro", "error"] {
            find.query = query
            find.search(in: text)
        }
        #expect(find.currentRange == NSRange(location: 11, length: 5))
    }

    @Test func noMatchesClearsTheCurrentOne() {
        let find = FindState()
        find.query = "zzz"
        find.search(in: "abc", from: 0)
        #expect(find.current == nil)
        #expect(find.currentRange == nil)
    }
}
