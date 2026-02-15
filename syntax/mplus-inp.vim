if exists("b:current_syntax")
   finish
endif

runtime syntax/mplus.vim

"" TITLE section: no keyword highlighting in body (free-form text)
syn region mplusFold matchgroup=mplusSection
    \ start="^\s*TITL\w*\s*:"
    \ end="^\s*\ze\(TITL\w*\|DATA\w*\(\s\+\S\+\)\?\|VARI\w*\|DEFI\w*\|ANAL\w*\|MODE\w*\(\s\+\S\+\)\?\|OUTP\w*\|SAVE\w*\|PLOT\w*\|MONT\w*\):"
    \ fold keepend contains=mplusComment

"" All other sections: matchgroup overrides keyword priority for headers
"" contains=ALLBUT,mplusFold prevents self-nesting (flat folds)
syn region mplusFold matchgroup=mplusSection
    \ start="^\s*\(DATA\w*\(\s\+[^: \t]\+\)\?\|VARI\w*\|DEFI\w*\|ANAL\w*\|MODE\w*\(\s\+[^: \t]\+\)\?\|OUTP\w*\|SAVE\w*\|PLOT\w*\|MONT\w*\):"
    \ end="^\s*\ze\(TITL\w*\|DATA\w*\(\s\+[^: \t]\+\)\?\|VARI\w*\|DEFI\w*\|ANAL\w*\|MODE\w*\(\s\+[^: \t]\+\)\?\|OUTP\w*\|SAVE\w*\|PLOT\w*\|MONT\w*\):"
    \ fold keepend contains=ALLBUT,mplusFold

let b:current_syntax = "mplus-inp"
