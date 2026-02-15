if exists("b:current_syntax")
   finish
endif

runtime syntax/mplus.vim

"" Uppercase section headers in output
syn match mplusHeader "\C^\u[A-Z 0-9/,-]\+$"

"" Echoed input section headers (2-space indent)
syn match mplusSection
    \ "^  \(TITLE\|VARIABLE\|DEFINE\|ANALYSIS\|OUTPUT\|SAVEDATA\|PLOT\|MONTECARLO\):"
syn match mplusSection
    \ "^  \(DATA\|MODEL\)\(\s\+\S\+\)\?:"

"" Fold output sections
syn region mplusFold
    \ start="\C^\u[A-Z 0-9/,-]\+$"
    \ end="\ze\C^\u[A-Z 0-9/,-]\+$"
    \ fold transparent keepend

let b:current_syntax = "mplus-out"
