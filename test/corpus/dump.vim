" Write the kind and the fold level of every line of Mplus outputs, as the
" syntax file test/corpus/../../syntax/mplus-out.vim reads them, for
" test/corpus/check-syntax.sh to compare with test/corpus/kinds.py. It runs
" in Vim and in Neovim with no configuration of the user:
"
"   CHECK_LIST=list CHECK_OUT=out vim -N -u NONE -i NONE -es -S dump.vim
"
" CHECK_LIST names a file with the path of one output on each line. For each
" output the file CHECK_OUT gets the line "= path", a line "! message" for
" every error message that opening the output gave, and a line "kind level"
" for every line of the output.
"
" The kind of a line comes from the syntax groups at its first character
" that is no space, and from the folds that start on it:
"
"   mplusFooter                          footer
"   mplusBanner                          banner
"   mplusEcho                            echohead where a fold of level 1
"                                        starts, echosect where a fold of
"                                        level 2 starts, else echo
"   mplusTitle                           title
"   the innermost of the groups below:
"     mplusError                         error
"     mplusWarning                       warning
"     mplusStatus                        status
"     mplusPart                          part where a fold starts, else part2
"     mplusSub                           sub where a fold starts, else sub2
"     mplusTable                         table
"   anything else, and an empty line     plain
"
" A fold that starts on a line of any other kind makes it "fold" and the
" level of the fold, so that the comparison finds it. The fold level is
" foldlevel() of the line, with folds of a single line allowed.

let s:repo = expand('<sfile>:p:h:h:h')
let &runtimepath = escape(s:repo, ',') . ',' . escape($VIMRUNTIME, ',')
set noswapfile nomore hidden
filetype plugin on
syntax on

let s:headers = {'mplusError': 'error', 'mplusWarning': 'warning', 'mplusStatus': 'status',
    \ 'mplusPart': 'part', 'mplusSub': 'sub', 'mplusTable': 'table'}
let s:folds = ['echohead', 'echosect', 'part', 'sub', 'table']

" Return the level of the fold that starts on each line, or 0, as a list
" indexed by line number.
function! s:FoldStarts() abort
    let l:starts = repeat([0], line('$') + 1)
    for l:level in [0, 1, 2]
        let &l:foldlevel = l:level
        let l:lnum = 1
        while l:lnum <= line('$')
            if foldclosed(l:lnum) == l:lnum
                let l:starts[l:lnum] = l:level + 1
                let l:lnum = foldclosedend(l:lnum)
            endif
            let l:lnum += 1
        endwhile
    endfor
    return l:starts
endfunction

" Return the kind of line a:lnum, where a fold of level a:start starts.
function! s:Kind(lnum, start) abort
    let l:col = match(getline(a:lnum), '\S') + 1
    if l:col == 0
        return 'plain'
    endif
    let l:names = map(synstack(a:lnum, l:col), 'synIDattr(v:val, "name")')
    if index(l:names, 'mplusFooter') >= 0
        return 'footer'
    elseif index(l:names, 'mplusBanner') >= 0
        return 'banner'
    elseif index(l:names, 'mplusEcho') >= 0
        return a:start == 1 ? 'echohead' : a:start == 2 ? 'echosect' : 'echo'
    elseif index(l:names, 'mplusTitle') >= 0
        return 'title'
    endif
    for l:name in reverse(l:names)
        if has_key(s:headers, l:name)
            let l:kind = s:headers[l:name]
            return l:kind =~# '^\%(part\|sub\)$' && !a:start ? l:kind . '2' : l:kind
        endif
    endfor
    return 'plain'
endfunction

function! s:Dump(path) abort
    let v:errmsg = ''
    let l:out = ['= ' . a:path]
    try
        execute 'edit ' . fnameescape(a:path)
        setlocal foldenable foldminlines=0
        let l:starts = s:FoldStarts()
        let l:lines = []
        for l:lnum in range(1, line('$'))
            let l:kind = s:Kind(l:lnum, l:starts[l:lnum])
            if l:starts[l:lnum] && index(s:folds, l:kind) < 0
                let l:kind = 'fold' . l:starts[l:lnum]
            endif
            call add(l:lines, l:kind . ' ' . foldlevel(l:lnum))
        endfor
    catch
        let v:errmsg = v:exception
        let l:lines = []
    endtry
    if !empty(v:errmsg)
        call add(l:out, '! ' . v:errmsg)
    endif
    call writefile(l:out + l:lines, $CHECK_OUT, 'a')
    bwipeout!
endfunction

for s:path in readfile($CHECK_LIST)
    call s:Dump(s:path)
endfor
qall!
