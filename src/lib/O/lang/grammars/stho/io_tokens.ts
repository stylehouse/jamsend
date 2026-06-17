// $lib/O/lang/grammars/stho/io_tokens.ts — external tokenizer for the IO path.
//
// The path separators (/ , :) are context-sensitive: inside an IO path "/" is a
// leg separator, in host JS it is a regex|divide|comment.  A single tokenizer
// can't resolve that by precedence (Lezer picks the highest-precedence matching
// token, then checks validity — it does not fall through), so we decide here,
// where we can ask the parse stack what it wants and peek the next char:
//
//   - emit PathSep|PathComma|PathColon only when stack.canShift() it (i.e. the
//     parser is mid-path), so JS keeps its regex|divide|colon untouched|
//   - keep the path whitespace-tight: a separator followed by space|tab|EOL ends
//     the path, so an IO atom can sit inside a JS list|args (f(o %Foo, b)).
//
// The same canShift|tight discipline carries the capture suffix tokens, so a
// trailing capture rides only inside a path:
//   - CaptureDot    "." the value-grab lead-in, claimed only when a "$" follows.
//   - CaptureDollar "$" the capture marker, claimed only tight after a key|val|
//     dot (a leading "$var" stays an ordinary Sigil flowing in).
//   - CaptureName    the let-name, claimed only straight after a CaptureDollar,
//     so it never collides with a bare Name lineItem.
import { ExternalTokenizer, type Stack, type InputStream } from "@lezer/lr"

const SLASH = 47, COMMA = 44, COLON = 58, DOT = 46, DOLLAR = 36, USCORE = 95
const SPACE = 32, TAB = 9, NL = 10, EOF = -1
const SEMI = 59, LP = 40, RP = 41, LB = 91, RB = 93, LC = 123, RC = 125
const SQUOTE = 39, DQUOTE = 34, BTICK = 96, PERCENT = 37

const isWord  = (c: number) =>
    (c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c === USCORE
const isStart = (c: number) =>
    (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c === USCORE

// Built against a terms record so it serves both the live buildParser (terms
// supplied via the externalTokenizer option) and a generated parser (terms
// imported from the generated *.terms artifact and passed in by its wiring).
export function makePathSep(terms: {
    PathSep: number, PathComma: number, PathColon: number,
    CaptureDot: number, CaptureDollar: number, CaptureName: number,
    FlowSep: number, PathVal: number,
}): ExternalTokenizer {
    const SEP: Record<number, number> = {
        [SLASH]: terms.PathSep, [COMMA]: terms.PathComma, [COLON]: terms.PathColon,
    }
    return new ExternalTokenizer((input: InputStream, stack: Stack) => {
        // Capture let-name — only reachable straight after a CaptureDollar, so a
        // plain Name lineItem never gets misclaimed.
        if (isStart(input.next) && stack.canShift(terms.CaptureName)) {
            do { input.advance() } while (isWord(input.next))
            input.acceptToken(terms.CaptureName)
            return
        }
        // "..." FlowSep — the r/rm pattern→replacement separator.  Only emitted
        // when the parser is mid-IOing and can shift it (after the first IOpath
        // of an IOness2 verb), so host-JS spread {...x}/[...a]/f(...args) stays
        // Punct everywhere else.  Deliberately NOT whitespace-tight: spaces
        // around it are fine (`r %a ... %b` and `r %a...%b` both read).
        if (input.next === DOT
            && input.peek(1) === DOT && input.peek(2) === DOT
            && stack.canShift(terms.FlowSep)) {
            input.advance(); input.advance(); input.advance()
            input.acceptToken(terms.FlowSep)
            return
        }
        // "." value-grab lead-in — only mid-path, tight, and only before a "$"
        // so host-JS "a.b" and "3.0" keep their dots.
        if (input.next === DOT) {
            if (!stack.canShift(terms.CaptureDot)) return
            const before = input.peek(-1)
            if (before === SPACE || before === TAB) return
            if (input.peek(1) !== DOLLAR) return
            input.advance()
            input.acceptToken(terms.CaptureDot)
            return
        }
        // "$" capture marker — only tight after a key|val|dot; a leading "$var"
        // (before is a separator|space) stays an ordinary Sigil that flows in.
        if (input.next === DOLLAR) {
            if (!stack.canShift(terms.CaptureDollar)) return
            const before = input.peek(-1)
            if (!(isWord(before) || before === DOT)) return
            input.advance()
            input.acceptToken(terms.CaptureDollar)
            return
        }
        // loose peel value — a bare value carrying a non-word char (e.g.
        //  "no-direct-route").  Only in PeelVal position (canShift), tight right
        //  after the value colon, and only claimed when the run holds a char a plain
        //  Name|Number wouldn't: word-only ("mock") falls through to Name and numeric
        //  ("3", "3.6") to Number, so their string|number semantics are untouched.
        //  A space|comma|colon ends it (those still need quoting); a trailing ".$"
        //  capture is left for the capture tokens.  Stops at JS structure so it can
        //  never run away off the path.
        if (stack.canShift(terms.PathVal) && input.peek(-1) === COLON) {
            const c0 = input.next
            if (c0 !== SQUOTE && c0 !== DQUOTE && c0 !== BTICK && c0 !== DOLLAR) {
                const isTerm = (c: number) =>
                    c === SPACE || c === TAB || c === NL || c === EOF ||
                    c === COMMA || c === SLASH || c === COLON || c === SEMI || c === PERCENT ||
                    c === LP || c === RP || c === LB || c === RB || c === LC || c === RC
                let i = 0, sawExtra = false, c = input.peek(0)
                while (!isTerm(c)) {
                    if (c === DOLLAR) break                               // "$" row capture ends the value
                    if (c === DOT && input.peek(i + 1) === DOLLAR) break  // ".$" capture ends the value
                    if (c === DOT && input.peek(i + 1) === DOT && input.peek(i + 2) === DOT) break  // "..." FlowSep
                    if (!isWord(c) && c !== DOT) sawExtra = true          // "." kept for Number-safety
                    i++; c = input.peek(i)
                }
                if (i > 0 && sawExtra) {
                    for (let k = 0; k < i; k++) input.advance()
                    input.acceptToken(terms.PathVal)
                    return
                }
            }
        }

        const term = SEP[input.next]
        if (term === undefined) return
        if (!stack.canShift(term)) return            // not mid-path → leave it to JS
        // tight on BOTH sides: whitespace before means the path already ended
        // (skip ate the gap), so a trailing "// comment" keeps its slashes|
        // whitespace after likewise lets the separator fall through to JS.
        const before = input.peek(-1), after = input.peek(1)
        if (before === SPACE || before === TAB) return
        if (after === SPACE || after === TAB || after === NL || after === EOF) return
        input.advance()
        input.acceptToken(term)
    })
}
