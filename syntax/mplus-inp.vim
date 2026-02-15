if exists("b:current_syntax")
   finish
endif

runtime syntax/mplus.vim

"" TITLE section: no keyword highlighting in body (free-form text)
syn region mplusFold matchgroup=mplusSection
    \ start="^\s*TITLE\s*:"
    \ end="^\s*\ze\(TITLE\|DATA\(\s\+\S\+\)\?\|VARIABLE\|DEFINE\|ANALYSIS\|MODEL\(\s\+\S\+\)\?\|OUTPUT\|SAVEDATA\|PLOT\|MONTECARLO\):"
    \ fold keepend contains=mplusComment

"" All other sections: matchgroup overrides keyword priority for headers
"" contains=ALLBUT,mplusFold prevents self-nesting (flat folds)
syn region mplusFold matchgroup=mplusSection
    \ start="^\s*\(DATA\(\s\+\S\+\)\?\|VARIABLE\|DEFINE\|ANALYSIS\|MODEL\(\s\+\S\+\)\?\|OUTPUT\|SAVEDATA\|PLOT\|MONTECARLO\):"
    \ end="^\s*\ze\(TITLE\|DATA\(\s\+\S\+\)\?\|VARIABLE\|DEFINE\|ANALYSIS\|MODEL\(\s\+\S\+\)\?\|OUTPUT\|SAVEDATA\|PLOT\|MONTECARLO\):"
    \ fold keepend contains=ALLBUT,mplusFold

let b:current_syntax = "mplus-inp"
