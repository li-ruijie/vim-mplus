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

"" Headers in capitals (with &, parentheses, colon, dot, star, percent, and
"" equals sign). Result lines stand in capitals as well (" F1       BY",
"" the names above the columns of a matrix, the rows of the modification
"" indices, the lines of a message), so a line in capitals is a header in
"" two places only. The first is column 0, where the headers of the parts of
"" an output stand (MODEL RESULTS), unless the line holds a decimal number
"" or ends with a slash, as the rows of the modification indices do. The
"" second is an indented line that has an empty line above and below it
"" and holds no decimal number, which is how the headers inside a part
"" stand (PARAMETER SPECIFICATION under TECHNICAL 1 OUTPUT).
"" Specific mixed-case headers of the model fit information count as well.
let s:caps = '\s*\u[A-Z 0-9/,&():.*%=-]\+$'
"" Each pattern tests the cheap condition first, as it is tried on every line.
let s:main = '\u\%(.*\.\d\)\@!\%(.*/\s*$\)\@![A-Z 0-9/,&():.*%=-]\+$'
let s:sub = '\%(\s\+\u[A-Z 0-9/,&():.*%=-]\+\n\s*$\)\@=\%(^\s*\n\)\@<=\%(.*\.\d\)\@!'
    \ . '\s\+\u[A-Z 0-9/,&():.*%=-]\+$'
let s:mixed = '\s*\(Loglikelihood\|Information Criteria\|Chi-Square Test of Model Fit.*'
    \ . '\|RMSEA.*\|SRMR.*\|WRMR.*\|Weighted Root Mean Square Residual.*\)\s*$'
"" A header of the echoed input that stands in capitals, alone or before
"" other text in capitals ("  MODEL:", "  MODEL:  %WITHIN%").
let s:echoed = '\%(' . s:caps . '\)\@=\s*' . mplus#section#Pattern()
let s:fold_end = 'end="\C^\ze' . s:main . '\|^\ze' . s:sub . '\|^\ze' . s:mixed
    \ . '\|^\ze' . s:echoed . '"'
    \ . ' fold keepend contains=mplusComment,mplusHeader,mplusSection,mplusTitle'
execute 'syn region mplusFold matchgroup=mplusHeader'
    \ 'start="\C^' . s:main . '\|^' . s:sub . '\|^' . s:mixed . '"' s:fold_end

"" An echoed header in capitals starts a fold as well. This region is
"" defined later and therefore wins where such a header is also a line with
"" an empty line above and below it. It shows the header as mplusSection,
"" like the echoed headers that have other text after them.
execute 'syn region mplusFold matchgroup=mplusSection'
    \ 'start="\C^' . s:echoed . '"' s:fold_end

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
