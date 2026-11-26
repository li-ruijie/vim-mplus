" Tests for syntax highlighting and folding of Mplus input and output.

source <sfile>:p:h/common.vim

filetype plugin on
syntax on

let s:data = expand('<sfile>:p:h:h') . '/data/'

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

function! Test_title_ends_at_a_header() abort
    " A command name, alone or with one more word, and a colon start a
    " section, in a TITLE as anywhere else.
    call s:Buffer('mplus-inp', [
        \ 'TITLE: a study of growth',
        \ '  Step 2: more text',
        \ '  model with covariates: two groups',
        \ '  Model comparison: two groups',
        \ '  more text',
        \ 'DATA:',
        \ '  FILE = x.dat;',
        \ 'data imputation:',
        \ '  IMPUTE = y1;',
        \ 'Variable names:',
        \ '  x',
        \ 'title notes:',
        \ '  x',
        \ '  anal :',
        \ '    TYPE = BASIC;'])
    call assert_equal([1, 4, 6, 8, 10, 12, 14], s:FoldStarts())
    call assert_equal(['mplusTitle'], s:LineGroups(2))
    call assert_equal(['mplusTitle'], s:LineGroups(3))
    for [l:lnum, l:col] in [[4, 3], [8, 1], [10, 1], [12, 1], [14, 3]]
        call assert_equal('mplusSection', synIDattr(synID(l:lnum, l:col, 1), 'name'), l:lnum)
    endfor
endfunction

function! Test_title_text() abort
    " A semicolon does not end a title, and the word title at the start of
    " a line starts one only as a TITLE header.
    call s:Buffer('mplus-inp', [
        \ 'TITLE: a study; in two parts',
        \ '  second line; with more',
        \ '  third line',
        \ 'DATA:',
        \ '  FILE = x.dat;',
        \ 'MODEL:',
        \ '  title ON x;',
        \ '  y ON title;',
        \ 'title notes: passed over by Mplus',
        \ '  f BY y1;'])
    call assert_equal(['mplusStatement', 'mplusTitle'], s:LineGroups(1))
    call assert_equal(['mplusTitle'], s:LineGroups(2))
    call assert_equal(['mplusTitle'], s:LineGroups(3))
    for l:lnum in [5, 7, 8, 9, 10]
        call assert_equal(-1, index(s:LineGroups(l:lnum), 'mplusTitle'), l:lnum)
    endfor
    call assert_equal('mplusModel', synIDattr(synID(7, 9, 1), 'name'))
    call assert_equal([1, 4, 6, 9], s:FoldStarts())
endfunction

function! Test_title_text_on_the_title_line() abort
    " Text on the TITLE: line is title text, whatever it looks like.
    call s:Buffer('mplus-inp', [
        \ "TITLE:\tModel comparison: two groups",
        \ '  and more text',
        \ 'DATA:',
        \ '  FILE = x.dat;'])
    call assert_equal(['mplusStatement', 'mplusTitle'], s:LineGroups(1))
    call assert_equal(['mplusTitle'], s:LineGroups(2))
    call assert_equal([1, 3], s:FoldStarts())
endfunction

function! Test_header_in_a_block_comment_starts_no_fold() abort
    call s:Buffer('mplus-inp', [
        \ '!* DATA: a heading in a comment',
        \ 'MODEL: and one more *!',
        \ 'MODEL:',
        \ '  f BY y1;',
        \ '  !* a note',
        \ 'DATA: this is inside the comment',
        \ '  MODEL male: and so is this *!',
        \ '  y ON x;',
        \ 'OUTPUT:',
        \ '  TECH1;'])
    call assert_equal([-1, 3, 9], s:FoldStarts())
    for l:lnum in [1, 2, 5, 6, 7]
        call assert_equal(['mplusBlockComment'], s:LineGroups(l:lnum)[-1:], l:lnum)
    endfor
    call assert_equal('mplusModel', synIDattr(synID(8, 5, 1), 'name'))
endfunction

function! Test_section_name_in_full_or_shortened() abort
    call s:Buffer('mplus-inp', ['MODEL:', '  f BY y1;', 'modeling: x;',
        \ 'database: y;', 'models x: z;', 'plo: z;', 'anal:', '  TYPE = BASIC;',
        \ 'OUTPUT :', '  TECH1;'])
    call assert_equal([1, 7, 9], s:FoldStarts())
endfunction

function! Test_echoed_headers() abort
    " The input echoed in an output has the headers of the input.
    call s:Buffer('mplus-out', [
        \ 'Mplus VERSION 9.1.1',
        \ 'MUTHEN & MUTHEN',
        \ '11/25/2026  10:30 AM',
        \ '',
        \ 'INPUT INSTRUCTIONS',
        \ '',
        \ '  TITLE: a study',
        \ '  Step 2: more text',
        \ '  Model comparison: two groups',
        \ '  data: file is x.dat;',
        \ '  Data imputation: impute = y1;',
        \ '  anal : type = basic;',
        \ '  MODEL male:',
        \ '    f BY y1;',
        \ '  models: x',
        \ '',
        \ 'INPUT READING TERMINATED NORMALLY'])
    for [l:lnum, l:header] in [[7, 'TITLE:'], [9, 'Model comparison:'], [10, 'data:'],
        \ [11, 'Data imputation:'], [12, 'anal :'], [13, 'MODEL male:']]
        call assert_equal('mplusSection', synIDattr(synID(l:lnum, 3, 1), 'name'), l:header)
        call assert_equal('mplusSection',
            \ synIDattr(synID(l:lnum, 2 + strlen(l:header), 1), 'name'), l:header)
    endfor
    for l:lnum in [8, 14, 15]
        call assert_notequal('mplusSection', synIDattr(synID(l:lnum, 5, 1), 'name'), l:lnum)
    endfor
endfunction

function! Test_echoed_header_in_capitals() abort
    " A line in capitals starts a fold in an output. An echoed header on
    " such a line is shown as the other echoed headers are.
    call s:Buffer('mplus-out', [
        \ 'Mplus VERSION 9.1.1',
        \ 'MUTHEN & MUTHEN',
        \ '11/25/2026  10:30 AM',
        \ '',
        \ 'INPUT INSTRUCTIONS',
        \ '',
        \ '  TITLE: a study',
        \ '  ANALYSIS:',
        \ '    TYPE = TWOLEVEL;',
        \ '  MODEL:      %WITHIN%',
        \ '    f BY y1;',
        \ '  MODEL POPULATION:',
        \ '    f BY y1;',
        \ '  OUTPUT: TECH1;',
        \ '',
        \ 'SUMMARY OF ANALYSIS',
        \ '',
        \ 'MODEL RESULTS',
        \ '',
        \ '    F BY Y1',
        \ 'TECHNICAL 1 OUTPUT:',
        \ '    x'])
    call assert_equal(['mplusSection'], s:LineGroups(8))
    call assert_equal(['mplusSection', 'mplusFold', 'mplusSection'], s:LineGroups(10))
    call assert_equal(['mplusSection'], s:LineGroups(12))
    call assert_equal(['mplusSection', 'mplusFold'], s:LineGroups(14))
    call assert_equal(['mplusHeader'], s:LineGroups(5))
    call assert_equal(['mplusHeader'], s:LineGroups(16))
    call assert_equal(['mplusHeader'], s:LineGroups(18))
    call assert_equal(['mplusHeader'], s:LineGroups(21))
    " The folds are those of the headers. Line 1 is in no fold, as it is not
    " in capitals. Line 20 is a result line and stays in the fold of line 18.
    call assert_equal(['mplusFold'], s:LineGroups(20))
    call assert_equal([-1, 2, 5, 8, 10, 12, 16, 18, 21], s:FoldStarts())
endfunction

function! Test_output_headers_and_result_lines() abort
    " A line in capitals is a header at column 0, or where it is indented
    " and has an empty line above and below it. Result lines in capitals
    " are no headers and start no fold.
    let l:lines = [
        \ 'Mplus VERSION 9.1.1',
        \ 'MUTHEN & MUTHEN',
        \ '11/26/2026  10:30 AM',
        \ '',
        \ 'INPUT INSTRUCTIONS',
        \ '',
        \ '  TITLE: a study',
        \ '  MODEL:',
        \ '    F1 BY Y1-Y3',
        \ '       Y4;',
        \ '',
        \ 'INPUT READING TERMINATED NORMALLY',
        \ '',
        \ 'a study',
        \ '',
        \ 'SUMMARY OF ANALYSIS',
        \ '',
        \ 'MODEL RESULTS',
        \ '',
        \ '                    Estimate',
        \ ' F1       BY',
        \ '    Y1                 1.000',
        \ ' Y2       WITH',
        \ '    Y3               999.000',
        \ '',
        \ 'MINIMUM ROTATION FUNCTION VALUE       0.12345',
        \ '',
        \ 'ON/BY Statements',
        \ '',
        \ 'Y1       ON I        /',
        \ 'I        BY Y1                     4.225     0.057',
        \ '',
        \ 'TECHNICAL 1 OUTPUT',
        \ '',
        \ '',
        \ '     PARAMETER SPECIFICATION',
        \ '',
        \ '',
        \ '           NU',
        \ '              Y1            Y2',
        \ '              ________      ________',
        \ '                    1             2',
        \ '',
        \ '     THE STANDARD ERRORS OF THE MODEL PARAMETER ESTIMATES MAY NOT BE',
        \ '     TRUSTWORTHY FOR SOME PARAMETERS',
        \ '',
        \ '  TECHNICAL 8 OUTPUT FOR STARTING VALUE SET 3',
        \ '',
        \ '   E STEP  ITER  LOGLIKELIHOOD    ABS CHANGE',
        \ '              1  -0.21490513D+04    0.0000000',
        \ '',
        \ 'MUTHEN & MUTHEN',
        \ '3463 Stoner Ave.']
    call s:Buffer('mplus-out', l:lines)
    let l:headers = [2, 3, 5, 12, 16, 18, 33, 36, 47, 52]
    for l:lnum in range(1, len(l:lines))
        if l:lnum == 8
            call assert_equal(['mplusSection'], s:LineGroups(l:lnum))
        elseif index(l:headers, l:lnum) >= 0
            call assert_equal(['mplusHeader'], s:LineGroups(l:lnum), l:lines[l:lnum - 1])
        else
            call assert_equal(-1, index(s:LineGroups(l:lnum), 'mplusHeader'), l:lines[l:lnum - 1])
        endif
    endfor
    call assert_equal([-1, 2, 5, 8, 12, 16, 18, 33, 36, 47, 52], s:FoldStarts())
endfunction

function! Test_printed_title_is_title_text() abort
    " Mplus prints the title between the messages about the input and the
    " summary of the analysis. It is title text whatever it looks like, and
    " it stays in the fold of the line above it. The files are outputs of
    " Mplus 9.1.1, with the lines of the title block given here.
    for [l:name, l:first, l:last] in [['title-same-line.out', 16, 20],
        \ ['title-plain.out', 17, 22], ['title-three-words.out', 17, 22]]
        execute 'edit' fnameescape(s:data . l:name)
        syntax sync fromstart
        call assert_equal('mplus-out', &filetype, l:name)
        call assert_equal('INPUT READING TERMINATED NORMALLY', getline(l:first - 1), l:name)
        call assert_equal('SUMMARY OF ANALYSIS', getline(l:last + 1), l:name)
        for l:lnum in filter(range(l:first, l:last), 'getline(v:val) =~# "\\S"')
            call assert_equal(['mplusTitle'], s:LineGroups(l:lnum), l:name . ' line ' . l:lnum)
        endfor
        call assert_equal(['mplusHeader'], s:LineGroups(l:first - 1), l:name)
        call assert_equal(['mplusHeader'], s:LineGroups(l:last + 1), l:name)
        setlocal foldminlines=0
        normal! zM
        call assert_equal([l:first - 1, l:last + 1],
            \ uniq(map(range(l:first - 1, l:last + 1), 'foldclosed(v:val)')), l:name)
        bwipeout!
    endfor
    " In the echoed input the text on the TITLE: line is no header either.
    execute 'edit' fnameescape(s:data . 'title-same-line.out')
    syntax sync fromstart
    call assert_equal("  TITLE:\tModel comparison: two groups", getline(7))
    call assert_equal(['mplusSection', 'mplusFold'], s:LineGroups(7))
    bwipeout!
endfunction

function! Test_printed_title_after_warnings() abort
    call s:Buffer('mplus-out', [
        \ 'Mplus VERSION 9.1.1',
        \ 'MUTHEN & MUTHEN',
        \ '11/26/2026   9:58 AM',
        \ '',
        \ 'INPUT INSTRUCTIONS',
        \ '',
        \ '  TITLE: A TITLE IN CAPITALS',
        \ '  DATA: FILE IS x.dat;',
        \ '',
        \ '*** WARNING in OUTPUT command',
        \ '  TECH8 option is not available.',
        \ '   1 WARNING(S) FOUND IN THE INPUT INSTRUCTIONS',
        \ '',
        \ '',
        \ 'A TITLE IN CAPITALS',
        \ 'MODEL: this is title text',
        \ '! and so is this, with %percent% signs',
        \ '',
        \ 'SUMMARY OF ANALYSIS',
        \ '',
        \ 'Number of groups                                                 1'])
    for l:lnum in [15, 16, 17]
        call assert_equal(['mplusTitle'], s:LineGroups(l:lnum), l:lnum)
    endfor
    call assert_equal(['mplusHeader'], s:LineGroups(19))
    call assert_equal('', synIDattr(synID(21, 1, 1), 'name') ==# 'mplusTitle' ? 'title' : '')
    setlocal foldminlines=0
    normal! zM
    call assert_equal(foldclosed(12), foldclosed(15))
    call assert_equal(foldclosed(12), foldclosed(17))
    call assert_equal(19, foldclosed(19))
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
