" Tests for syntax highlighting and folding of Mplus input and output.

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

" Show a:lines in a buffer of type a:filetype.
function! s:Buffer(filetype, lines) abort
    enew!
    call setline(1, a:lines)
    execute 'set filetype=' . a:filetype
    syntax sync fromstart
endfunction

" Return the syntax groups along line a:lnum, each run of one group once.
function! s:LineGroups(lnum) abort
    return uniq(map(range(1, col([a:lnum, '$']) - 1),
        \ 'synIDattr(synID(a:lnum, v:val, 1), "name")'))
endfunction

" Return the first line of every fold of the buffer.
function! s:FoldStarts() abort
    setlocal foldminlines=0
    normal! zM
    return uniq(map(range(1, line('$')), 'foldclosed(v:val)'))
endfunction

function! Test_title_ends_only_at_a_command_name_and_a_colon() abort
    call s:Buffer('mplus-inp', [
        \ 'TITLE: a study of growth',
        \ '  model comparison: two groups',
        \ '  Data imputation: twenty data sets',
        \ 'DATA:',
        \ '  FILE = x.dat;',
        \ 'data imputation:',
        \ '  IMPUTE = y1;',
        \ 'MODEL:',
        \ '  f BY y1;',
        \ 'Model male:',
        \ '  f BY y1;',
        \ '  anal:',
        \ '    TYPE = BASIC;'])
    call assert_equal([1, 4, 6, 8, 10, 12], s:FoldStarts())
    call assert_equal(['mplusTitle'], s:LineGroups(2))
    call assert_equal(['mplusTitle'], s:LineGroups(3))
    call assert_equal('mplusSection', synIDattr(synID(6, 1, 1), 'name'))
    call assert_equal('mplusSection', synIDattr(synID(10, 1, 1), 'name'))
    call assert_equal('mplusSection', synIDattr(synID(12, 3, 1), 'name'))
endfunction

function! Test_section_name_in_full_or_shortened() abort
    call s:Buffer('mplus-inp', ['MODEL:', '  f BY y1;', 'modeling: x;',
        \ 'database: y;', 'VARIABLE names: z;', 'anal:', '  TYPE = BASIC;',
        \ 'OUTPUT :', '  TECH1;'])
    call assert_equal([1, 6, 8], s:FoldStarts())
endfunction

function! Test_timestamp_is_a_header() abort
    " Output has its own syntax file, which defines no numbers.
    call s:Buffer('mplus-out', ['Mplus VERSION 8.8', 'MUTHEN & MUTHEN',
        \ '04/10/2017   4:39 AM', '', 'INPUT INSTRUCTIONS', '', '11/25/2026  10:30  PM'])
    call assert_equal(['mplusHeader'], s:LineGroups(3))
    call assert_equal(['mplusHeader'], s:LineGroups(7))
    " The rules for input define the same line, which starts as a number does.
    call s:Buffer('mplus-inp', ['MODEL:', '04/10/2017   4:39 AM', '11/25/2026  10:30  PM',
        \ '  x = 04/10;'])
    call assert_equal(['mplusHeader'], s:LineGroups(2))
    call assert_equal(['mplusHeader'], s:LineGroups(3))
    call assert_equal(['04', '10'], s:Numbers('  x = 04/10;'))
endfunction

function! Test_examples() abort
    for l:file in ExampleFiles('out')
        execute 'edit' fnameescape(l:file)
        syntax sync fromstart
        call assert_equal(['mplusHeader'], s:LineGroups(3), l:file)
        bwipeout!
    endfor
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
