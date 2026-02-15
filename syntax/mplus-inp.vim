if exists("b:current_syntax")
   finish
endif

runtime syntax/mplus.vim

"" Section headers at column 1 (input files)
syn match mplusSection
    \ "^\(TITLE\|DATA\|VARIABLE\|MODEL\|ANALYSIS\|OUTPUT\):"
syn match mplusSection
    \ "^\(DEFINE\|SAVEDATA\|PLOT\|MONTECARLO\):"
syn match mplusSection
    \ "^\(CONSTRAINT\|INDIRECT\|POPULATION\|MISSING\|PRIORS\|TEST\):"

"" Fold sections
syn region mplusFold
    \ start="^\(TITLE\|DATA\|VARIABLE\|DEFINE\|ANALYSIS\|MODEL\(\s\+\S\+\)\?\|OUTPUT\|SAVEDATA\|PLOT\|MONTECARLO\):"
    \ end="\ze^\(TITLE\|DATA\|VARIABLE\|DEFINE\|ANALYSIS\|MODEL\(\s\+\S\+\)\?\|OUTPUT\|SAVEDATA\|PLOT\|MONTECARLO\):"
    \ fold transparent keepend

let b:current_syntax = "mplus-inp"
