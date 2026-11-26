" Where a section of an Mplus input starts. The syntax files, the indent
" file, and the formatter all take the rule from this file. The rule was
" found by running inputs through Mplus 9.1.1, and test/mplus-rules.sh runs
" them again.
"
" A section starts on a line whose first word is a command name, followed by
" a colon either at once or after one more word. The names are TITLE, DATA,
" VARIABLE, DEFINE, ANALYSIS, MODEL, OUTPUT, SAVEDATA, PLOT, and MONTECARLO,
" in any case, in full or shortened to four or more letters. Spaces and tabs
" may stand before the first word, between the words, and before the colon.
" The rule is the same inside a TITLE, so a title line such as "Model
" comparison: two groups" ends the title. A semicolon does not end a title.
"
" No section starts where three words stand before the colon ("model with
" covariates: x"), where the first word is no command name ("models: x",
" "plo: x"), or where the name does not start the line ("the model: x").
"
" What Mplus does with the section depends on the header.
"
"   One word                 the command (anal: is ANALYSIS:)
"   MODEL in full, a word    MODEL CONSTRAINT, INDIRECT, TEST, PRIORS, and
"                            so on when the word is that name in full, and
"                            else the model of the group or class with that
"                            label
"   DATA, a subcommand       DATA IMPUTATION, MISSING, TWOPART, WIDETOLONG,
"                            LONGTOWIDE, SURVIVAL, or COHORT, with the name
"                            in full
"   DATA, another word       an error ("Unknown command"), or nothing at
"                            all when the word shortens a subcommand name
"   Any other pair           nothing at all
"
" "Nothing at all" means that Mplus passes over every line up to the next
" header without a message. That holds for "mode indirect:", for "variable
" names:", and for "data impu:". mplus#section#Parse() reports such a header
" as not read, and the formatter then leaves the section as it is.
"
" ftdetect/mplus-inp.vim has its own pattern for the first line of a file,
" since it has to work before the plugin is on the runtimepath. The pattern
" follows the same rule, and test/unit/test_ftdetect.vim checks the two
" against the same cases.

let s:commands = ['TITLE', 'DATA', 'VARIABLE', 'DEFINE', 'ANALYSIS', 'MODEL',
    \ 'OUTPUT', 'SAVEDATA', 'PLOT', 'MONTECARLO']
let s:data_commands = ['IMPUTATION', 'MISSING', 'TWOPART', 'WIDETOLONG',
    \ 'LONGTOWIDE', 'SURVIVAL', 'COHORT']

let s:names = 'TITL\%[E]\|DATA\|VARI\%[ABLE]\|DEFI\%[NE]\|ANAL\%[YSIS]\|MODE\%[L]'
    \ . '\|OUTP\%[UT]\|SAVE\%[DATA]\|PLOT\|MONT\%[ECARLO]'
let s:header = '\%(' . s:names . '\)\%(\s\+[^: \t]\+\)\=\s*:'
let s:parts = '\c^\s*\(' . s:names . '\)\%(\s\+\([^: \t]\+\)\)\=\s*:\s*\(.*\)$'

" Return the pattern of a section header, to be matched without regard to
" case after the indent of a line.
function! mplus#section#Pattern() abort
    return s:header
endfunction

" Return whether a section starts on line a:lnum of the current buffer. A
" line in a block comment (!* ... *!) starts none, whatever it looks like.
" The comment is open at the line when the nearest line above that begins
" or ends a block comment begins one.
function! mplus#section#Starts(lnum) abort
    if getline(a:lnum) !~? '^\s*' . s:header
        return 0
    endif
    let l:lnum = a:lnum - 1
    while l:lnum >= 1
        let l:line = getline(l:lnum)
        if l:line =~# '\*!'
            return 1
        elseif l:line =~# '^\s*!\*'
            return 0
        endif
        let l:lnum -= 1
    endwhile
    return 1
endfunction

" Take a:line apart as a section header. Return [] when no section starts
" there, else [name, word, rest, read]. The name is the command name in
" full and in capitals, the word is the second word in capitals or '', the
" rest is the text after the colon, and read tells whether Mplus reads the
" section.
function! mplus#section#Parse(line) abort
    let l:m = matchlist(a:line, s:parts)
    if empty(l:m)
        return []
    endif
    let l:first = toupper(l:m[1])
    let l:word = toupper(l:m[2])
    let l:read = l:word ==# '' || l:first ==# 'MODEL'
        \ || (l:first ==# 'DATA' && index(s:data_commands, l:word) >= 0)
    return [s:commands[match(s:commands, '^' . l:first)], l:word, l:m[3], l:read]
endfunction
