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

"" Section headers of the echoed input, which follow the rule of
"" autoload/mplus/section.vim. A header is a command name in any case, in
"" full or shortened, alone or with one more word, and a colon.
execute 'syn match mplusSection "\c^\s*' . mplus#section#Pattern() . '"'

"" Timestamp header (e.g., 01/15/2026  10:30 AM)
syn match mplusHeader "^\d\{2}\/\d\{2}\/\d\{4}\s\+\d\+:\d\+\s\+.M$"

"" Mixed-case section headers
syn match mplusHeader "^\s*Loglikelihood\s*$"
syn match mplusHeader "^\s*Information Criteria\s*$"
syn match mplusHeader "^\s*Chi-Square Test of Model Fit.*$"
syn match mplusHeader "^\s*RMSEA.*$"
syn match mplusHeader "^\s*SRMR.*$"
syn match mplusHeader "^\s*WRMR.*$"
syn match mplusHeader "^\s*Weighted Root Mean Square Residual.*$"

"" All-caps section headers (includes &, parentheses, colon, dot, star, percent, equals)
"" Also includes specific mixed-case headers commonly found in Model Fit Information
syn region mplusFold matchgroup=mplusHeader
    \ start="\C^\s*\u[A-Z 0-9/,&():.*%=-]\+$\|^\s*\(Loglikelihood\|Information Criteria\|Chi-Square Test of Model Fit.*\|RMSEA.*\|SRMR.*\|WRMR.*\|Weighted Root Mean Square Residual.*\)\s*$"
    \ end="\C^\ze\s*\u[A-Z 0-9/,&():.*%=-]\+$\|^\ze\s*\(Loglikelihood\|Information Criteria\|Chi-Square Test of Model Fit.*\|RMSEA.*\|SRMR.*\|WRMR.*\|Weighted Root Mean Square Residual.*\)\s*$"
    \ fold keepend contains=mplusComment,mplusHeader,mplusSection

"" Highlight links
highlight link mplusSection Include
highlight link mplusComment Comment
highlight link mplusHeader  Type

let b:current_syntax = "mplus-out"
