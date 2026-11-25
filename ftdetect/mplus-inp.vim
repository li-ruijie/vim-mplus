autocmd BufRead,BufNewFile *.mdg set filetype=mplus-inp

" Other programs write their input under *.inp as well (Abaqus, ORCA, CP2K),
" so a file with content is taken as Mplus input only when its first line of
" code is a command header such as TITLE:, anal:, or MODEL INDIRECT:. A new
" or blank file is taken as Mplus input.
autocmd BufNewFile *.inp setfiletype mplus-inp
autocmd BufRead *.inp if s:IsMplusInput() | setfiletype mplus-inp | endif

" A command name in full or shortened to four or more letters, then a colon.
" Only DATA and MODEL take a second word (DATA IMPUTATION:, MODEL male:).
let s:header_re = '\c^\s*\%(TITL\%[E]\|VARI\%[ABLE]\|DEFI\%[NE]\|ANAL\%[YSIS]'
    \ . '\|OUTP\%[UT]\|SAVE\%[DATA]\|PLOT\|MONT\%[ECARLO]'
    \ . '\|\%(DATA\|MODE\%[L]\)\%(\s\+[^: \t]\+\)\=\)\s*:'

" Return whether the buffer is blank or its first line of code, looked for
" in the first 500 lines, is a command header. Blank lines, comment lines,
" and block comments (!* ... *!) are passed over.
function! s:IsMplusInput() abort
    let l:in_block = 0
    for l:line in getline(1, 500)
        if l:in_block || l:line =~# '^\s*!\*'
            let l:in_block = l:line !~# '\*!'
        elseif l:line !~# '^\s*\%(!.*\)\=$'
            return l:line =~# s:header_re
        endif
    endfor
    return search('\S', 'nw') == 0
endfunction
