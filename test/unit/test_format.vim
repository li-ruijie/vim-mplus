" Tests for the gq formatter.

source <sfile>:p:h/common.vim

filetype plugin indent on

" Format a:lines as a whole Mplus input, check that a second pass changes
" nothing, and return the result.
function! s:Format(lines) abort
    enew!
    call setline(1, a:lines)
    set filetype=mplus-inp
    normal gggqG
    let l:once = getline(1, '$')
    normal gggqG
    call assert_equal(l:once, getline(1, '$'), 'second pass: ' . string(a:lines))
    return l:once
endfunction

" Format the statement a:statement in a section that starts with a:header
" and return the formatted statement.
function! s:Statement(header, statement) abort
    let l:lines = s:Format([a:header, a:statement])
    call assert_equal(2, len(l:lines), a:header . ' ' . a:statement)
    return substitute(l:lines[-1], '^\s*', '', '')
endfunction

function! Test_esti_depends_on_the_section() abort
    for l:word in ['esti', 'ESTIM', 'Estima', 'estimat', 'estimato']
        call assert_equal('ESTIMATOR = MLR;',
            \ s:Statement('ANALYSIS:', l:word . ' = mlr;'), l:word)
    endfor
    for l:word in ['esti', 'ESTIM', 'Estima', 'estimat', 'estimate']
        call assert_equal('ESTIMATES = Results.dat;',
            \ s:Statement('SAVEDATA:', l:word . ' are Results.dat;'), l:word)
    endfor
endfunction

function! Test_other_abbreviations_depend_on_the_section() abort
    for [l:header, l:statement, l:expected] in [
        \ ['OUTPUT:', 'samp resi modi;', 'SAMPSTAT RESIDUAL MODINDICES;'],
        \ ['SAVEDATA:', 'samp is Sample.dat;', 'SAMPLE = Sample.dat;'],
        \ ['VARIABLE:', 'miss are all (-99);', 'MISSING = ALL (-99);'],
        \ ['MONTECARLO:', 'miss = y1-y4;', 'MISSING = Y1-Y4;'],
        \ ['SAVEDATA:', 'miss = 999;', 'MISSFLAG = 999;'],
        \ ['ANALYSIS:', 'star = 20 5;', 'STARTS = 20 5;'],
        \ ['ANALYSIS:', 'start = 20 5;', 'STARTS = 20 5;'],
        \ ['MONTECARLO:', 'star = Start.dat;', 'STARTING = Start.dat;'],
        \ ['MONTECARLO:', 'start = Start.dat;', 'STARTING = Start.dat;'],
        \ ['DATA IMPUTATION:', 'impu = y1-y4;', 'IMPUTE = Y1-Y4;'],
        \ ['DATA:', 'vari = nocheck;', 'VARIANCES = NOCHECK;'],
        \ ['ANALYSIS:', 'vari = 0.001;', 'VARIANCE = 0.001;'],
        \ ['DATA WIDETOLONG:', 'idva = id;', 'IDVARIABLE = ID;'],
        \ ['VARIABLE:', 'idva = id;', 'IDVARIABLE = ID;'],
        \ ['DATA:', 'nobs = 500;', 'NOBSERVATIONS = 500;'],
        \ ['MONTECARLO:', 'nobs = 500;', 'NOBSERVATIONS = 500;'],
        \ ['MONTECARLO:', 'nobservation = 500;', 'NOBSERVATIONS = 500;']]
        call assert_equal(l:expected, s:Statement(l:header, l:statement),
            \ l:header . ' ' . l:statement)
    endfor
endfunction

function! Test_abbreviation_of_another_section_is_kept() abort
    for [l:header, l:statement, l:expected] in [
        \ ['ANALYSIS:', 'clus = x;', 'CLUS = X;'],
        \ ['VARIABLE:', 'dist = x;', 'DIST = X;'],
        \ ['PLOT:', 'clas = x;', 'CLAS = X;'],
        \ ['OUTPUT:', 'esti miss star;', 'ESTI MISS STAR;'],
        \ ['DATA:', 'anal = x;', 'ANAL = X;'],
        \ ['MODEL:', 'esti BY y1-y3;', 'ESTI BY Y1-Y3;']]
        call assert_equal(l:expected, s:Statement(l:header, l:statement),
            \ l:header . ' ' . l:statement)
    endfor
endfunction

function! Test_section_is_read_from_above_a_range() abort
    enew!
    call setline(1, ['ANALYSIS:', '    esti = ml;', 'SAVEDATA:', '    esti = e.dat;'])
    set filetype=mplus-inp
    4normal gqq
    call assert_equal('    ESTIMATES = e.dat;', getline(4))
    2normal gqq
    call assert_equal('    ESTIMATOR = ML;', getline(2))
endfunction

function! Test_whole_input() abort
    call assert_equal([
        \ 'TITLE:',
        \ '    this is kept as written',
        \ 'DATA:',
        \ '    FILE = ex.dat;',
        \ 'VARIABLE:',
        \ '    NAMES = Y1-Y4 CLUS;',
        \ '    CLUSTER = CLUS;',
        \ 'ANALYSIS:',
        \ '    TYPE = COMPLEX; ESTIMATOR = MLR;',
        \ 'MODEL:',
        \ '    F BY Y1-Y4;',
        \ 'OUTPUT:',
        \ '    SAMPSTAT TECH1;',
        \ 'SAVEDATA:',
        \ '    FILE = out.dat; ESTIMATES = est.dat;'],
        \ s:Format([
        \ 'title: this is kept as written',
        \ 'data: file is ex.dat;',
        \ 'vari: names are y1-y4 clus;',
        \ "\tclus = clus;",
        \ 'anal: type = complex; esti = mlr;',
        \ 'model: f by y1-y4;',
        \ 'outp: samp tech1;',
        \ 'saved: file = out.dat; esti = est.dat;']))
endfunction

function! Test_examples() abort
    for l:file in ExampleFiles('inp')
        execute 'edit' fnameescape(l:file)
        let v:errmsg = ''
        normal gggqG
        let l:once = getline(1, '$')
        normal gggqG
        call assert_equal(l:once, getline(1, '$'), 'second pass: ' . l:file)
        call assert_equal('', v:errmsg, l:file)
        bwipeout!
    endfor
endfunction

call RunTests()
