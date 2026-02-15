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

let b:undo_indent = "setlocal indentexpr< indentkeys<"

if exists("*GetMplusInpIndent")
    finish
endif

function! GetMplusInpIndent()
    let line = getline(v:lnum)
    "" Single-word section headers go to column 0
    if line =~? '^\s*\(TITLE\|VARIABLE\|DEFINE\|ANALYSIS\|OUTPUT\|SAVEDATA\|PLOT\|MONTECARLO\)\s*:'
        return 0
    endif
    "" Compound section headers: DATA [X]: and MODEL [X]:
    if line =~? '^\s*\(DATA\|MODEL\)\(\s\+\S\+\)\?\s*:'
        return 0
    endif
    "" Everything else indented one level
    return shiftwidth()
endfunction
