" Neither Vim nor Neovim has a rule for *.mdg, the diagram input of Mplus.
" setfiletype keeps a type that an earlier rule of another plugin has set.
autocmd BufRead,BufNewFile *.mdg setfiletype mplus-inp

" Other programs write their input under *.inp as well (Abaqus, ORCA, CP2K),
" so a file with content is taken as Mplus input only when its first line of
" code is a command header such as TITLE:, anal:, or MODEL INDIRECT:. A new
" or blank file is taken as Mplus input.
"
" A file that holds only comments is not taken. A line that starts with !
" is a keyword line in ORCA input and a comment in CP2K input, so such a
" file says nothing about the program it is for, and setfiletype would keep
" the type from a later rule of a plugin for one of those programs. Mplus
" does not run such a file either. It gets its type when a command is added
" and it is read again, or from :setfiletype mplus-inp.
autocmd BufNewFile *.inp setfiletype mplus-inp
autocmd BufRead *.inp if s:IsMplusInput() | setfiletype mplus-inp | endif

" A command name in full or shortened to four or more letters, followed by
" a colon at once or after one more word (DATA IMPUTATION:, MODEL male:,
" variable names:). This is the rule of autoload/mplus/section.vim for the
" line where a section starts, written out here as this file is read before
" the plugin is on the runtimepath. A unit test holds the two together.
let s:header_re = '\c^\s*\%(TITL\%[E]\|DATA\|VARI\%[ABLE]\|DEFI\%[NE]\|ANAL\%[YSIS]'
    \ . '\|MODE\%[L]\|OUTP\%[UT]\|SAVE\%[DATA]\|PLOT\|MONT\%[ECARLO]\)'
    \ . '\%(\s\+[^: \t]\+\)\=\s*:'

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
