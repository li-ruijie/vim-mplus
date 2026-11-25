if exists("b:current_syntax")
   finish
endif

runtime syntax/mplus.vim

"" A section runs from one command header to the next. The pattern of a
"" header comes from autoload/mplus/section.vim, which states the rule. Inside
"" a TITLE only a command name directly followed by a colon is a header, so
"" a title line such as "model comparison: two groups" stays in the title.
let s:header = mplus#section#Pattern(0)
let s:header_in_title = mplus#section#Pattern(1)

"" TITLE section: no keyword highlighting in body (free-form text)
execute 'syn region mplusFold'
    \ 'start="^\s*TITL\%[E]\s*:"'
    \ 'end="^\ze\s*' . s:header_in_title . '"'
    \ 'fold keepend contains=mplusComment,mplusTitle'

"" All other sections: matchgroup overrides keyword priority for headers
"" contains=ALLBUT,mplusFold prevents self-nesting (flat folds)
execute 'syn region mplusFold matchgroup=mplusSection'
    \ 'start="^\s*\%(TITL\)\@!' . s:header . '"'
    \ 'end="^\ze\s*' . s:header . '"'
    \ 'fold keepend contains=ALLBUT,mplusFold'

let b:current_syntax = "mplus-inp"
