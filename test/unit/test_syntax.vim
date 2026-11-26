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

" Return the first line of every fold of level a:level.
function! s:LevelStarts(level) abort
    setlocal foldminlines=0
    let &l:foldlevel = a:level - 1
    return filter(range(1, line('$')), 'foldclosed(v:val) == v:val')
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
    " The input echoed in an output is highlighted as an input, where the
    " TITLE header is a statement and the other headers are sections.
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
    for [l:lnum, l:header, l:group] in [[7, 'TITLE:', 'mplusStatement'],
        \ [9, 'Model comparison:', 'mplusSection'], [10, 'data:', 'mplusSection'],
        \ [11, 'Data imputation:', 'mplusSection'], [12, 'anal :', 'mplusSection'],
        \ [13, 'MODEL male:', 'mplusSection']]
        call assert_equal(l:group, synIDattr(synID(l:lnum, 3, 1), 'name'), l:header)
        call assert_equal(l:group,
            \ synIDattr(synID(l:lnum, 2 + strlen(l:header), 1), 'name'), l:header)
    endfor
    for l:lnum in [8, 14, 15]
        call assert_notequal('mplusSection', synIDattr(synID(l:lnum, 5, 1), 'name'), l:lnum)
    endfor
endfunction

function! Test_echoed_header_in_capitals() abort
    " A line in capitals at column 0 after an empty line starts a part of an
    " output. An echoed header on such a line is shown as an input shows it,
    " and starts a fold of level 2 in the echoed input, unless its section has
    " only the header line (TITLE here).
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
    call assert_equal(['mplusSection', 'mplusFold', 'mplusStatement', 'mplusFold'],
        \ s:LineGroups(14))
    call assert_equal(['mplusPart'], s:LineGroups(5))
    call assert_equal(['mplusPart'], s:LineGroups(16))
    call assert_equal(['mplusPart'], s:LineGroups(18))
    " The banner is in no fold. Lines 20 and 21 are result lines in the fold
    " of line 18, as line 21 has no empty line above it.
    call assert_equal(['mplusPartFold'], s:LineGroups(20))
    call assert_equal(['mplusPartFold'], s:LineGroups(21))
    call assert_equal([-1, 5, 16, 18], s:FoldStarts())
    call assert_equal([8, 10, 12, 14], s:LevelStarts(2))
endfunction

function! Test_output_headers_and_result_lines() abort
    " The headers of an output have a group for each of the three levels of
    " fold: a part (MODEL RESULTS), a sub-header (ON/BY Statements, PARAMETER
    " SPECIFICATION), and the name of a matrix or table (NU, LAMBDA). The
    " banner, the printed title, a warning, and the footer have groups of
    " their own. Result lines in capitals are no headers and start no fold.
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
        \ '',
        \ '           LAMBDA',
        \ '              F1',
        \ '              ________',
        \ ' Y1                 0',
        \ ' Y2                13',
        \ '',
        \ '',
        \ '           ESTIMATED RESIDUAL VARIANCES',
        \ '              Y1            Y2',
        \ '              ________      ________',
        \ '                0.999         0.999',
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
    let l:groups = {1: 'mplusBanner', 2: 'mplusBanner', 3: 'mplusBanner', 5: 'mplusPart',
        \ 14: 'mplusTitle', 16: 'mplusPart', 18: 'mplusPart', 28: 'mplusSub', 33: 'mplusPart',
        \ 36: 'mplusSub', 39: 'mplusTable', 45: 'mplusTable', 52: 'mplusTable',
        \ 57: 'mplusWarning', 58: 'mplusWarning', 60: 'mplusSub', 65: 'mplusFooter',
        \ 66: 'mplusFooter'}
    let l:kinds = uniq(sort(values(l:groups)))
    for l:lnum in range(1, len(l:lines))
        if l:lnum == 8
            call assert_equal(['mplusSection'], s:LineGroups(l:lnum))
        elseif has_key(l:groups, l:lnum)
            call assert_equal([l:groups[l:lnum]], s:LineGroups(l:lnum), l:lines[l:lnum - 1])
        elseif l:lnum < 7 || l:lnum > 10
            for l:group in s:LineGroups(l:lnum)
                call assert_equal(-1, index(l:kinds, l:group), l:lines[l:lnum - 1])
            endfor
        endif
    endfor
    " Line 7 is a section of one line, which starts no fold. The message that
    " ends the reading of the input and the printed title are in no fold.
    call assert_equal(repeat([0], 4) + repeat([1], 3) + repeat([2], 4) + repeat([0], 4)
        \ + repeat([1], 12) + repeat([2], 5) + repeat([1], 3) + repeat([2], 3)
        \ + repeat([3], 21) + repeat([2], 5) + repeat([0], 2),
        \ map(range(1, len(l:lines)), 'foldlevel(v:val)'))
    call assert_equal([5, 16, 18, 33], s:LevelStarts(1))
    call assert_equal([8, 28, 36, 60], s:LevelStarts(2))
    call assert_equal([39, 45, 52], s:LevelStarts(3))
endfunction

function! Test_printed_title_is_title_text() abort
    " Mplus prints the title between the messages about the input and the
    " summary of the analysis. It is title text whatever it looks like, and
    " it stands in no fold, as the message above it does. The files are
    " outputs of Mplus 9.1.1, with the lines of the title block given here.
    for [l:name, l:first, l:last] in [['title-same-line.out', 16, 20],
        \ ['title-plain.out', 17, 22], ['title-three-words.out', 17, 22]]
        execute 'edit' fnameescape(s:data . l:name)
        call assert_equal('mplus-out', &filetype, l:name)
        call assert_equal('INPUT READING TERMINATED NORMALLY', getline(l:first - 1), l:name)
        call assert_equal('SUMMARY OF ANALYSIS', getline(l:last + 1), l:name)
        for l:lnum in filter(range(l:first, l:last), 'getline(v:val) =~# "\\S"')
            call assert_equal(['mplusTitle'], s:LineGroups(l:lnum), l:name . ' line ' . l:lnum)
        endfor
        call assert_equal([''], s:LineGroups(l:first - 1), l:name)
        call assert_equal(['mplusPart'], s:LineGroups(l:last + 1), l:name)
        setlocal foldminlines=0
        normal! zM
        call assert_equal([-1, l:last + 1],
            \ uniq(map(range(l:first - 1, l:last + 1), 'foldclosed(v:val)')), l:name)
        bwipeout!
    endfor
    " In the echoed input the text on the TITLE: line is title text, as it is
    " in an input.
    execute 'edit' fnameescape(s:data . 'title-same-line.out')
    call assert_equal("  TITLE:\tModel comparison: two groups", getline(7))
    call assert_equal(['mplusStatement', 'mplusTitle'], s:LineGroups(7))
    bwipeout!
endfunction

function! Test_printed_title_without_summary() abort
    " Outputs of Mplus 9.1.1 that stop after the printed title, as Mplus wrote
    " them. In title-fatal.out the population covariance matrix is not
    " positive definite, in title-warning.out the sample covariance matrix is
    " singular, and title-interrupted.out is a long Monte Carlo study that
    " was ended after 15 seconds. The title is title text up to its end and
    " no further, also where it has an empty line in it, and it is in no fold.
    for [l:name, l:first, l:last] in [['title-fatal.out', 22, 26],
        \ ['title-warning.out', 22, 26], ['title-interrupted.out', 23, 27]]
        execute 'edit' fnameescape(s:data . l:name)
        call assert_equal('mplus-out', &filetype, l:name)
        call assert_equal('INPUT READING TERMINATED NORMALLY', getline(l:first - 4), l:name)
        call assert_equal(['MODEL RESULTS OF THE RUN', 'an indented line', '', 'after an empty line'],
            \ getline(l:first + 1, l:last), l:name)
        call assert_equal(0, search('SUMMARY OF ANALYSIS', 'nw'), l:name)
        for l:lnum in filter(range(l:first, l:last), 'getline(v:val) =~# "\\S"')
            call assert_equal(['mplusTitle'], s:LineGroups(l:lnum), l:name . ' line ' . l:lnum)
        endfor
        for l:lnum in filter(range(l:last + 1, line('$')), 'getline(v:val) =~# "\\S"')
            call assert_equal(-1, index(s:LineGroups(l:lnum), 'mplusTitle'),
                \ l:name . ' line ' . l:lnum . ': ' . getline(l:lnum))
        endfor
        setlocal foldminlines=0
        normal! zM
        call assert_equal(repeat([-1], 5), map(range(l:first - 4, l:first), 'foldclosed(v:val)'),
            \ l:name)
        call assert_equal(-1, foldclosed(l:last), l:name)
        bwipeout!
    endfor
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
    for l:lnum in [10, 11, 12]
        call assert_equal(['mplusWarning'], s:LineGroups(l:lnum), l:lnum)
    endfor
    for l:lnum in [15, 16, 17]
        call assert_equal(['mplusTitle'], s:LineGroups(l:lnum), l:lnum)
    endfor
    call assert_equal(['mplusPart'], s:LineGroups(19))
    call assert_equal('', synIDattr(synID(21, 1, 1), 'name') ==# 'mplusTitle' ? 'title' : '')
    " The warnings and the title are in no fold.
    setlocal foldminlines=0
    normal! zM
    call assert_equal(repeat([-1], 8), map(range(10, 17), 'foldclosed(v:val)'))
    call assert_equal(19, foldclosed(19))
endfunction

function! Test_timestamp_is_a_header() abort
    " Output has its own syntax file, which defines no numbers. The timestamp
    " of the banner is in the banner, and one below it is plain text.
    call s:Buffer('mplus-out', ['Mplus VERSION 8.8', 'MUTHEN & MUTHEN',
        \ '04/10/2017   4:39 AM', '', 'INPUT INSTRUCTIONS', '', '11/25/2026  10:30  PM'])
    call assert_equal(['mplusBanner'], s:LineGroups(3))
    call assert_equal([''], s:LineGroups(7))
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
        call assert_equal(['mplusBanner'], s:LineGroups(3), l:file)
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

function! Test_end_is_a_name() abort
    " Mplus has no END statement and stops with an error at END DO, so END
    " is a name as any other word is, while DO starts a loop.
    call assert_equal(['mplusFold', 'mplusFold', 'mplusFold'], s:Groups('f BY end y1;')[5:7])
    call assert_equal('mplusModel', s:Groups('DO (1, 2) y# ON x#;')[0])
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
