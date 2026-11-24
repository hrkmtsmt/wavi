import Foundation
import Testing

@testable import Wavi

struct VimMotionTests {
    @Test func movesByCharacterWithinTheLine() {
        #expect(after("l", "|abc").marked == "a|bc")
        #expect(after("lll", "|abc").marked == "ab|c")
        #expect(after("h", "a|bc").marked == "|abc")
        #expect(after("h", "ab\n|cd").marked == "ab\n|cd")
        #expect(after("3l", "|abcdef").marked == "abc|def")
    }

    @Test func emojiIsOneStep() {
        #expect(after("l", "|🌊x").marked == "🌊|x")
    }

    @Test func movesByWord() {
        #expect(after("w", "|hello world").marked == "hello |world")
        #expect(after("w", "|foo.bar").marked == "foo|.bar")
        #expect(after("W", "|foo.bar baz").marked == "foo.bar |baz")
        #expect(after("e", "|hello world").marked == "hell|o world")
        #expect(after("ee", "|hello world").marked == "hello worl|d")
        #expect(after("b", "hello wo|rld").marked == "hello |world")
        #expect(after("b", "hello |world").marked == "|hello world")
        #expect(after("w", "|end\nnext").marked == "end\n|next")
        #expect(after("w", "|a\n\nb").marked == "a\n|\nb")
        #expect(after("2w", "|one two three").marked == "one two |three")
    }

    @Test func movesToLineEdges() {
        #expect(after("$", "|abc\nde").marked == "ab|c\nde")
        #expect(after("0", "  ab|c").marked == "|  abc")
        #expect(after("^", "  ab|c").marked == "  |abc")
    }

    @Test func upAndDownKeepTheColumn() {
        #expect(after("j", "abc|def\nab\nabcdef").marked == "abcdef\na|b\nabcdef")
        #expect(after("jj", "abc|def\nab\nabcdef").marked == "abcdef\nab\nabc|def")
        #expect(after("k", "ab\nab|c").marked == "a|b\nabc")
        #expect(after("j", "a|b\nlast").marked == "ab\nl|ast")
        #expect(after("j", "only|").marked == "onl|y")
    }

    @Test func jumpsToLines() {
        #expect(after("gg", "one\ntwo\n  th|ree").marked == "|one\ntwo\n  three")
        #expect(after("G", "|one\ntwo\n  three").marked == "one\ntwo\n  |three")
        #expect(after("2G", "|one\n  two\nthree").marked == "one\n  |two\nthree")
    }
}

struct VimEditTests {
    @Test func deletesCharacters() {
        let x = after("x", "a|bc")
        #expect(x.marked == "a|c")
        #expect(x.clipboard == "b")
        #expect(after("x", "ab|c").marked == "a|b")
        #expect(after("2x", "|abcd").marked == "|cd")
        #expect(after("X", "ab|c").marked == "a|c")
    }

    @Test func deletesLines() {
        let dd = after("dd", "one\nt|wo\nthree")
        #expect(dd.marked == "one\n|three")
        #expect(dd.clipboard == "two\n")
        #expect(after("dd", "one\ntw|o").marked == "|one")
        #expect(after("2dd", "|one\ntwo\nthree").marked == "|three")
        #expect(after("dj", "|one\ntwo\nthree").marked == "|three")
        #expect(after("dd", "o|nly").marked == "|")
    }

    @Test func deletesWithMotions() {
        #expect(after("dw", "|hello world").marked == "|world")
        #expect(after("dw", "hello |world\nnext").marked == "hello| \nnext")
        #expect(after("de", "|hello world").marked == "| world")
        #expect(after("d$", "ab|cdef").marked == "a|b")
        #expect(after("D", "ab|cdef").marked == "a|b")
        #expect(after("d2w", "|one two three").marked == "|three")
        #expect(after("2dw", "|one two three").marked == "|three")
        #expect(after("db", "one tw|o").marked == "one |o")
    }

    @Test func changesAndEntersInsertMode() {
        var cw = Harness("|hello world")
        cw.type("cwbye<esc>")
        #expect(cw.marked == "by|e world")
        #expect(cw.engine.mode == .normal)

        var cc = Harness("one\n  t|wo\nthree")
        cc.type("ccnew<esc>")
        #expect(cc.text == "one\nnew\nthree")

        var c = Harness("ab|cd")
        c.type("Cxy<esc>")
        #expect(c.marked == "abx|y")
    }

    @Test func insertsAndAppends() {
        #expect(after("iX<esc>", "a|b").marked == "a|Xb")
        #expect(after("aX<esc>", "a|b").marked == "ab|X")
        #expect(after("AX<esc>", "a|b").marked == "ab|X")
        #expect(after("IX<esc>", "  a|b").marked == "  |Xab")
        #expect(after("oX<esc>", "a|b\nc").marked == "ab\n|X\nc")
        #expect(after("OX<esc>", "ab\n|c").marked == "ab\n|X\nc")
    }

    @Test func yanksAndPastes() {
        var lines = Harness("|one\ntwo")
        lines.type("yyjp")
        #expect(lines.text == "one\ntwo\none")
        #expect(lines.marked == "one\ntwo\n|one")

        var above = Harness("one\n|two")
        above.type("yykP")
        #expect(above.marked == "|two\none\ntwo")

        var word = Harness("|ab cd")
        word.type("ywP")
        #expect(word.text == "ab ab cd")

        #expect(after("p", "a|b", clipboard: "XY").marked == "abX|Y")
        #expect(after("P", "a|b", clipboard: "XY").marked == "aX|Yb")
        #expect(after("p", "|", clipboard: "XY").marked == "X|Y")
    }

    @Test func joinsLines() {
        #expect(after("J", "o|ne\n   two").marked == "one| two")
        #expect(after("3J", "|a\nb\nc").text == "a b c")
        #expect(after("J", "|last").marked == "|last")
    }

    @Test func replacesAndTogglesCase() {
        #expect(after("rx", "a|bc").marked == "a|xc")
        #expect(after("3rx", "|abcd").marked == "xx|xd")
        #expect(after("~~", "|abC").marked == "AB|C")
    }

    @Test func shiftsLines() {
        #expect(after(">>", "a|b").marked == "    |ab")
        #expect(after("<<", "      a|b").marked == "  |ab")
        #expect(after("2>>", "|a\nb").text == "    a\n    b")
    }

    @Test func undoAndRedoGoToTheTextView() {
        #expect(after("u<c-r>", "|a").history == [.undo, .redo])
    }

    @Test func escapeCancelsAHalfTypedCommand() {
        var harness = Harness("|one two")
        harness.type("d<esc>w")
        #expect(harness.marked == "one |two")
    }
}

struct VimVisualTests {
    @Test func deletesASelection() {
        var harness = Harness("a|bcde")
        harness.type("vlld")
        #expect(harness.marked == "a|e")
        #expect(harness.clipboard == "bcd")
        #expect(harness.engine.mode == .normal)
    }

    @Test func yanksWholeLines() {
        var harness = Harness("o|ne\ntwo\nthree")
        harness.type("Vjy")
        #expect(harness.clipboard == "one\ntwo\n")
        #expect(harness.text == "one\ntwo\nthree")
    }

    @Test func selectsAsItMoves() {
        var harness = Harness("|abc def")
        harness.type("vw")
        #expect(harness.selection == NSRange(location: 0, length: 5))
        harness.type("<esc>")
        #expect(harness.engine.mode == .normal)
        #expect(harness.selection.length == 0)
    }

    @Test func changesASelection() {
        var harness = Harness("|abc def")
        harness.type("vecX<esc>")
        #expect(harness.text == "X def")
    }
}

struct VimEndOfFileTests {
    @Test func aFinalLineBreakDoesNotMakeAnEmptyLine() {
        #expect(after("G", "|one\ntwo\n").marked == "one\n|two\n")
        #expect(after("j", "one\n|two\n").marked == "one\n|two\n")
        let dd = after("dd", "one\ntwo\n|")
        #expect(dd.text == "one\n")
        #expect(dd.clipboard == "two\n")
    }
}
