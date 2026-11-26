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
let s:caps = '\s*\u[A-Z 0-9/,&():.*%=-]\+$'
let s:mixed = '\s*\(Loglikelihood\|Information Criteria\|Chi-Square Test of Model Fit.*'
    \ . '\|RMSEA.*\|SRMR.*\|WRMR.*\|Weighted Root Mean Square Residual.*\)\s*$'
let s:fold_end = 'end="\C^\ze' . s:caps . '\|^\ze' . s:mixed . '"'
    \ . ' fold keepend contains=mplusComment,mplusHeader,mplusSection,mplusTitle'
execute 'syn region mplusFold matchgroup=mplusHeader'
    \ 'start="\C^' . s:caps . '\|^' . s:mixed . '"' s:fold_end

"" A header of the echoed input that stands in capitals, alone or before
"" other text in capitals ("  MODEL:", "  MODEL:  %WITHIN%"), is an all-caps
"" line as well. This region is defined later and therefore wins there. It
"" starts the same fold and shows the header as mplusSection, like the
"" echoed headers that have other text after them.
execute 'syn region mplusFold matchgroup=mplusSection'
    \ 'start="\C^\%(' . s:caps . '\)\@=\s*' . mplus#section#Pattern() . '"' s:fold_end

"" The title, which Mplus prints as it was written between the messages
"" about the input and the summary of the analysis. The messages end with the
"" line INPUT READING TERMINATED NORMALLY or, when there were warnings, with
"" the line that counts them. Every one of the 428 example outputs has one of
"" the two lines and the summary. The title is title text whatever it looks
"" like, so nothing is matched in it, and the region has "extend", so that a
"" title line in capitals does not end the fold around it and start another.
syn region mplusTitle extend
    \ start="^\%(\%(INPUT READING TERMINATED NORMALLY\|\s*\d\+ WARNING(S) FOUND IN THE INPUT INSTRUCTIONS\)\s*\n\)\@<="
    \ end="^\zeSUMMARY OF ANALYSIS\s*$"

"" Highlight links
highlight link mplusSection Include
highlight link mplusComment Comment
highlight link mplusHeader  Type
highlight link mplusTitle   String

let b:current_syntax = "mplus-out"
