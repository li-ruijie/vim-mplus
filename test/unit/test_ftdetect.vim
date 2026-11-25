" Tests for file type detection of *.inp, *.out, and *.mdg files.

source <sfile>:p:h/common.vim

" A rule of another plugin that is registered before the rules of vim-mplus.
augroup filetypedetect
    autocmd BufRead,BufNewFile claimed.inp,claimed.out setfiletype claimed
augroup END
filetype on

let s:dir = tempname()
call mkdir(s:dir, 'p')

" Edit the file a:path and return the file type it is given.
function! s:TypeOf(path) abort
    execute 'edit' fnameescape(a:path)
    let l:type = &filetype
    bwipeout!
    return l:type
endfunction

" Write a:lines to a file called a:name and return its file type.
function! s:Detect(name, lines) abort
    call writefile(a:lines, s:dir . '/' . a:name)
    return s:TypeOf(s:dir . '/' . a:name)
endfunction

function! Test_inp_new_or_empty() abort
    call assert_equal('mplus-inp', s:TypeOf(s:dir . '/missing.inp'))
    call assert_equal('mplus-inp', s:Detect('empty.inp', []))
    call assert_equal('mplus-inp', s:Detect('blank.inp', ['', '   ', '']))
endfunction

function! Test_inp_starts_with_a_command() abort
    for l:line in ['TITLE: a regression', 'title:', '  Title :', 'TITL: x',
        \ 'DATA: FILE IS ex.dat;', 'data imputation:', 'VARIABLE:', 'vari:',
        \ 'VARIABL: NAMES = y;', 'DEFINE:', 'defi:', 'ANALYSIS: TYPE = BASIC;',
        \ 'ANAL:', 'analys:', 'MODEL:', 'MODE:', 'MODEL INDIRECT:',
        \ 'model population-g1:', 'Model male:', 'OUTPUT: TECH1;', 'outp:',
        \ 'SAVEDATA:', 'SAVE:', 'saved:', 'PLOT:', 'MONTECARLO:', 'mont:',
        \ 'Montecar:']
        call assert_equal('mplus-inp', s:Detect('case.inp', [l:line, '  y ON x;']), l:line)
    endfor
endfunction

function! Test_inp_command_after_comments() abort
    call assert_equal('mplus-inp', s:Detect('case.inp',
        \ ['', '! a comment', '  ! another', '', 'data: file is ex.dat;']))
    call assert_equal('mplus-inp', s:Detect('case.inp',
        \ ['!* a block comment', 'Heading: free text', 'ends here *!', 'VARIABLE:']))
    call assert_equal('mplus-inp', s:Detect('case.inp',
        \ ['!* on one line *!', 'ANALYSIS:']))
    call assert_equal('mplus-inp', s:Detect('case.inp',
        \ repeat(['! comment'], 300) + ['TITLE: late']))
endfunction

function! Test_inp_of_another_program() abort
    for l:lines in [
        \ ['*Heading', '** Abaqus job', '*Node'],
        \ ['! B3LYP def2-SVP', '* xyz 0 1', 'H 0 0 0', '*'],
        \ ['&GLOBAL', '  PROJECT water', '&END GLOBAL'],
        \ ['Some notes kept under this extension.'],
        \ ['&CONTROL', 'TITLE: this is not the first line of code'],
        \ ['! only a comment'],
        \ ['!* an open block comment', 'TITLE: inside the comment'],
        \ ['TITLES: x'], ['TIT: x'], ['DAT: x'], ['MODELS: x'],
        \ ['VARIABLE NAMES: x'], ['TITLE without a colon'], ['[TITLE]'],
        \ ['MODEL two words: x']]
        call assert_notequal('mplus-inp', s:Detect('case.inp', l:lines), string(l:lines))
    endfor
    call assert_notequal('mplus-inp', s:Detect('case.inp',
        \ repeat([''], 500) + ['TITLE: too far down']))
endfunction

function! Test_out_of_mplus() abort
    call assert_equal('mplus-out', s:Detect('case.out',
        \ ['Mplus VERSION 8.8', 'MUTHEN & MUTHEN', '04/10/2017   4:39 AM', '',
        \ 'INPUT INSTRUCTIONS']))
    call assert_equal('mplus-out', s:Detect('case.out',
        \ ['', '  Mplus VERSION 8.8 (Mac)', 'INPUT INSTRUCTIONS']))
    call assert_equal('mplus-out', s:Detect('case.out',
        \ ['Mplus DEVELOPMENT', 'MUTHEN & MUTHEN']))
endfunction

function! Test_out_of_another_program() abort
    call assert_equal('', s:TypeOf(s:dir . '/missing.out'))
    call assert_equal('', s:Detect('empty.out', []))
    call assert_equal('', s:Detect('case.out', ['Hello, world', 'exit status 0']))
    call assert_equal('', s:Detect('case.out', ['Converted from Mplus VERSION 8.8']))
    call assert_equal('', s:Detect('case.out', ['mplus version 8.8']))
    call assert_equal('', s:Detect('case.out',
        \ repeat(['log line'], 10) + ['Mplus VERSION 8.8', 'MUTHEN & MUTHEN']))
endfunction

function! Test_type_set_by_another_rule_is_kept() abort
    call assert_equal('claimed', s:Detect('claimed.inp', ['TITLE: x']))
    call assert_equal('claimed', s:Detect('claimed.out', ['Mplus VERSION 8.8']))
endfunction

function! Test_mdg() abort
    call assert_equal('mplus-inp', s:Detect('case.mdg', ['anything']))
endfunction

function! Test_examples() abort
    for l:file in ExampleFiles('inp')
        call assert_equal('mplus-inp', s:TypeOf(l:file), l:file)
    endfor
    for l:file in ExampleFiles('out')
        call assert_equal('mplus-out', s:TypeOf(l:file), l:file)
    endfor
endfunction

call RunTests()
