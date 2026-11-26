if exists("b:did_indent")
    finish
endif
let b:did_indent = 1

setlocal indentexpr=GetMplusInpIndent()
setlocal indentkeys+==TITLE:,=TITL:,=DATA:,=VARIABLE:,=VARI:,=DEFINE:,=DEFI:
setlocal indentkeys+==ANALYSIS:,=ANAL:,=MODEL:,=MODE:,=OUTPUT:,=OUTP:
setlocal indentkeys+==SAVEDATA:,=SAVE:,=PLOT:,=MONTECARLO:,=MONT:
setlocal indentkeys+==CONSTRAINT:,=INDIRECT:,=POPULATION:,=MISSING:,=PRIORS:,=TEST:
setlocal indentkeys+==PRIOR:,=COVERAGE:
setlocal indentkeys+==IMPUTATION:,=TWOPART:,=WIDETOLONG:,=LONGTOWIDE:,=SURVIVAL:,=COHORT:
setlocal indentkeys+=0=DO,0=END

let b:undo_indent = "setlocal indentexpr< indentkeys<"

if exists("*GetMplusInpIndent")
    finish
endif

function! GetMplusInpIndent()
    let lnum = prevnonblank(v:lnum - 1)
    if lnum == 0
        return 0
    endif

    let line = getline(v:lnum)
    let prev_line = getline(lnum)
    let ind = indent(lnum)

    "" Section headers always go to column 0. mplus#section#Starts() holds
    "" the rule for a header.
    if mplus#section#Starts(v:lnum)
        return 0
    endif

    "" If previous line was a section header, indent one level
    if mplus#section#Starts(lnum)
        return shiftwidth()
    endif

    "" Handle DO loops
    "" If previous line starts with DO and doesn't contain END DO, indent.
    "" DO (1, 6) expression; is one statement, so a DO line that holds the
    "" semicolon of its statement has nothing below it that belongs to it.
    if prev_line =~? '^\s*DO\s*(' && prev_line !~? '\<END\s\+DO\>'
        \ && substitute(prev_line, '!.*', '', '') !~# ';'
        let ind = ind + shiftwidth()
    endif

    "" If current line starts with END DO, dedent
    if line =~? '^\s*END\s\+DO\>'
        let ind = ind - shiftwidth()
    endif

    return ind
endfunction
