if exists("b:current_syntax")
   finish
endif

"" Output files do not source mplus.vim — keywords like RANDOM, SEED,
"" CHAINS etc. appear as plain English in output text and should not
"" be highlighted. Only comments, headers, and section labels apply.

"" Comments
syn match mplusComment "!.*$"

"" Class/level labels (%OVERALL%, %c#1%, %BETWEEN subject%, etc.)
syn match mplusSection "%[^%]\+%"

"" Echoed input section headers (2-space indent or flexible)
syn match mplusSection
    \ "^\s*\(TITLE\|VARIABLE\|DEFINE\|ANALYSIS\|OUTPUT\|SAVEDATA\|PLOT\|MONTECARLO\):"
syn match mplusSection
    \ "^\s*\(DATA\|MODEL\)\(\s\+\S\+\)\?:"

"" Timestamp header (e.g., 01/15/2026  10:30 AM)
syn match mplusHeader "^\d\{2}\/\d\{2}\/\d\{4}\s\+\d\+:\d\+\s\+.M$"

"" All-caps section headers (includes &, parentheses, colon, dot, star, percent, equals)
syn match mplusHeader "\C^\u[A-Z 0-9/,&():.*%=-]\+$"

"" Fold output sections between all-caps headers
syn region mplusFold matchgroup=mplusHeader
    \ start="\C^\u[A-Z 0-9/,&():.*%=-]\+$"
    \ end="\C^\ze\u[A-Z 0-9/,&():.*%=-]\+$"
    \ fold keepend contains=mplusComment,mplusHeader,mplusSection

"" Highlight links
highlight link mplusSection Include
highlight link mplusComment Comment
highlight link mplusHeader  Type

let b:current_syntax = "mplus-out"
