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
import { ExternalTokenizer, type Stack, type InputStream } from "@lezer/lr"

const SLASH = 47, COMMA = 44, COLON = 58
const SPACE = 32, TAB = 9, NL = 10, EOF = -1

// Built against a terms record so it serves both the live buildParser (terms
// supplied via the externalTokenizer option) and a generated parser (terms
// imported from the generated *.terms artifact and passed in by its wiring).
export function makePathSep(terms: {
    PathSep: number, PathComma: number, PathColon: number,
}): ExternalTokenizer {
    return new ExternalTokenizer((input: InputStream, stack: Stack) => {
        let term: number
        switch (input.next) {
            case SLASH: term = terms.PathSep;   break
            case COMMA: term = terms.PathComma; break
            case COLON: term = terms.PathColon; break
            default: return
        }
        if (!stack.canShift(term)) return            // not mid-path → leave it to JS
        const after = input.peek(1)
        if (after === SPACE || after === TAB || after === NL || after === EOF) return
        input.advance()
        input.acceptToken(term)
    })
}
