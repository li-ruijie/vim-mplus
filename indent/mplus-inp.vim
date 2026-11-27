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

let b:undo_indent = "setlocal indentexpr< indentkeys<"

if exists("*GetMplusInpIndent")
    finish
endif

function! GetMplusInpIndent()
    let lnum = prevnonblank(v:lnum - 1)
    if lnum == 0
        return 0
    endif

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

    "" DO (1, 6) expression; is one statement, which ends with the semicolon
    "" of its expression on whatever line that stands, and the loop takes no
    "" statement after it. Mplus has no END DO, and stops with an error at it.
    "" A line below a DO line that does not end the statement is one level
    "" deeper, the lines below it keep their indent, and the line after the
    "" statement has the indent of the line where the statement starts.
    let code = substitute(prev_line, '!.*', '', '')
    if prev_line =~? '^\s*DO\s*(' && code !~# ';'
        return ind + shiftwidth()
    endif
    if code =~# ';'
        let start = s:StatementStart(lnum)
        if getline(start) =~? '^\s*DO\s*('
            return indent(start)
        endif
    endif

    return ind
endfunction

"" Return the line where the statement that ends on line a:lnum starts. That
"" is the first line with code below the nearest line above that ends a
"" statement or starts a section. Empty lines and comments hold no code.
function! s:StatementStart(lnum)
    let start = a:lnum
    let lnum = a:lnum - 1
    while lnum >= 1 && !mplus#section#Starts(lnum)
        let code = substitute(getline(lnum), '!.*', '', '')
        if code =~# ';'
            break
        elseif code =~# '\S'
            let start = lnum
        endif
        let lnum -= 1
    endwhile
    return start
endfunction
