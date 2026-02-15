if exists("b:current_syntax")
   finish
endif

runtime syntax/mplus.vim

"" Uppercase section headers in output
syn match mplusHeader "^\u[A-Z ]\+$"

"" Echoed input section headers (2-space indent)
syn match mplusSection
    \ "^  \(TITLE\|DATA\|VARIABLE\|MODEL\|ANALYSIS\|OUTPUT\):"
syn match mplusSection
    \ "^  \(DEFINE\|SAVEDATA\|PLOT\|MONTECARLO\):"
syn match mplusSection
    \ "^  \(CONSTRAINT\|INDIRECT\|POPULATION\|MISSING\|PRIORS\|TEST\):"

let b:current_syntax = "mplus-out"
