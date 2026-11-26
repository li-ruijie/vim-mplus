" Tests for the rule of autoload/mplus/section.vim, where a section starts.

source <sfile>:p:h/common.vim

let s:cases = expand('<sfile>:p:h:h') . '/header-cases.txt'

" Return the reading of a:line by mplus#section#Parse(), in the words of
" header-cases.txt. Parse() does not tell "skipped" from "rejected".
function! s:Reading(line) abort
    let l:header = mplus#section#Parse(a:line)
    return empty(l:header) ? 'text' : l:header[3] ? 'command' : 'not read'
endfunction

function! Test_cases_read_as_mplus_reads_them() abort
    let l:count = 0
    for l:case in filter(readfile(s:cases), 'v:val !~# "^\\%(#.*\\)\\=$"')
        let [l:expected, l:text] = split(l:case, '|')
        let l:line = substitute(l:text, '\\t', "\t", 'g') . ' zzmark'
        call assert_equal(substitute(l:expected, 'skipped\|rejected', 'not read', ''),
            \ s:Reading(l:line), l:case)
        enew!
        call setline(1, l:line)
        call assert_equal(l:expected !=# 'text', mplus#section#Starts(1), l:case)
        let l:count += 1
    endfor
    call assert_true(l:count > 100, 'cases: ' . l:count)
endfunction

function! Test_parts_of_a_header() abort
    for [l:line, l:parts] in [
        \ ['anal: type = basic;', ['ANALYSIS', '', 'type = basic;', 1]],
        \ ["  Saved \t:", ['SAVEDATA', '', '', 1]],
        \ ['Model male: f BY y1;', ['MODEL', 'MALE', 'f BY y1;', 1]],
        \ ["data \timputation :  impute = y1;", ['DATA', 'IMPUTATION', 'impute = y1;', 1]],
        \ ['mode indirect: y IND x;', ['MODEL', 'INDIRECT', 'y IND x;', 0]],
        \ ['mont notes:', ['MONTECARLO', 'NOTES', '', 0]],
        \ ['title: one: two', ['TITLE', '', 'one: two', 1]]]
        call assert_equal(l:parts, mplus#section#Parse(l:line), l:line)
    endfor
endfunction

function! Test_no_section_starts_in_a_block_comment() abort
    enew!
    call setline(1, ['!* DATA: x', 'MODEL: y', 'title: z *!', 'MODEL:', '!* one line *!',
        \ 'OUTPUT:', '  !* open', 'PLOT:'])
    call assert_equal([0, 0, 0, 1, 0, 1, 0, 0], map(range(1, 8), 'mplus#section#Starts(v:val)'))
endfunction

call RunTests()
