if exists("b:current_syntax")
   finish
endif

runtime syntax/mplus.vim

"" Section headers (input files)
syn match mplusSection
    \ "^\(TITLE\|VARIABLE\|DEFINE\|ANALYSIS\|OUTPUT\|SAVEDATA\|PLOT\|MONTECARLO\):"
syn match mplusSection
    \ "^\(DATA\|MODEL\)\(\s\+\S\+\)\?:"

"" Fold sections
syn region mplusFold
    \ start="^\(TITLE\|DATA\(\s\+\S\+\)\?\|VARIABLE\|DEFINE\|ANALYSIS\|MODEL\(\s\+\S\+\)\?\|OUTPUT\|SAVEDATA\|PLOT\|MONTECARLO\):"
    \ end="\ze^\(TITLE\|DATA\(\s\+\S\+\)\?\|VARIABLE\|DEFINE\|ANALYSIS\|MODEL\(\s\+\S\+\)\?\|OUTPUT\|SAVEDATA\|PLOT\|MONTECARLO\):"
    \ fold transparent keepend

let b:current_syntax = "mplus-inp"
