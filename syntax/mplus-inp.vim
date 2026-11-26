if exists("b:current_syntax")
   finish
endif

runtime syntax/mplus.vim

"" A section runs from one command header to the next. The pattern of a
"" header comes from autoload/mplus/section.vim, which states the rule. It
"" is the same inside a TITLE, so a title line such as "Model comparison:
"" two groups" ends the title, as it does for Mplus.
let s:header = mplus#section#Pattern()

"" TITLE section: no keyword highlighting in body (free-form text)
execute 'syn region mplusFold'
    \ 'start="^\s*TITL\%[E]\s*:"'
    \ 'end="^\ze\s*' . s:header . '"'
    \ 'fold keepend contains=mplusComment,mplusTitle'

"" All other sections: matchgroup overrides keyword priority for headers
"" contains=ALLBUT,mplusFold prevents self-nesting (flat folds)
execute 'syn region mplusFold matchgroup=mplusSection'
    \ 'start="^\s*\%(TITL\%[E]\s*:\)\@!' . s:header . '"'
    \ 'end="^\ze\s*' . s:header . '"'
    \ 'fold keepend contains=ALLBUT,mplusFold'

"" Sections, block comments, and the printed title are regions of many
"" lines, and a line reads differently inside one of them. Folding by syntax
"" parses the whole buffer in any case, so every line is read with the state
"" that the lines above it leave, wherever the window starts.
syn sync fromstart

let b:current_syntax = "mplus-inp"
