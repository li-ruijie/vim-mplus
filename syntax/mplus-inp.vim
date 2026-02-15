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

let b:current_syntax = "mplus-inp"
