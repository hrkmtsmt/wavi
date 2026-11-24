import Foundation
import Testing

@testable import Wavi

struct VimFindCharacterTests {
    @Test func findsOnTheLine() {
        #expect(after("fc", "|abcabc").marked == "ab|cabc")
        #expect(after("2fc", "|abcabc").marked == "abcab|c")
        #expect(after("tc", "|abcabc").marked == "a|bcabc")
        #expect(after("Fa", "abcab|c").marked == "abc|abc")
        #expect(after("Ta", "abcab|c").marked == "abca|bc")
        #expect(after("fz", "|abc").marked == "|abc")
        #expect(after("fx", "|ab\nx").marked == "|ab\nx")
    }

    @Test func repeatsWithSemicolonAndComma() {
        #expect(after("fc;", "|abcabc").marked == "abcab|c")
        #expect(after("fc;,", "|abcabc").marked == "ab|cabc")
        #expect(after("tc;", "|abcabc").marked == "abca|bc")
    }

    @Test func worksWithOperators() {
        #expect(after("dfc", "|abcd").marked == "|d")
        #expect(after("dtc", "|abcd").marked == "|cd")
        #expect(after("dFa", "xab|c").marked == "x|c")
        #expect(after("dfz", "|abc").marked == "|abc")
    }
}

struct VimBracketAndParagraphTests {
    @Test func jumpsToTheMatchingBracket() {
        #expect(after("%", "|f(a(b)c)").marked == "f(a(b)c|)")
        #expect(after("%", "f(a(b)c|)").marked == "f|(a(b)c)")
        #expect(after("%", "|{\n  x\n}").marked == "{\n  x\n|}")
        #expect(after("%", "|abc").marked == "|abc")
        #expect(after("d%", "x|(ab)y").marked == "x|y")
    }

    @Test func movesByParagraph() {
        #expect(after("}", "|a\nb\n\nc").marked == "a\nb\n|\nc")
        #expect(after("}}", "|a\n\nb\n\nc").marked == "a\n\nb\n|\nc")
        #expect(after("{", "a\n\nb\n|c").marked == "a\n|\nb\nc")
        #expect(after("}", "|a\nb").marked == "a\n|b")
    }

    @Test func movesByHalfPages() {
        var harness = Harness("|1\n2\n3\n4\n5\n6")
        harness.engine.halfPage = 2
        harness.type("<c-d>")
        #expect(harness.marked == "1\n2\n|3\n4\n5\n6")
        harness.type("<c-u>")
        #expect(harness.marked == "|1\n2\n3\n4\n5\n6")
    }
}

struct VimTextObjectTests {
    @Test func words() {
        #expect(after("diw", "one tw|o three").marked == "one | three")
        #expect(after("daw", "one tw|o three").marked == "one |three")
        #expect(after("daw", "one t|wo").marked == "on|e")
        #expect(after("ciwX<esc>", "a fo|o b").marked == "a |X b")
        let yank = after("yiw", "a fo|o b")
        #expect(yank.clipboard == "foo")
        #expect(yank.text == "a foo b")
    }

    @Test func quotes() {
        #expect(after("di\"", "say \"h|i there\" ok").marked == "say \"|\" ok")
        #expect(after("da\"", "say \"h|i\" ok").marked == "say | ok")
        #expect(after("di'", "|x = 'abc'").marked == "x = '|'")
        #expect(after("di\"", "|no quotes").marked == "|no quotes")
    }

    @Test func brackets() {
        #expect(after("di(", "f(a, |b)").marked == "f(|)")
        #expect(after("da(", "f(a, |b)").marked == "|f")
        #expect(after("di(", "f(a(|b)c)").marked == "f(a(|)c)")
        #expect(after("di)", "f(a, b|)").marked == "f(|)")
        #expect(after("di{", "x {\n  |y\n}").marked == "x {|}")
        #expect(after("di[", "|[1, 2]").marked == "[|]")
        #expect(after("dib", "f(|a)").marked == "f(|)")
    }

    @Test func selectsInVisualMode() {
        var harness = Harness("say \"h|i there\"")
        harness.type("vi\"")
        #expect(harness.selection == NSRange(location: 5, length: 8))
        harness.type("d")
        #expect(harness.text == "say \"\"")
    }
}

struct VimRepeatTests {
    @Test func repeatsAnOperator() {
        #expect(after("dw.", "|one two three").marked == "|three")
        #expect(after("x..", "|abcd").marked == "|d")
        #expect(after("dd.", "|a\nb\nc").marked == "|c")
    }

    @Test func repeatsTypedText() {
        var harness = Harness("|a\nb")
        harness.type("AX<esc>j.")
        #expect(harness.text == "aX\nbX")

        var change = Harness("|foo bar")
        change.type("cwnew<esc>w.")
        #expect(change.text == "new new")
    }

    @Test func repeatsWithACount() {
        #expect(after("x3.", "|abcdef").marked == "|ef")
    }

    @Test func motionsAndUndoAreNotChanges() {
        var harness = Harness("|abc")
        harness.type("xl.")
        #expect(harness.text == "b")
        harness = Harness("|abc")
        harness.type("x u.")
        #expect(harness.text == "c")
    }

    @Test func nothingToRepeatDoesNothing() {
        #expect(after(".", "a|b").marked == "a|b")
    }

    @Test func isOneEdit() {
        var harness = Harness("|a\nb")
        harness.type("AX<esc>j")
        let outcome = harness.engine.handle(VimKey("."), text: harness.text, selection: harness.selection, clipboard: nil)
        #expect(outcome.edits.count == 1)
    }

    @Test func difference() {
        #expect(VimEngine.difference(from: "abc", to: "abc") == nil)
        #expect(VimEngine.difference(from: "abc", to: "aXc") == VimEdit(range: NSRange(location: 1, length: 1), replacement: "X"))
        #expect(VimEngine.difference(from: "a🌊b", to: "a🌍b") == VimEdit(range: NSRange(location: 1, length: 2), replacement: "🌍"))
    }
}

struct VimSearchTests {
    @Test func asksTheTextViewToSearch() {
        #expect(after("/", "|abc").searches == [.prompt(backward: false)])
        #expect(after("?n", "|abc").searches == [.prompt(backward: true), .next(backward: true)])
        #expect(after("/nN", "|abc").searches == [.prompt(backward: false), .next(backward: false), .next(backward: true)])
        #expect(after("*", "a fo|o b").searches == [.word("foo", backward: false)])
        #expect(after("#n", "fo|o").searches == [.word("foo", backward: true), .next(backward: true)])
        #expect(after("*", "a | b").searches.isEmpty)
    }
}
