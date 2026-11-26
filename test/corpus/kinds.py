"""Classify the lines of an Mplus output by kind and give each line its fold level.

This is the oracle of the tests of syntax/mplus-out.vim. It reads an output as Mplus wrote it and
applies the rules below, which follow where and how Mplus prints each kind of line. Every rule for a
header or a warning reads only the line itself, the lines next to it, the line two below, and the
next line with text, so that a syntax file can state the same rule. It needs nothing but the Python
standard library.

Usage:
    python kinds.py show FILE [FIRST [LAST]]   print line number, fold level, kind, place, and text
    python kinds.py count DIR...               count the lines of each kind in the outputs under DIR
    python kinds.py table [--keep LIST] DIR... print the labelled list of the outputs under DIR,
                                               with the doubt marks of LIST
    python kinds.py check [--exact] LIST DIR...
                                               compare the outputs under DIR with a labelled list,
                                               with --exact also every key and count

Kinds of line, with the fold rank of the kinds that start a fold:
    banner    the lines above INPUT INSTRUCTIONS (version, MUTHEN & MUTHEN, date and time)
    echohead  INPUT INSTRUCTIONS, which starts the echoed input (rank 1)
    echosect  a section header of the echoed input, by the rule of autoload/mplus/section.vim (rank 2)
    echo      any other line of the echoed input
    title     a line of the printed title
    part      the header of a part of the output (rank 1)
    part2     the second line of a part header of two lines
    sub       a sub-header inside a part (rank 2)
    sub2      the second line of a sub-header of two lines at column 0
    table     the name of a matrix or table above a rule of underscores (rank 3)
    warning   a line of a message that Mplus marks as a warning, or that tells of a doubtful estimation
    error     a line of a message that Mplus marks as an error, or that tells of a failed estimation
    status    the line THE MODEL ESTIMATION TERMINATED NORMALLY that opens the status block
    footer    the lines from the MUTHEN & MUTHEN that follows an empty line to the end
The other lines are plain text. Three kinds of them are named, to say why a line that looks like a
header is none:
    message   a line of any other message (a sentence, a note, a footnote)
    label     the first line of a block of results, above lines indented deeper (" F1       BY")
    colhead   a line of words set out in columns with no decimal number: the heads of the columns of
              a table, and labels with a value in words ("Cluster variable      CLUS")
    plain     anything else, empty lines among them

A fold of rank r runs from its header to the line above the next header of rank r or lower, and
holds the folds of higher rank that start inside it. A table directly under a part is at level 2.
The echoed input ends at its first line with text at column 0, and the folds open in it end there.
A section of the echoed input that has only its header line starts no fold, and its header is echo.
A sub-header at column 0 holds the lines below it up to the next line with text at column 0 that has
an empty line above it and is no row of numbers. The footer ends every fold.

The status block tells how the estimation ended. It opens at the status line THE MODEL ESTIMATION
TERMINATED NORMALLY at column 0, at the error of an estimation that did not terminate normally
(THE MODEL ESTIMATION DID NOT TERMINATE NORMALLY, NO CONVERGENCE.), or at the verdict on the random
starts (THE BEST LOGLIKELIHOOD VALUE HAS BEEN REPLICATED, or the warning that it was not) when the
next paragraph is one of those two. A line inside a part whose header starts with TECHNICAL opens
none, since TECHNICAL 9 prints a status line for every replication and every bootstrap draw. The
block ends every fold and runs to the line above the next part header or the footer, outside any
fold, so that it shows when every fold is closed. No sub-header or table starts inside it.
"""
import re
import sys
from pathlib import Path

RANK = {"echohead": 1, "part": 1, "echosect": 2, "sub": 2, "table": 3}
FOLDS = ("echohead", "echosect", "part", "sub", "table")

# The section rule of autoload/mplus/section.vim: a command name in full or shortened to four or more
# letters, one more word at most, and a colon, in any case.
_NAMES = ["TITLE", "DATA", "VARIABLE", "DEFINE", "ANALYSIS", "MODEL", "OUTPUT", "SAVEDATA", "PLOT",
          "MONTECARLO"]
_NAME = "|".join(n[:4] + "".join(f"(?:{c}" for c in n[4:]) + ")?" * (len(n) - 4) for n in _NAMES)
SECTION = re.compile(rf"^\s*(?:{_NAME})(?:\s+[^:\s]+)?\s*:", re.IGNORECASE)
# A TITLE header with no second word, the only form of it that Mplus reads as a title.
TITLE_HEADER = re.compile(r"^\s*TITL(?:E)?\s*:", re.IGNORECASE)
# A line that opens a block comment that is still open at its end (mplus#section#Opens()).
OPENS = re.compile(r"!\*(?!.*\*!)")

RULE = re.compile(r"^\s*_{8}(?:\s+_{8})*\s*$")
DECIMAL = re.compile(r"\d\.\d|(?<![\w.])\.\d")
GAP = re.compile(r"\S {2,}\S")
LOWER = re.compile(r"[a-z]")
UPPER = re.compile(r"[A-Z]")
# The line above the empty line that opens the printed title: the end of the reading of the input,
# or the last of the lines that count the warnings and the errors in it.
TITLE_MARK = re.compile(r"^(?:INPUT READING TERMINATED NORMALLY|\s*\d+ (?:WARNING|ERROR)\(S\) FOUND IN THE "
                        r"INPUT INSTRUCTIONS)\s*$")

# The start of a message. Mplus starts none of its headers with an article, a note, or an asterisk,
# and the line that ends the reading of the input is no header either.
MESSAGE = re.compile(r"^\s*(?:THE |The |NOTE:|\*|INPUT READING TERMINATED NORMALLY\s*$)")

# Lines in capitals at column 0 that stand where and as a part header stands, but name a section
# inside a part: the fit section CFI/TLI, the labels of a class, a level, and a set of variables
# that older versions print in capitals, and the pair of variables of a table of CROSSTABS.
CAPS_LABEL = re.compile(r"^(?:CFI/TLI|CLASS \d+|WITHIN|BETWEEN|VARIABLE SET \d+"
                        r"|[A-Z][\w#$&.]* AND [A-Z][\w#$&.]*)\s*$")

# The first words of a message that Mplus marks as a problem, or that tells of a failed or doubtful
# estimation. Mplus words these messages as it words its other messages, so only the wording tells
# them apart. An error is a message that Mplus marks as one, or that tells that a step failed and
# gave no result. ERROR is matched as a word, so that the caption ERRORS DURING ESTIMATION WITH
# BOOTSTRAP DRAW NUMBER n (shown below, if any) is no error.
ERROR_OPENERS = [
    r"\*\*\* (?:ERROR|FATAL ERROR)",
    r"ERROR\b",
    r"\d+ ERROR\(S\) FOUND IN THE INPUT INSTRUCTIONS",
    r"Errors for replication with data file",
    r"NO CONVERGENCE",
    r"THE MODEL ESTIMATION DID NOT TERMINATE",
    r"Model estimation did not terminate normally",
    r"THE LOGLIKELIHOOD DECREASED",
    r"THE FOLLOWING DATA SET\(S\) DID NOT RESULT",
    r"DEMO VERSION MAXIMUM EXCEEDED",
]
WARNING_OPENERS = [
    r"\*\*\* WARNING",
    r"WARNING\b",
    r"\d+ WARNING\(S\) FOUND IN THE INPUT INSTRUCTIONS",
    r"PROBLEMS? (?:OCCURRED|INVOLVING)",
    r"COMPUTATIONAL PROBLEMS",
    r"THE MODEL ESTIMATION HAS REACHED",
    r"THE STANDARD ERRORS OF THE MODEL PARAMETER ESTIMATES",
    r"ONE OR MORE (?:[A-Z]+ )*PARAMETERS WERE FIXED",
    r"THE CONDITION NUMBER IS",
    r"THE NONIDENTIFICATION IS",
    r"THE (?:H1 )?MODEL ESTIMATION DID NOT CONVERGE",
    r"THIS ANALYSIS MAY HAVE MULTIPLE SOLUTIONS",
    r"THE EFFECTIVE SAMPLE SIZE",
    r"THE WARNING IS DUE TO",
    r"A MATRIX COULD NOT BE INVERTED",
]
ERROR = re.compile(r"^\s*(?:" + "|".join(ERROR_OPENERS) + ")")
WARNING = re.compile(r"^\s*(?:" + "|".join(WARNING_OPENERS) + ")")
# Mplus writes the messages about the input one below the other with no empty line between, each
# marked with ***, and the lines that count them below the last. Each starts a message of its own.
NEXT = re.compile(r"^\s*(?:\*\*\* |\d+ (?:ERROR|WARNING)\(S\) FOUND IN THE INPUT INSTRUCTIONS)")

# The lines that open the status block (see above).
STATUS = re.compile(r"^THE MODEL ESTIMATION TERMINATED NORMALLY\s*$")
FAILED = re.compile(r"^\s*(?:THE MODEL ESTIMATION DID NOT TERMINATE NORMALLY|NO CONVERGENCE\.)")
VERDICT = re.compile(r"^(?:THE BEST LOGLIKELIHOOD VALUE HAS BEEN REPLICATED|\s+WARNING:\s+THE BEST "
                     r"LOGLIKELIHOOD VALUE WAS NOT REPLICATED)")


class Line:
    __slots__ = ("text", "kind", "level", "indent", "up", "down", "pos", "rule2", "prev", "after", "depth")

    def __init__(self, text):
        self.text = text
        self.kind = "plain"
        self.level = 0
        self.indent = len(text) - len(text.lstrip())
        self.up = self.down = 0
        self.pos = self.prev = self.after = self.depth = ""
        self.rule2 = False

    @property
    def blank(self):
        return not self.text.strip()


def read(path):
    with open(path, "rb") as handle:
        data = handle.read().decode("latin-1")
    return data.replace("\r\n", "\n").replace("\r", "\n").split("\n")


def caps(text):
    return bool(UPPER.search(text)) and not LOWER.search(text)


def sentence_end(text):
    """A line that ends a sentence: a period after a word of two letters or more."""
    return bool(re.search(r"[A-Za-z]{2}\.\s*$", text))


def prose(text):
    """Words set apart by single spaces, two only after a colon, an asterisk, or a sentence."""
    text = text.strip()
    return all(re.search(r"(?:[A-Za-z]{2}\.|[:*])$", text[:m.start()])
               for m in re.finditer(r"(?<=\S) {2,}(?=\S)", text))


def is_row(text):
    """A row of numbers at column 0, as the modification indices print them."""
    return bool(DECIMAL.search(text)) or text.rstrip().endswith("/")


def _place(lines):
    """Record for each line with text the empty lines around it, the line above, the depth of the
    next line with text, and a rule of underscores two lines below. The next line is deep ("d") when
    it stands at most one column less deep than the line, and shallow ("s") when it stands less deep
    than that."""
    n = len(lines)
    nxt = None
    for i in range(n - 1, -1, -1):
        line = lines[i]
        if line.blank:
            continue
        if nxt is not None:
            line.down = nxt - i - 1
            line.depth = "d" if lines[nxt].indent >= line.indent - 1 else "s"
            if not line.down:
                line.after = "i" if lines[nxt].indent else "c"
        else:
            line.down = n - i - 1
        nxt = i
    last = None
    for i, line in enumerate(lines):
        if line.blank:
            continue
        line.up = i if last is None else i - last - 1
        if line.up == 0 and last is not None:
            above = lines[last]
            line.prev = "i" if above.indent else ("s" if sentence_end(above.text) else "c")
        line.rule2 = i + 2 < n and not lines[i + 1].blank and bool(RULE.match(lines[i + 2].text))
        last = i


def classify(texts):
    lines = [Line(t) for t in texts]
    n = len(lines)
    _place(lines)

    # The banner, the echoed input, and the footer.
    head = next((i for i, l in enumerate(lines) if l.text.rstrip() == "INPUT INSTRUCTIONS"), None)
    for i in range(head if head is not None else 0):
        if not lines[i].blank:
            lines[i].kind = "banner"
    echo_end = 0
    single = set()
    if head is not None:
        lines[head].kind = "echohead"
        echo_end = next((i for i in range(head + 1, n) if not lines[i].blank and not lines[i].indent), n)
        # A block comment opens at a !* anywhere on a line and closes at the next *!, except that
        # below a TITLE line that opens none, a !* is title text up to the next section header.
        comment = title = False
        for i in range(head + 1, echo_end):
            line = lines[i]
            if line.blank:
                continue
            shape = SECTION.match(line.text)
            line.kind = "echosect" if shape and not comment else "echo"
            if line.kind == "echosect":
                title = bool(TITLE_HEADER.match(line.text)) and not OPENS.search(line.text)
            if OPENS.search(line.text):
                if line.kind == "echosect" or not title or shape:
                    comment = True
            elif "*!" in line.text:
                comment = False
        # A section of a single line starts no fold, since a fold of syntax spans two lines or more.
        # Its header is then a line of the section above it, which ends there.
        for i in range(head + 1, echo_end):
            if lines[i].kind == "echosect" and (i + 1 == echo_end or lines[i + 1].kind == "echosect"):
                lines[i].kind = "echo"
                single.add(i)
    # The footer starts at the last MUTHEN & MUTHEN with an empty line above, or at the line Mplus
    # VERSION that Mplus on Linux writes above it, with only empty lines between.
    foot = n
    for i in range(n - 1, echo_end - 1, -1):
        if lines[i].text.rstrip() == "MUTHEN & MUTHEN" and i > 0 and lines[i - 1].blank:
            foot = i
            j = i - 1
            while j > echo_end and lines[j].blank:
                j -= 1
            if lines[j].text.startswith("Mplus VERSION"):
                foot = j
            break
    for i in range(foot, n):
        if not lines[i].blank:
            lines[i].kind = "footer"

    # The printed title, as mplusTitle in syntax/mplus-out.vim reads it.
    title = set()
    mark = next((i for i in range(echo_end, foot - 1)
                 if TITLE_MARK.match(lines[i].text) and lines[i + 1].blank), None)
    if mark is not None:
        i = mark + 1
        while i < foot:
            text = lines[i].text
            if text.rstrip() == "SUMMARY OF ANALYSIS" or re.match(r"^\s+\S", text):
                break
            if text.rstrip() == "*** FATAL ERROR":
                j = i + 1
                while j < foot and lines[j].blank:
                    j += 1
                if j < foot and lines[j].indent:
                    break
            if not lines[i].blank:
                lines[i].kind = "title"
            title.add(i)
            i += 1

    body = [i for i in range(echo_end, foot) if i not in title]
    inside = set(body)
    for i in body:
        _header(lines, i)
    block = _status(lines, body, foot)
    for lo, hi in _paragraphs(lines, body, inside):
        _problem(lines, lo, hi)
        _plain(lines, lo, hi)
    _levels(lines, echo_end if head is not None else None, foot, block, single)
    return lines


def _status(lines, body, foot):
    """Mark the status line, take the headers out of the status block, and return its lines."""
    block = set()
    part = ""
    opened = False
    for i in body:
        line = lines[i]
        if line.kind == "part":
            part, opened = line.text, False
        if opened or part.startswith("TECHNICAL") or line.blank:
            if opened:
                block.add(i)
            continue
        opens = STATUS.match(line.text) or FAILED.match(line.text)
        if not opens and VERDICT.match(line.text) and (i == 0 or lines[i - 1].blank):
            j = i
            while j < foot and not lines[j].blank:
                j += 1
            while j < foot and lines[j].blank:
                j += 1
            opens = j < foot and (STATUS.match(lines[j].text) or FAILED.match(lines[j].text))
        if opens:
            opened = True
            block.add(i)
    for i in block:
        line = lines[i]
        if line.kind in ("sub", "sub2", "table"):
            line.kind = "plain"
        elif STATUS.match(line.text):
            line.kind = "status"
    return block


def _paragraphs(lines, body, inside):
    i = 0
    while i < len(body):
        k = body[i]
        if lines[k].blank:
            i += 1
            continue
        j = k
        while j + 1 in inside and not lines[j + 1].blank:
            j += 1
        yield k, j + 1
        i += j + 1 - k


def _heading_text(text):
    """No decimal number, no period at the end, and no start of a message."""
    return not DECIMAL.search(text) and not text.rstrip().endswith(".") and not MESSAGE.match(text)


def _part_line(text):
    return caps(text) and not CAPS_LABEL.match(text) and _heading_text(text)


def _col0_sub_line(text):
    return LOWER.search(text) and not GAP.search(text.strip()) and _heading_text(text)


def _starts_header(text):
    """Mplus starts every header with a capital letter, never with a digit, a symbol, or a comment."""
    return bool(UPPER.match(text.strip()))


def _header(lines, i):
    """The rules for headers, in the order in which they are tried."""
    line = lines[i]
    if line.blank or line.kind != "plain":
        return
    text = line.text
    below = lines[i + 1] if i + 1 < len(lines) else None
    after = lines[i + 2] if i + 2 < len(lines) else None
    alone_below = below is None or below.blank

    # A continuation: the next line is at column 0, its text passes the test, and an empty line or
    # the end of the output follows it. A sub-header at column 0 may also go on in an indented line
    # that starts with a parenthesis, as "     (Ordinal) Outcomes" goes on a header of the fit.
    def cont(test, indented=False):
        return below is not None and not below.blank and test(below.text) \
            and (not below.indent or indented and below.text.lstrip().startswith("(")) \
            and (after is None or after.blank)

    if line.rule2 and line.indent:
        line.kind = "table"
    elif not _starts_header(text):
        return
    elif not line.indent and line.up and _part_line(text) and (alone_below or cont(_part_line)):
        line.kind = "part"
        if not alone_below:
            below.kind = "part2"
    elif not line.indent and line.up and CAPS_LABEL.match(text) and alone_below:
        line.kind = "sub"
    elif not line.indent and (line.up or line.prev in ("i", "s")) and _col0_sub_line(text) \
            and (alone_below or cont(_col0_sub_line, indented=True)):
        line.kind = "sub"
        if not alone_below:
            below.kind = "sub2"
    elif line.indent and line.up and alone_below and line.depth == "d" and _heading_text(text) \
            and not GAP.search(text.strip()):
        line.kind = "sub"


def _problem(lines, lo, hi):
    """A warning or an error runs from its first line to the end of its paragraph, or to the line
    above the next message of the other kind that Mplus marks with *** or counts."""
    kind = ""
    for k in range(lo, hi):
        text = lines[k].text
        if not kind or NEXT.match(text):
            kind = "error" if ERROR.match(text) else "warning" if WARNING.match(text) else kind
        if kind:
            lines[k].kind = kind


def _plain(lines, lo, hi):
    """Name the plain lines that look like headers: messages, result labels, and column heads."""
    size = hi - lo
    for k in range(lo, hi):
        lines[k].pos = "1" if size == 1 else ("2a" if k == lo else "2b") if size == 2 else \
            ("f" if k == lo else "l" if k == hi - 1 else "m")
    # A message: prose from the start of the paragraph to the end of a sentence, or to the end of a
    # paragraph that starts as a message does.
    end = None
    for k in range(lo, hi):
        if not prose(lines[k].text):
            break
        if sentence_end(lines[k].text) or (k == hi - 1 and MESSAGE.match(lines[lo].text)):
            end = k
    if end is not None:
        for k in range(lo, end + 1):
            if lines[k].kind == "plain":
                lines[k].kind = "message"
    first = lines[lo]
    if first.kind == "plain" and first.indent <= 1 and size > 1 and lines[lo + 1].indent > first.indent \
            and not is_row(first.text):
        first.kind = "label"
    for k in range(lo, hi):
        line = lines[k]
        fields = re.split(r" {2,}", line.text.strip())
        if line.kind == "plain" and line.indent >= 2 and len(fields) > 1 and not DECIMAL.search(line.text) \
                and all(re.search(r"[A-Za-z]", f) for f in fields):
            line.kind = "colhead"


def _levels(lines, echo_end, foot, block, single):
    stack = []   # the open folds, as [rank, whether it is a sub-header at column 0]
    for i, line in enumerate(lines):
        if i == echo_end or i == foot or i in block:
            stack = []
            if i in block:
                continue
        if i in single:
            del stack[1:]
        rank = RANK.get(line.kind)
        if rank is None and not line.blank and not line.indent and line.up \
                and line.kind not in ("sub2", "part2") and not is_row(line.text):
            for k, entry in enumerate(stack):
                if entry[1]:
                    del stack[k:]
                    break
        if rank is not None:
            while stack and stack[-1][0] >= rank:
                stack.pop()
            stack.append([rank, line.kind == "sub" and not line.indent])
        line.level = len(stack)


# The labelled list ------------------------------------------------------------------------------------

KINDS = ("banner", "echohead", "echosect", "echo", "title", "part", "part2", "sub", "sub2", "table",
         "warning", "error", "status", "message", "label", "colhead", "footer", "plain")


def norm(text):
    """The text of a line, with every number as # and every run of two spaces or more as two spaces."""
    text = re.sub(r"\d+", "#", text.replace("\t", " ").strip())
    return re.sub(r" {2,}", "  ", text)


def context(line):
    """The place of a line as the rules read it, as fields set apart by slashes: the indent (12 for
    12 or more), the empty lines above (0, 1, or 2+, and for 0 the line above: i indented, s a
    sentence at column 0, c other text at column 0), the empty lines below (0 or 1+, and for 0 the
    line below: i indented, c at column 0), the place in the paragraph (1 alone, 2a and 2b the lines
    of a paragraph of two, f m l the first, a middle, and the last line of a longer one), the depth
    of the next line with text (d at most one column less deep, s shallower), and R for a rule of
    underscores two lines below."""
    up = f"{min(line.up, 2)}{'+' if line.up >= 2 else ''}{line.prev}"
    down = "1+" if line.down else f"0{line.after}"
    rule = "/R" if line.rule2 else ""
    return f"{min(line.indent, 12)}/{up}/{down}/{line.pos or '-'}/{line.depth or '-'}{rule}"


HEADERS = ("echohead", "echosect", "part", "part2", "sub", "sub2", "table")


def candidate(line):
    """Whether a line goes into the labelled list: every header, warning, error, status, banner, and
    footer line, every other line that has the place of a header (at column 0, alone between empty
    lines, or two lines above a rule of underscores), and a title line in capitals at column 0."""
    if line.blank or line.kind == "echo":
        return False
    if line.kind == "title":
        return not line.indent and caps(line.text)
    if line.kind in HEADERS or line.kind in ("warning", "error", "status", "banner", "footer"):
        return True
    return not line.indent or bool(line.up and line.down) or line.rule2


def key(line):
    if line.kind in ("echohead", "echosect"):
        return re.sub(r"\s*:.*", ":", norm(line.text)).upper(), "echo"
    if line.kind in ("banner", "footer", "title"):
        return norm(line.text), line.kind
    return norm(line.text), context(line)


def outputs(roots):
    for root in roots:
        root = Path(root)
        for path in sorted(root.rglob("*.out")) if root.is_dir() else [root]:
            yield path


def collect(roots):
    """Count the candidate lines under roots by key and kind."""
    table = {}
    for path in outputs(roots):
        for line in classify(read(path)):
            if candidate(line):
                counts = table.setdefault(key(line), {})
                counts[line.kind] = counts.get(line.kind, 0) + 1
    return table


TEXT_COLUMN = 38
WIDTH = 108
RECORD = re.compile(r"^(\w+) +(\?)? *(\d+)  (\S+) +(.*)$")


LIST_HEADER = """\
# The kinds of the candidate lines of the 428 example outputs of Mplus 9.1.1 (the examples folder of
# the installation, written by Mplus 6.1, 8, and 8.8). Written by "python kinds.py table" and read by
# "python kinds.py check", which compares an output set with it. See kinds.py for the kinds and rules.
#
# Each record is: kind, a question mark where the label is not certain, the number of such lines in
# the examples, the place of the line, and its text. In the text every number is #, and every run of
# two spaces or more is two spaces. A text too long for the line goes on below, after a +, joined
# with one space. The place is the fields that the rules read, set apart by slashes:
#
#   indent        0 to 11, and 12 for 12 or more
#   above         empty lines above: 0, 1, or 2+, and for 0 the line above: i indented, s a
#                 sentence at column 0, c other text at column 0
#   below         empty lines below: 1+, or 0 and the line below: i indented, c at column 0
#   paragraph     1 alone, 2a and 2b the lines of a paragraph of two, f m l first, middle, last
#   depth         the next line with text: d at most one column less deep, s shallower
#   R             a rule of underscores two lines below
#
# Lines of the echoed input are listed by their header (place "echo"), and lines of the banner, the
# footer, and the printed title by their text.
#
"""


def write_list(table, marks, out):
    """Write the labelled list: one record per key, the text wrapped at single spaces onto lines
    that start with "+" in the text column. A key that two kinds share is written once per kind."""
    out.write(LIST_HEADER)
    rank = {kind: i for i, kind in enumerate(KINDS)}
    rows = [(kind, where, text, count) for (text, where), counts in table.items()
            for kind, count in counts.items()]
    rows.sort(key=lambda r: (rank[r[0]], r[1], r[2]))
    for kind, where, text, count in rows:
        mark = "?" if (kind, where, text) in marks else " "
        head = f"{kind:9s}{mark} {count:6d}  {where:18s}"
        head = head.ljust(TEXT_COLUMN - 1) + " "
        room = WIDTH - TEXT_COLUMN
        pieces = []
        while len(text) > room:
            cut = max((m.start() for m in re.finditer(r"(?<=\S) (?=\S)", text[:room + 1])), default=-1)
            if cut <= 0:
                break
            pieces.append(text[:cut])
            text = text[cut + 1:]
            room = WIDTH - TEXT_COLUMN - 2
        pieces.append(text)
        out.write(head + pieces[0] + "\n")
        for piece in pieces[1:]:
            out.write(" " * TEXT_COLUMN + "+ " + piece + "\n")


def read_list(path):
    """Read a labelled list into {(text, place): (kind, count, doubtful)}."""
    entries = {}
    last = None
    for raw in Path(path).read_text(encoding="utf-8").splitlines():
        if not raw.strip() or raw.startswith("#"):
            continue
        if raw.startswith(" " * TEXT_COLUMN + "+ ") and last is not None:
            kind, where, text, count, mark = last
            last = (kind, where, text + " " + raw[TEXT_COLUMN + 2:], count, mark)
            continue
        if last is not None:
            entries.setdefault((last[2], last[1]), []).append((last[0], last[3], last[4]))
        match = RECORD.match(raw)
        if not match:
            raise ValueError(f"{path}: not a record: {raw}")
        kind, mark, count, where, text = match.groups()
        last = (kind, where, text, int(count), mark == "?")
    if last is not None:
        entries.setdefault((last[2], last[1]), []).append((last[0], last[3], last[4]))
    return entries


def check(path, roots, exact):
    """Compare the kinds of the candidate lines under roots with the labelled list. Return the
    number of disagreements: lines whose key the list gives another kind, and with exact also keys
    that the list lacks or counts differently."""
    entries = read_list(path)
    seen = collect(roots)
    wrong = missing = counted = 0
    for k, counts in sorted(seen.items()):
        listed = {kind: count for kind, count, _ in entries.get(k, [])}
        for kind, count in sorted(counts.items()):
            if k in entries and kind not in listed:
                wrong += count
                print(f"wrong    {count:6d}  {kind} where the list has {'/'.join(listed)}  {k[1]}  {k[0]}")
            elif k not in entries:
                missing += count
                if exact:
                    print(f"missing  {count:6d}  {kind}  {k[1]}  {k[0]}")
            elif listed[kind] != count:
                counted += 1
                if exact:
                    print(f"count    {count:6d}  {kind} where the list has {listed[kind]}  {k[1]}  {k[0]}")
    if exact:
        for k, rows in sorted(entries.items()):
            for kind, count, _ in rows:
                if kind not in seen.get(k, {}):
                    counted += 1
                    print(f"unseen   {count:6d}  {kind}  {k[1]}  {k[0]}")
    print(f"{wrong} lines of another kind, {missing} lines of keys not listed, {counted} counts differ")
    return wrong + (missing + counted if exact else 0)


def main(argv):
    if len(argv) >= 2 and argv[0] == "show":
        lines = classify(read(argv[1]))
        lo = int(argv[2]) if len(argv) > 2 else 1
        hi = int(argv[3]) if len(argv) > 3 else len(lines)
        for i in range(lo - 1, min(hi, len(lines))):
            line = lines[i]
            where = context(line) if not line.blank else ""
            print(f"{i + 1:6d} {line.level} {line.kind:8s} {where:20s}|{line.text[:90]}")
        return 0
    if len(argv) >= 2 and argv[0] == "count":
        counts = {}
        for path in outputs(argv[1:]):
            for line in classify(read(path)):
                counts[line.kind] = counts.get(line.kind, 0) + 1
        for kind in KINDS:
            print(f"{kind:10s} {counts.get(kind, 0):8d}")
        return 0
    if len(argv) >= 2 and argv[0] == "table":
        roots, marks = argv[1:], set()
        if len(roots) > 2 and roots[0] == "--keep":
            for k, rows in read_list(roots[1]).items():
                marks.update((kind, k[1], k[0]) for kind, _, doubtful in rows if doubtful)
            roots = roots[2:]
        sys.stdout.reconfigure(encoding="utf-8", newline="\n")
        write_list(collect(roots), marks, sys.stdout)
        return 0
    if len(argv) >= 3 and argv[0] == "check":
        exact = argv[1] == "--exact"
        rest = argv[2:] if exact else argv[1:]
        return 1 if check(rest[0], rest[1:], exact) else 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
