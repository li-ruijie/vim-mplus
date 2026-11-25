" Tests for syntax highlighting of Mplus input.

source <sfile>:p:h/common.vim

filetype plugin on
syntax on

" Return the syntax group of every character of a:line, taken as a line of
" a MODEL section.
function! s:Groups(line) abort
    enew!
    call setline(1, ['MODEL:', a:line])
    set filetype=mplus-inp
    syntax sync fromstart
    return map(range(1, strlen(a:line)), 'synIDattr(synID(2, v:val, 1), "name")')
endfunction

" Return the pieces of a:line that are highlighted as numbers.
function! s:Numbers(line) abort
    let l:groups = s:Groups(a:line)
    let l:found = []
    let l:start = -1
    for l:i in range(strlen(a:line) + 1)
        let l:is_number = l:i < strlen(a:line) && l:groups[l:i] ==# 'mplusNumber'
        if l:is_number && l:start < 0
            let l:start = l:i
        elseif !l:is_number && l:start >= 0
            call add(l:found, strpart(a:line, l:start, l:i - l:start))
            let l:start = -1
        endif
    endfor
    return l:found
endfunction

function! Test_digits_in_names_are_not_numbers() abort
    for l:line in ['y1 ON x1 x2a;', 'f BY u11-u14 y10;', 'x_1 WITH var2b;',
        \ 'FILE IS ex3.1.dat;', 'FILE = 2level.dat;', 'TECH1 TECH14 H1SE;',
        \ 'FORMAT IS 5F8.2;', '%c#1%']
        call assert_equal([], s:Numbers(l:line), l:line)
    endfor
    " The digits get the group of the section they are in, as the letters do.
    let l:groups = s:Groups('y1 ON x2a;')
    call assert_equal(['mplusFold', 'mplusFold'], l:groups[0:1])
    call assert_equal(['mplusFold', 'mplusFold', 'mplusFold'], l:groups[6:8])
endfunction

function! Test_numeric_literals() abort
    for [l:line, l:numbers] in [
        \ ['NOBSERVATIONS = 500;', ['500']],
        \ ['STARTS = 20 5;', ['20', '5']],
        \ ['f1 BY y1-y4*0.5 y5@1;', ['0.5', '1']],
        \ ['y1@0 y2*.25 y3*1.5E-3 y4*0.100D-05 y5*2.5e+3;',
        \     ['0', '.25', '1.5E-3', '0.100D-05', '2.5e+3']],
        \ ['[c#1@0 u1$2*3];', ['1', '0', '2', '3']],
        \ ['SERIES = y1-y4 (1-4);', ['1', '4']],
        \ ['x = y/100 + 2*z1;', ['100', '2']]]
        call assert_equal(l:numbers, s:Numbers(l:line), l:line)
    endfor
endfunction

function! Test_minus_sign() abort
    " A minus that starts a value belongs to the number.
    for [l:line, l:numbers] in [
        \ ['[u1$1*-1.5];', ['1', '-1.5']],
        \ ['y1@-1 y2@-.5;', ['-1', '-.5']],
        \ ['MISSING ARE ALL (-99);', ['-99']],
        \ ['LOOP(mod,-2,2,0.1);', ['-2', '2', '0.1']],
        \ ['x = -3;', ['-3']],
        \ ['MISSING = x (-1 -2);', ['-1', '-2']]]
        call assert_equal(l:numbers, s:Numbers(l:line), l:line)
    endfor
    " A minus after an operand is the subtraction or list operator.
    for [l:line, l:numbers] in [
        \ ['p = a-1;', ['1']],
        \ ['p = a - 1;', ['1']],
        \ ['p = 2*x1-3;', ['2', '3']],
        \ ['p = (a+b)-3;', ['3']],
        \ ['p = 5-3;', ['5', '3']]]
        call assert_equal(l:numbers, s:Numbers(l:line), l:line)
    endfor
    call assert_equal('mplusModel', s:Groups('f BY y1-y4;')[7])
    call assert_equal('mplusModel', s:Groups('p = a-1;')[5])
endfunction

call RunTests()
