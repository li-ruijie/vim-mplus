" Where a section of an Mplus input starts. The syntax file, the indent
" file, and the formatter all take the rule from this file.
"
" A section starts on a line that begins with a command name and a colon.
" The names are TITLE, DATA, VARIABLE, DEFINE, ANALYSIS, MODEL, OUTPUT,
" SAVEDATA, PLOT, and MONTECARLO, in any case, in full or shortened to four
" or more letters. DATA and MODEL may carry a second word before the colon
" (DATA IMPUTATION:, MODEL INDIRECT:, MODEL male:).
"
" Inside a TITLE the second word is not accepted, so that only a command
" name directly followed by a colon ends the title. The user's guide says
" that a title "can contain any letters and symbols except the words used as
" Mplus commands when they are followed by a colon", which makes the line
" "model comparison: two groups" title text. The guide does not say how
" Mplus reads "MODEL word:" inside a title. Taking it as text is the choice
" that leaves the title alone, and a DATA or MODEL command with a second
" word that directly follows a title is then taken as title text as well.
"
" ftdetect/mplus-inp.vim repeats the first paragraph for the first line of
" a file, since it has to work before the plugin is on the runtimepath.

let s:names = 'TITL\%[E]\|DATA\|VARI\%[ABLE]\|DEFI\%[NE]\|ANAL\%[YSIS]\|MODE\%[L]'
    \ . '\|OUTP\%[UT]\|SAVE\%[DATA]\|PLOT\|MONT\%[ECARLO]'
let s:second = '\%(DATA\|MODE\%[L]\)\s\+[^: \t]\+'

" Return the pattern of a section header, to be matched without regard to
" case after the indent of a line. With a:in_title set it is the narrower
" pattern for a line inside a TITLE.
function! mplus#section#Pattern(in_title) abort
    return '\%(' . s:names . (a:in_title ? '' : '\|' . s:second) . '\)\s*:'
endfunction

let s:plain = '^\s*' . mplus#section#Pattern(1)
let s:any = '^\s*' . mplus#section#Pattern(0)

" Return whether a section starts on line a:lnum of the current buffer. A
" header with a second word starts one unless it stands in a TITLE, which
" is so when the nearest header above it without a second word is TITLE.
function! mplus#section#Starts(lnum) abort
    let l:line = getline(a:lnum)
    if l:line =~? s:plain
        return 1
    elseif l:line !~? s:any
        return 0
    endif
    let l:lnum = a:lnum - 1
    while l:lnum >= 1 && getline(l:lnum) !~? s:plain
        let l:lnum -= 1
    endwhile
    return getline(l:lnum) !~? '^\s*TITL\%[E]\s*:'
endfunction
