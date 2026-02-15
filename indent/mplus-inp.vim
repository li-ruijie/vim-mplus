if exists("b:did_indent")
    finish
endif
let b:did_indent = 1

setlocal indentexpr=GetMplusInpIndent()
setlocal indentkeys+==TITLE:,=DATA:,=VARIABLE:,=DEFINE:,=ANALYSIS:,=MODEL:
setlocal indentkeys+==OUTPUT:,=SAVEDATA:,=PLOT:,=MONTECARLO:
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

    "" Section headers always go to column 0
    if line =~? '^\s*\(TITLE\|VARIABLE\|DEFINE\|ANALYSIS\|OUTPUT\|SAVEDATA\|PLOT\|MONTECARLO\)\s*:'
        return 0
    endif
    if line =~? '^\s*\(DATA\|MODEL\)\(\s\+\S\+\)\?\s*:'
        return 0
    endif

    "" If previous line was a section header, indent one level
    if prev_line =~? '^\s*\(TITLE\|VARIABLE\|DEFINE\|ANALYSIS\|OUTPUT\|SAVEDATA\|PLOT\|MONTECARLO\)\s*:'
        return shiftwidth()
    endif
    if prev_line =~? '^\s*\(DATA\|MODEL\)\(\s\+\S\+\)\?\s*:'
        return shiftwidth()
    endif

    "" Handle DO loops
    "" If previous line starts with DO and doesn't contain END DO, indent
    if prev_line =~? '^\s*DO\s*(' && prev_line !~? '\<END\s\+DO\>'
        let ind = ind + shiftwidth()
    endif

    "" If current line starts with END DO, dedent
    if line =~? '^\s*END\s\+DO\>'
        let ind = ind - shiftwidth()
    endif

    return ind
endfunction
