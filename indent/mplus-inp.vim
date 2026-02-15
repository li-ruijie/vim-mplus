if exists("b:did_indent")
    finish
endif
let b:did_indent = 1

setlocal indentexpr=GetMplusInpIndent()
setlocal indentkeys+==TITLE:,=DATA:,=VARIABLE:,=DEFINE:,=ANALYSIS:,=MODEL:
setlocal indentkeys+==OUTPUT:,=SAVEDATA:,=PLOT:,=MONTECARLO:
setlocal indentkeys+==CONSTRAINT:,=INDIRECT:,=POPULATION:,=MISSING:,=PRIORS:,=TEST:

let b:undo_indent = "setlocal indentexpr< indentkeys<"

if exists("*GetMplusInpIndent")
    finish
endif

function! GetMplusInpIndent()
    let line = getline(v:lnum)
    "" Section headers go to column 0
    if line =~? '^\s*\(TITLE\|DATA\|VARIABLE\|DEFINE\|ANALYSIS\|MODEL\|OUTPUT\|SAVEDATA\|PLOT\|MONTECARLO\|CONSTRAINT\|INDIRECT\|POPULATION\|MISSING\|PRIORS\|TEST\)\>'
        return 0
    endif
    "" Everything else indented one level
    return shiftwidth()
endfunction
