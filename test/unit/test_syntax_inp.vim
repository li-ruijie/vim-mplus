" Tests for the syntax of Mplus input that follow what Mplus 9.1.1 reads
" as a comment, found by running small inputs through mplus.exe.

source <sfile>:p:h/common.vim

filetype plugin on
syntax on

" Show a:lines in a buffer of type mplus-inp.
function! s:Buffer(lines) abort
    enew!
    call setline(1, a:lines)
    set filetype=mplus-inp
endfunction

" Return the syntax group at column a:col of line a:lnum.
function! s:Group(lnum, col) abort
    return synIDattr(synID(a:lnum, a:col, 1), 'name')
endfunction

" Return whether the text at column a:col of line a:lnum is a comment.
function! s:IsComment(lnum, col) abort
    return synIDattr(synIDtrans(synID(a:lnum, a:col, 1)), 'name') ==# 'Comment'
endfunction

" Return the first line of every fold of the buffer.
function! s:FoldStarts() abort
    setlocal foldminlines=0
    normal! zM
    return uniq(map(range(1, line('$')), 'foldclosed(v:val)'))
endfunction

function! Test_comments_in_a_title() abort
    " Mplus drops the comment of the TITLE line and a line below it that
    " starts with a ! with no * after it. It prints every other line of the
    " title, also one that holds a ! or starts with !*.
    call s:Buffer([
        \ 'TITLE: first line ! a comment',
        \ '! a comment line',
        \ '    ! an indented comment line',
        \ 'second line ! printed by Mplus',
        \ '!* printed as well',
        \ '  *! and this',
        \ 'third!line',
        \ 'DATA: FILE = x.dat; ! a comment',
        \ '  LISTWISE = ON;'])
    call assert_equal('mplusTitle', s:Group(1, 8))
    call assert_true(s:IsComment(1, 19))
    call assert_true(s:IsComment(2, 1))
    call assert_true(s:IsComment(3, 7))
    for l:lnum in [4, 5, 6, 7]
        for l:col in range(1, strlen(getline(l:lnum)))
            if getline(l:lnum)[l:col - 1] =~# '\S'
                call assert_equal('mplusTitle', s:Group(l:lnum, l:col), l:lnum . ':' . l:col)
            endif
        endfor
    endfor
    call assert_true(s:IsComment(8, 22))
    call assert_equal([1, 8], s:FoldStarts())
endfunction

function! Test_block_comment_mark_below_the_title_line() abort
    " Below the TITLE line, !* opens no block comment, so the header after
    " it starts a section, and *! there is a * and a comment.
    call s:Buffer([
        \ 'TITLE: a title',
        \ '!* text of the title',
        \ 'DATA: FILE = x.dat;',
        \ '*!',
        \ 'MODEL: y ON x;',
        \ '  x;'])
    call assert_equal('mplusTitle', s:Group(2, 1))
    call assert_equal('mplusSection', s:Group(3, 1))
    call assert_true(s:IsComment(4, 2))
    call assert_false(s:IsComment(4, 1))
    call assert_equal([1, 3, 5], s:FoldStarts())
endfunction

function! Test_block_comment_on_the_title_line() abort
    " On the TITLE line !* opens a block comment, which runs past the next
    " header to its *!, and a header in it starts no section.
    call s:Buffer([
        \ 'TITLE: a title !* the comment starts here',
        \ 'DATA: FILE = none.dat;',
        \ '   and ends here *! more title',
        \ 'DATA: FILE = x.dat;',
        \ '  LISTWISE = ON;',
        \ 'TITLE: two !* in the middle *! and the rest',
        \ '  more title',
        \ 'MODEL: y ON x;',
        \ '  x;'])
    call assert_equal('mplusTitle', s:Group(1, 8))
    call assert_true(s:IsComment(1, 16))
    call assert_true(s:IsComment(2, 1))
    call assert_true(s:IsComment(3, 19))
    call assert_equal('mplusTitle', s:Group(3, 24))
    call assert_equal('mplusSection', s:Group(4, 1))
    call assert_true(s:IsComment(6, 20))
    call assert_equal('mplusTitle', s:Group(6, 40))
    call assert_equal([1, 4, 6, 8], s:FoldStarts())
endfunction

function! Test_block_comment_after_code() abort
    " Mplus opens a block comment at a !* after code and in a ! comment, and
    " a header in it starts no section.
    call s:Buffer([
        \ 'MODEL:',
        \ '  y ON x; !* a block comment',
        \ 'DATA: FILE = none.dat;',
        \ '  *! z ON x;',
        \ '  z ON w; ! a note !* that opens one',
        \ 'OUTPUT: TECH1;',
        \ '*!',
        \ 'OUTPUT:',
        \ '  TECH1;'])
    for [l:lnum, l:col] in [[2, 11], [3, 1], [4, 3], [5, 11], [5, 20], [6, 1], [7, 1]]
        call assert_true(s:IsComment(l:lnum, l:col), l:lnum . ':' . l:col)
    endfor
    call assert_false(s:IsComment(4, 6))
    call assert_equal([1, 8], s:FoldStarts())
endfunction

call RunTests()
