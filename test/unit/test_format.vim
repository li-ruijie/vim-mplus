" Tests for the gq formatter.

source <sfile>:p:h/common.vim
source <sfile>:p:h/tokens.vim

let s:inputs = expand('<sfile>:p:h:h') . '/inputs/'

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
        \ ['OUTPUT:', 'samp res mod cint;', 'SAMPSTAT RESIDUAL MODINDICES CINTERVAL;'],
        \ ['OUTPUT:', 'cint (boot) stdyx (clus);', 'CINTERVAL (BOOTSTRAP) STDYX (CLUSTER);'],
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

function! Test_four_letters_that_start_two_options() abort
    " Mplus reads INTE as INTEGRATION and takes INTERACTIVE, which names a
    " file, from five letters on. PARA is PARAMETERIZATION, although
    " PARALLEL starts with the same letters.
    for [l:header, l:statement, l:expected] in [
        \ ['ANALYSIS:', 'inte = 15;', 'INTEGRATION = 15;'],
        \ ['ANALYSIS:', 'integ = montecarlo;', 'INTEGRATION = MONTECARLO;'],
        \ ['ANALYSIS:', 'inter = Control.dat;', 'INTERACTIVE = Control.dat;'],
        \ ['ANALYSIS:', 'interactive = Control.dat;', 'INTERACTIVE = Control.dat;'],
        \ ['ANALYSIS:', 'para = theta;', 'PARAMETERIZATION = THETA;'],
        \ ['ANALYSIS:', 'paral = 50;', 'PARAL = 50;'],
        \ ['ANALYSIS:', 'info = expected;', 'INFORMATION = EXPECTED;'],
        \ ['DATA:', 'list = on;', 'LISTWISE = ON;'],
        \ ['VARIABLE:', 'with = x;', 'WITHIN = X;'],
        \ ['MONTECARLO:', 'with = x;', 'WITHIN = X;'],
        \ ['VARIABLE:', 'cent = grandmean (x);', 'CENTERING = GRANDMEAN (X);']]
        call assert_equal(l:expected, s:Statement(l:header, l:statement),
            \ l:header . ' ' . l:statement)
    endfor
endfunction

function! Test_output_option_has_one_short_form() abort
    " Mplus takes an OUTPUT option in full or in one short form, and it
    " rejects every other shortening. A rejected word is not written as an
    " option that Mplus accepts.
    call assert_equal('RESI MODI CINTE SAMPS;', s:Statement('OUTPUT:', 'resi modi cinte samps;'))
    call assert_equal('CINTERVAL (BOOTS) CROSSTABS (COUN);',
        \ s:Statement('OUTPUT:', 'cinterval (boots) crosstabs (coun);'))
endfunction

function! Test_file_option_depends_on_the_section() abort
    " A file name keeps its spelling. The same option name takes a file in
    " one section and a setting, a number, or variable names in another.
    for [l:header, l:statement, l:expected] in [
        \ ['SAVEDATA:', 'basehazard = Base.dat;', 'BASEHAZARD = Base.dat;'],
        \ ['ANALYSIS:', 'basehazard = on;', 'BASEHAZARD = ON;'],
        \ ['MONTECARLO:', 'coverage = Cov.dat;', 'COVERAGE = Cov.dat;'],
        \ ['ANALYSIS:', 'coverage = .1e-1;', 'COVERAGE = .1E-1;'],
        \ ['MONTECARLO:', 'save = Rep*.dat;', 'SAVE = Rep*.dat;'],
        \ ['DATA IMPUTATION:', 'save = Imp*.dat;', 'SAVE = Imp*.dat;'],
        \ ['SAVEDATA:', 'save = fscores;', 'SAVE = FSCORES;'],
        \ ['SAVEDATA:', 'lresponses = u1 u2;', 'LRESPONSES = U1 U2;'],
        \ ['SAVEDATA:', 'resu are Res.dat;', 'RESU = Res.dat;'],
        \ ['MONTECARLO:', 'results = Res.dat;', 'RESULTS = Res.dat;'],
        \ ['DATA:', 'file is Data.dat;', 'FILE = Data.dat;'],
        \ ['DATA:', 'swmatrix = Sw.dat;', 'SWMATRIX = Sw.dat;'],
        \ ['SAVEDATA:', 'swmatrix = Sw.dat;', 'SWMATRIX = Sw.dat;'],
        \ ['SAVEDATA:', 'h5results = Res.h5;', 'H5RESULTS = Res.h5;'],
        \ ['ANALYSIS:', 'difftest = Deriv.dat;', 'DIFFTEST = Deriv.dat;'],
        \ ['ANALYSIS:', 'mult = Mult.dat;', 'MULT = Mult.dat;'],
        \ ['MONTECARLO:', 'population = Pop.dat;', 'POPULATION = Pop.dat;'],
        \ ['MONTECARLO:', 'star = Start.dat;', 'STARTING = Start.dat;'],
        \ ['MONTECARLO:', 'repsave = all;', 'REPSAVE = ALL;'],
        \ ['VARIABLE:', 'names are y1 Results;', 'NAMES = Y1 RESULTS;']]
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

function! Test_title_ends_at_a_header() abort
    " Mplus ends a title at a command name, alone or with one more word,
    " and a colon. A semicolon does not end a title, and neither does a
    " colon after anything else.
    call assert_equal([
        \ 'TITLE:',
        \ '    a study of growth; in two parts',
        \ '    Step 2: titles: more text',
        \ '    the model: two groups',
        \ '    model with covariates: two groups',
        \ '    models: two groups',
        \ '    tit: x',
        \ 'MODEL COMPARISON:',
        \ '    TWO GROUPS;',
        \ 'DATA:',
        \ '    FILE = x.dat;'],
        \ s:Format([
        \ 'TITLE: a study of growth; in two parts',
        \ 'Step 2: titles: more text',
        \ '  the model: two groups',
        \ '  model with covariates: two groups',
        \ 'models: two groups',
        \ 'tit: x',
        \ '  Model comparison: two groups;',
        \ 'data: file is x.dat;']))
endfunction

function! Test_title_ends_at_a_command_name_and_a_colon() abort
    for [l:line, l:header] in [['anal: type = basic;', 'ANALYSIS:'],
        \ ['Analysis : type = basic;', 'ANALYSIS:'],
        \ ['  model: type = basic;', 'MODEL:'],
        \ ['title: type = basic;', 'TITLE:']]
        call assert_equal(l:header, s:Format(['TITLE: first', '  more text', l:line])[3],
            \ l:line)
    endfor
endfunction

function! Test_second_word_that_mplus_reads() abort
    " After MODEL in full any word is read, as a subcommand or as the label
    " of a group or class. After DATA the full name of a subcommand is read.
    call assert_equal([
        \ 'DATA:',
        \ '    FILE = x.dat;',
        \ 'DATA IMPUTATION:',
        \ '    IMPUTE = Y1;',
        \ 'DATA MISSING:',
        \ '    NAMES = Y1;',
        \ 'MODEL:',
        \ '    F BY Y1;',
        \ 'MODEL INDIRECT:',
        \ '    Y IND X;',
        \ 'MODEL CONSTRAINT:',
        \ '    NEW(B);',
        \ 'MODEL MALE:',
        \ '    F BY Y1;'],
        \ s:Format([
        \ 'data: file is x.dat;',
        \ 'data imputation: impu = y1;',
        \ "Data \tMissing : names = y1;",
        \ 'model: f by y1;',
        \ 'model indirect: y ind x;',
        \ '  MODEL  constraint :',
        \ 'new(b);',
        \ 'Model male: f by y1;']))
endfunction

function! Test_header_that_mplus_does_not_read_is_kept() abort
    " Mplus passes over the section under a shortened command name with a
    " second word, under a second word after any command but DATA and
    " MODEL, and under DATA with a shortened subcommand name. It stops at
    " DATA with any other word. Writing MODE INDIRECT: as MODEL INDIRECT:
    " would turn text that Mplus skips into statements that it reads, so
    " the header and the lines below it stay as they are.
    for l:header in ['mode indirect:', 'Mode male:', 'Variable names:',
        \ 'data impu:', 'data notes:', 'title notes:', 'outp x :', 'save y:']
        call assert_equal([
            \ 'MODEL:',
            \ '    F BY Y1;',
            \ l:header . ' y ind x;',
            \ '    esti = ml;',
            \ 'OUTPUT:',
            \ '    TECH1;'],
            \ s:Format([
            \ 'model: f by y1;',
            \ '  ' . l:header . ' y ind x;',
            \ 'esti = ml;',
            \ 'output: tech1;']), l:header)
    endfor
endfunction

function! Test_statement_is_read_from_above_a_range() abort
    " A line that goes on with a statement is formatted as part of it. The
    " name of a file keeps its case, also when gq is used on its line only.
    enew!
    call setline(1, ['DATA:', '    FILE IS', '    Mixed.dat;', '    vari = nocheck;',
        \ 'ANALYSIS:', '    esti', '    = mlr; type =', '    Basic; ! esti = x;',
        \ '    !* inte = 1;', '    esti = y; *!', '    inte = 7;'])
    set filetype=mplus-inp
    3normal gqq
    call assert_equal('    Mixed.dat;', getline(3))
    4normal gqq
    call assert_equal('    VARIANCES = NOCHECK;', getline(4))
    8normal gqq
    call assert_equal('    BASIC; ! esti = x;', getline(8))
    10normal gqq
    call assert_equal('    esti = y; *!', getline(10))
    11normal gqq
    call assert_equal('    INTEGRATION = 7;', getline(11))
    7normal gqq
    call assert_equal('    = MLR; TYPE =', getline(7))
endfunction

function! Test_text_after_a_header_that_looks_like_a_header() abort
    " Mplus takes a command only at the start of a line. Text after the
    " colon of a header is title text or code, also when it would be a
    " header on a line of its own, so it stays on the line of its header.
    call assert_equal([
        \ 'TITLE:    Model comparison: two groups',
        \ 'DATA:',
        \ '    FILE = x.dat;'],
        \ s:Format(["TITLE:\tModel comparison: two groups", 'data: file is x.dat;']))
    call assert_equal([
        \ 'title: Data notes: collected in 2020',
        \ '    and a second line',
        \ 'DATA:'],
        \ s:Format(['title: Data notes: collected in 2020', 'and a second line', 'DATA:']))
    call assert_equal([
        \ 'TITLE: anal: x',
        \ 'MODEL: MODEL: y ON x1',
        \ '    X3;',
        \ 'OUTPUT:',
        \ '    TECH1;'],
        \ s:Format(['TITLE: anal: x', 'MODEL: MODEL: y ON x1', 'x3;', 'output: tech1;']))
    " Text that is no header on its own line moves down as before.
    call assert_equal([
        \ 'TITLE:',
        \ '    this is a test of Model comparison: two groups',
        \ 'DATA:'],
        \ s:Format(['TITLE: this is a test of Model comparison: two groups', 'DATA:']))
endfunction

function! Test_code_on_the_header_line_is_read_from_above_a_range() abort
    enew!
    call setline(1, ['DATA: FILE IS', '    Mixed.dat;', 'ANALYSIS: esti', '    = mlr;',
        \ 'TITLE: Model comparison: two groups', '    model x'])
    set filetype=mplus-inp
    2normal gqq
    call assert_equal('    Mixed.dat;', getline(2))
    4normal gqq
    call assert_equal('    = MLR;', getline(4))
    6normal gqq
    call assert_equal('    model x', getline(6))
endfunction

function! Test_header_in_a_block_comment_is_no_header() abort
    " The lines of the comment get the indent of the line above them, as
    " every line does that is no header.
    let l:lines = ['ANALYSIS:', '    !* notes', 'SAVEDATA: no header', '  title: no header *!',
        \ '    esti = ml;']
    call assert_equal(['ANALYSIS:', '    !* notes', '    SAVEDATA: no header',
        \ '    title: no header *!', '    ESTIMATOR = ML;'], s:Format(l:lines))
    " The section of the last line is read from above the comment.
    enew!
    call setline(1, l:lines)
    set filetype=mplus-inp
    5normal gqq
    call assert_equal('  ESTIMATOR = ML;', getline(5))
    call assert_equal(l:lines[0:3], getline(1, 4))
endfunction

function! Test_block_comment_mark_in_a_title() abort
    " Below the TITLE line Mplus takes !* for title text, so the header
    " after it starts a section. On the TITLE line it opens a block comment,
    " and Mplus drops that line, so it stays as written.
    call assert_equal(['TITLE:', '    a title', '    !* text of the title', 'DATA:',
        \ '    FILE = x.dat;', 'MODEL:', '    Y ON X;'],
        \ s:Format(['TITLE: a title', '!* text of the title', 'data: file is x.dat;',
        \ 'model: y on x;']))
    call assert_equal(['TITLE: a title !* a comment', '    data: file = none.dat;', '    *!',
        \ 'DATA:', '    FILE = x.dat;'],
        \ s:Format(['TITLE: a title !* a comment', 'data: file = none.dat;', '*!',
        \ 'data: file = x.dat;']))
endfunction

function! Test_comment_on_the_title_line_is_kept_there() abort
    " Mplus reads a ! on the TITLE line as the start of a comment and prints
    " it as title text on the lines below, so the text stays on its line.
    call assert_equal(['TITLE: a title ! a comment', '    more', 'DATA:'],
        \ s:Format(['TITLE: a title ! a comment', 'more', 'DATA:']))
    call assert_equal(['TITLE:', '    a title', 'DATA:'], s:Format(['TITLE: a title', 'DATA:']))
endfunction

function! Test_block_comment_after_code() abort
    " Mplus opens a block comment at a !* after code or in a ! comment, and
    " drops the line where it stays open. That line and the comment stay as
    " written, and a header in it is no header.
    call assert_equal(['MODEL:', '    y on x; !* a note', '    data: x', '    *!', '    Z ON W;',
        \ '    z on w; ! a !* b', '    output: x *!', 'OUTPUT:', '    TECH1;'],
        \ s:Format(['MODEL:', 'y on x; !* a note', 'data: x', '*!', 'z on w;',
        \ 'z on w; ! a !* b', 'output: x *!', 'output: tech1;']))
    call assert_equal(['MODEL:', '    Y ON X; !* a note *!', 'OUTPUT:', '    TECH1;'],
        \ s:Format(['MODEL:', 'y on x; !* a note *!', 'output: tech1;']))
endfunction

function! Test_header_is_read_from_above_a_range() abort
    enew!
    call setline(1, ['TITLE: a study', '  step 2: twenty sets', '  impu = y1;',
        \ 'DATA:', '  file is x.dat;', 'DATA IMPUTATION:', '  impu = y1;',
        \ 'data impu:', '  impu = y1;', 'MODEL male:', '  f by y1;'])
    set filetype=mplus-inp
    11normal gqq
    call assert_equal('    F BY Y1;', getline(11))
    9normal gqq
    call assert_equal('    impu = y1;', getline(9))
    7normal gqq
    call assert_equal('    IMPUTE = Y1;', getline(7))
    3normal gqq
    call assert_equal('  impu = y1;', getline(3))
    2normal gqq
    call assert_equal('    step 2: twenty sets', getline(2))
    call assert_equal(11, line('$'))
endfunction

" Return the words of a:lines in one string, without regard to case.
function! s:Words(lines) abort
    return toupper(join(split(join(a:lines)), ' '))
endfunction

function! Test_line_that_formatting_makes_too_long_is_broken() abort
    " Mplus reads 90 characters of a line. These lines have 90 or fewer
    " with their tabs, and more once the indent is four spaces and the
    " abbreviation is written in full.
    let l:names = "\t\tuseo = " . join(map(range(1, 7), '"x" . v:val . " eq 1"'), ' or ') . '; ! c'
    let l:model = "\tf BY " . join(map(range(101, 116), '"y" . v:val')) . ' yy;'
    call assert_true(strlen(l:names) <= 90 && strlen(l:model) <= 90)
    let l:lines = s:Format(['VARIABLE:', l:names, 'MODEL:', l:model])
    call assert_equal(6, len(l:lines))
    call assert_equal([], filter(copy(l:lines), 'strlen(v:val) > 90'))
    call assert_equal(s:Words(['VARIABLE:', substitute(l:names, 'useo', 'USEOBSERVATIONS', ''),
        \ 'MODEL:', l:model]), s:Words(l:lines))
    call assert_match('^    USEOBSERVATIONS = X1 EQ 1 OR ', l:lines[1])
    call assert_match('^    \S.*; ! c$', l:lines[2])
    call assert_match('^    F BY Y101 .* Y11\d$', l:lines[4])
    call assert_match('^    \S*YY;$', l:lines[5])
endfunction

function! Test_title_line_that_is_too_long_is_broken() abort
    let l:text = join(map(range(1, 24), '"word" . v:val'))
    let l:lines = s:Format(['TITLE: ' . l:text, 'DATA:', '  FILE = x.dat;'])
    call assert_equal(5, len(l:lines))
    call assert_equal([], filter(copy(l:lines), 'strlen(v:val) > 90'))
    call assert_equal('TITLE: ' . toupper(l:text) . ' DATA: FILE = X.DAT;', s:Words(l:lines))
    " No break makes a command or a comment of the text that follows it.
    let l:start = repeat('t', 80)
    for l:tail in ['the model: two groups compared', 'yes ! and no', 'a data set: one more']
        let l:lines = s:Format(['TITLE:', l:start . ' ' . l:tail, 'DATA:'])
        call assert_equal(4, len(l:lines), l:tail)
        call assert_equal([], mplus#section#Parse(l:lines[2]), l:tail)
        call assert_notmatch('^\s*!', l:lines[2], l:tail)
        call assert_equal(toupper('TITLE: ' . l:start . ' ' . l:tail . ' DATA:'), s:Words(l:lines))
    endfor
endfunction

function! Test_tab_in_title_text() abort
    " Mplus 9.1.1 prints a tab in the text of a title as one space and does
    " not print the indent, so the title that it prints stays the same. A
    " comment line is not printed, and code keeps four spaces for a tab.
    call assert_equal([
        \ 'TITLE:',
        \ '    a b  c',
        \ '    where attrition is predicted by time-',
        \ '    ! a    note',
        \ 'MODEL:',
        \ '    F BY Y1    Y2;'],
        \ s:Format(["TITLE:\ta\tb  c", "\twhere attrition is\tpredicted by time-\t",
        \ "\t! a\tnote", 'MODEL:', "\tf by y1\ty2;"]))
    call assert_equal(['TITLE:', '    first line', '    a b', 'DATA:'],
        \ s:Format(["TITLE: first line", "a\tb", 'DATA:']))
    call assert_equal(['TITLE:    Model comparison: two groups', '    a b', 'DATA:'],
        \ s:Format(["TITLE:\tModel comparison:\ttwo groups", "a\tb", 'DATA:']))
endfunction

function! Test_long_line_that_is_not_broken() abort
    " A comment loses nothing that Mplus reads, a quoted string has to
    " stay whole, and a section that Mplus passes over stays as written.
    let l:long = repeat('c', 95)
    for l:lines in [
        \ ['MODEL:', '    ! ' . l:long . ' and more'],
        \ ['MODEL:', '    F BY Y1; ! ' . l:long . ' and more'],
        \ ['MODEL:', '    !* ' . l:long . ' and more', '    *!'],
        \ ['mode indirect:', '    ' . l:long . ' and more;'],
        \ ['MODEL:', '    ' . toupper(l:long) . ';']]
        call assert_equal(l:lines, s:Format(l:lines))
    endfor
    " The break comes before a string that does not fit.
    call assert_equal(['DATA:', '    FILE =', '    "' . repeat('c', 80) . ' and more.dat";'],
        \ s:Format(['DATA:', '    FILE = "' . repeat('c', 80) . ' and more.dat";']))
endfunction

function! Test_break_in_a_file_name_with_spaces() abort
    " Mplus 9.1.1 reads a file name with spaces that is not quoted. It takes
    " the white space between two words of the name as one space, also when
    " that white space is a line break, so a break at a space leaves the
    " name as it was. A quoted name is never broken, since Mplus joins the
    " two parts of a quoted name without a space.
    let l:name = strpart('a data file ' . repeat('with a long name ', 4), 0, 73) . 'End.dat'
    let l:lines = s:Format(['DATA:', "\t\tFILE = " . l:name . ';', 'SAVEDATA:',
        \ "\t\tFILE = " . l:name . ';'])
    call assert_equal(6, len(l:lines))
    call assert_equal([], filter(copy(l:lines), 'strlen(v:val) > 90'))
    call assert_equal('FILE = ' . l:name . ';', join(split(join(l:lines[1:2])), ' '))
    call assert_equal('FILE = ' . l:name . ';', join(split(join(l:lines[4:5])), ' '))
    call assert_equal(['DATA:', '    FILE =', '    "' . l:name . '";'],
        \ s:Format(['DATA:', "\t\tFILE = \"" . l:name . '";']))
endfunction

function! Test_indent_after_a_do_statement() abort
    " DO (1, 6) expression; is one statement. The line after it belongs to
    " the section and has the indent of the DO line.
    call assert_equal([
        \ 'MODEL PRIORS:',
        \ '    DO(1,6) DIFF(LAM1_#-LAM10_#)~N(0,0.01);',
        \ '    DO(1,6) DIFF(NU1_#-NU10_#)~N(0,0.01); ! a note',
        \ '    DO ($,1,2) DO (#,1,4) S$_# ~ N (0,0.1);',
        \ '    F1 WITH F2;',
        \ 'OUTPUT:',
        \ '    TECH1;'],
        \ s:Format([
        \ 'MODEL PRIORS:',
        \ '  DO(1,6) DIFF(lam1_#-lam10_#)~N(0,0.01);',
        \ '  DO(1,6) DIFF(nu1_#-nu10_#)~N(0,0.01); ! a note',
        \ '  DO ($,1,2) DO (#,1,4) s$_# ~ N (0,0.1);',
        \ '  f1 WITH f2;',
        \ 'output: tech1;']))
    " A DO statement that goes on has its next line one level deeper.
    call assert_equal([
        \ 'MODEL CONSTRAINT:',
        \ '    DO (1, 3) 0 = ! not the end; of the statement',
        \ '        P# - Q#;'],
        \ s:Format([
        \ 'MODEL CONSTRAINT:',
        \ 'DO (1, 3) 0 = ! not the end; of the statement',
        \ 'p# - q#;']))
endfunction

function! Test_indent_of_a_do_statement_over_lines() abort
    " A DO statement ends with the semicolon of its expression, on whatever
    " line that stands, and the loop takes no statement after it. The lines
    " that go on with it are one level deeper, and the line after it has the
    " indent of the line where it started, also below a DO inside a DO.
    " Mplus 9.1.1 stops with an error at END DO in DEFINE, MODEL, MODEL
    " CONSTRAINT, MODEL TEST, and MODEL PRIORS, so such a line is indented
    " as any other line is.
    call assert_equal([
        \ 'MODEL CONSTRAINT:',
        \ '    NEW(Q1 Q2 R);',
        \ '    DO (1, 2)',
        \ '        Q# = P# *',
        \ '        2;',
        \ '    R = Q1 + Q2;',
        \ '    DO ($, 1, 2)',
        \ '        DO (#, 1, 2) 0 = A$ - B#;',
        \ '    S = 1;',
        \ '    DO ($, 1, 2)',
        \ '        ! a note; with a semicolon',
        \ '        DO (#, 1, 2)',
        \ '            0 = A$ - B#; ! the end',
        \ '    T = 1;',
        \ '    END DO;',
        \ '    U = 1;',
        \ 'OUTPUT:',
        \ '    TECH1;'],
        \ s:Format([
        \ 'MODEL CONSTRAINT:',
        \ 'NEW(q1 q2 r);',
        \ 'DO (1, 2)',
        \ 'q# = p# *',
        \ '2;',
        \ 'r = q1 + q2;',
        \ 'DO ($, 1, 2)',
        \ 'DO (#, 1, 2) 0 = a$ - b#;',
        \ 's = 1;',
        \ 'DO ($, 1, 2)',
        \ '! a note; with a semicolon',
        \ 'DO (#, 1, 2)',
        \ '0 = a$ - b#; ! the end',
        \ 't = 1;',
        \ 'END DO;',
        \ 'u = 1;',
        \ 'output: tech1;']))
    " The indent of the line below is that of the DO line, whatever it is.
    enew!
    call setline(1, ['DEFINE:', '        DO (1, 3)', '            d# = y# - x#;', 'e = 1;',
        \ '  x = 1; y = 2;', '        z = 3;'])
    set filetype=mplus-inp
    4normal! ==
    6normal! ==
    call assert_equal('        e = 1;', getline(4))
    call assert_equal('  z = 3;', getline(6))
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

" Check that gq changes nothing that Mplus reads in the input a:written,
" which it formats as a:formatted. A note tells what Mplus drops from a line
" of a:written that is too long.
function! s:SameTokens(name, written, formatted) abort
    let [l:difference, l:note] = MplusTokenCheck(a:written, a:formatted)
    call assert_equal('', l:difference, 'tokens: ' . a:name)
    if l:note !=# ''
        call add(g:test_notes, 'NOTE: ' . fnamemodify(a:name, ':t') . ': ' . l:note)
    endif
endfunction

function! Test_examples() abort
    for l:file in ExampleFiles('inp')
        execute 'edit' fnameescape(l:file)
        let l:written = getline(1, '$')
        let v:errmsg = ''
        normal gggqG
        let l:once = getline(1, '$')
        call s:SameTokens(l:file, l:written, l:once)
        normal gggqG
        call assert_equal(l:once, getline(1, '$'), 'second pass: ' . l:file)
        call assert_equal('', v:errmsg, l:file)
        bwipeout!
    endfor
endfunction

function! Test_inputs_keep_their_tokens() abort
    let l:files = glob(s:inputs . '*.inp', 1, 1)
    call assert_true(len(l:files) >= 5)
    for l:file in l:files
        execute 'edit' fnameescape(l:file)
        let l:written = getline(1, '$')
        normal gggqG
        call s:SameTokens(l:file, l:written, getline(1, '$'))
        bwipeout!
    endfor
endfunction

" Return the tokens of the input a:lines as Mplus reads it, each as kind and
" text, with the lines cut to a:1 characters (90 by default).
function! s:Tokens(lines, ...) abort
    return map(MplusTokens(a:lines, a:0 ? a:1 : 90), 'v:val[0] . ":" . v:val[1]')
endfunction

function! Test_tokens_as_mplus_reads_them() abort
    " Each case is a rule that runs of mplus.exe 9.1.1 showed, as told in
    " tokens.vim. Mplus reads 90 characters of a line, a tab counted as one.
    let l:long = "MODEL:\t y ON x;" . repeat(' ', 76) . 'z;'
    call assert_equal(['H:MODEL', 'C:Y', 'C:ON', 'C:X', ';:;'], s:Tokens([l:long]))
    call assert_equal(['H:MODEL', 'C:Y', 'C:ON', 'C:X', ';:;', 'C:Z', ';:;'], s:Tokens([l:long], 0))
    " Block comments open anywhere, also in a ! comment, and nest. A line on
    " which one opens and stays open is dropped whole, the text after *! is
    " read, and the text before a block comment on its line loses its
    " trailing white space. *! with none open is a * and a comment.
    call assert_equal(['H:MODEL', 'C:D', 'C:ON', 'C:E', ';:;', 'C:FH', ';:;', 'C:J', ';:;', 'C:*'],
        \ s:Tokens(['MODEL:', 'y ON x; !* a', 'b ON c;', '*! d ON e;', 'f !* g *!h;',
        \ '!* outer', '!* inner', '*!', 'i;', '*!', 'j; *! k', 'l; ! m !* n', 'o;', '*!']))
    " ! starts a comment also inside a word or a quoted string.
    call assert_equal(['H:VARIABLE', 'K:NAMES', 'C:=', 'C:Y', 'C:X', 'H:DATA', 'K:FILE', 'C:=',
        \ 'Q:a'], s:Tokens(['VARIABLE: NAMES = y x!zzz;', 'DATA: FILE = "a!b.dat";']))
    " Below the TITLE line only a line that starts with a ! with no * after
    " it is a comment. Mplus prints the other lines without indent, with a
    " tab as one space. The TITLE line is read as code is.
    call assert_equal(['H:TITLE', 'T:first', 'T:second ! kept', 'T:third line', 'T:!* kept',
        \ 'H:DATA', 'K:FILE', 'C:=', 'F:x.dat', ';:;', 'K:*'],
        \ s:Tokens(['TITLE: first ! a comment', '! a comment', '!x a comment',
        \ '  second ! kept', "third\tline", '!* kept', '', 'DATA: FILE = x.dat; *!']))
    " A block comment that opens on the TITLE line drops the line, and a
    " header in it starts nothing.
    call assert_equal(['H:DATA', 'K:FILE', 'C:=', 'F:d.dat', ';:;'],
        \ s:Tokens(['TITLE: a !* b', 'DATA: FILE = n.dat;', '*!', 'DATA: FILE = d.dat;']))
    " A quoted string keeps its case, a run of spaces in it is one space, it
    " goes on over a line break without the white space there, and it ends
    " at a semicolon. A file name keeps its case.
    call assert_equal(['H:DATA', 'K:FILE', 'C:=', 'Q:DaTa.dat', ';:;', 'H:SAVEDATA', 'K:FILE',
        \ 'C:=', 'Q:a b.dat', ';:;', 'K:RESULTS', 'C:=', 'Q:c', ';:;', 'K:D.DAT', 'Q:', ';:;'],
        \ s:Tokens(['DATA: FILE = "Da   ', "   Ta.dat\";", 'SAVEDATA: FILE = "a  b.dat";',
        \ 'RESULTS = "c;d.dat";']))
    call assert_equal(['H:DATA', 'K:FILE', 'C:=', 'F:Mixed', 'F:Name.Dat', ';:;'],
        \ s:Tokens(['data: file is Mixed', '  Name.Dat;']))
    " IS after an option name is the connector, and a name elsewhere.
    call assert_equal(['H:VARIABLE', 'K:NAMES', 'C:=', 'C:Y', 'C:IS', ';:;', 'H:MODEL', 'C:Y',
        \ 'C:ON', 'C:IS', ';:;'], s:Tokens(['VARIABLE: NAMES ARE y is;', 'MODEL: y ON is;']))
    " Mplus does not read a section that it passes over.
    call assert_equal(['X:MODEL INDIRECT', 'H:OUTPUT', 'K:SAMP', ';:;'],
        \ s:Tokens(['mode indirect: y ind x;', 'esti = ml;', 'OUTPUT: samp;']))
endfunction

function! Test_token_difference() abort
    " An option name and a word of OUTPUT may be written in full.
    call assert_equal('', MplusTokenDifference(MplusTokens(['anal: esti = ml;', 'outp: cint(boot);'], 90),
        \ MplusTokens(['ANALYSIS:', '    ESTIMATOR = ML;', 'OUTPUT:', '    CINTERVAL(BOOTSTRAP);'], 90), 0))
    for [l:written, l:formatted] in [
        \ [['MODEL: esti BY y1;'], ['MODEL:', '    ESTIMATOR BY Y1;']],
        \ [['DATA: FILE = ex.dat;'], ['DATA:', '    FILE = EX.DAT;']],
        \ [['TITLE: Two groups', 'DATA:'], ['TITLE:', '    TWO GROUPS', 'DATA:']],
        \ [['DATA: FILE = "a b.dat";'], ['DATA: FILE = "a', 'b.dat";']],
        \ [['MODEL: y ON x;'], ['MODEL: y ON x']]]
        call assert_notequal('', MplusTokenDifference(MplusTokens(l:written, 90),
            \ MplusTokens(l:formatted, 90), 0), string(l:formatted))
    endfor
    " A line of title text that is too long may be broken at white space
    " when it is compared with the written line read whole.
    let l:title = ['TITLE: ' . repeat('word ', 20) . 'end', 'DATA:']
    let l:broken = ['TITLE:', '    ' . repeat('word ', 16) . 'word', '    word word word end', 'DATA:']
    call assert_equal('', MplusTokenDifference(MplusTokens(l:title, 0), MplusTokens(l:broken, 90), 1))
    call assert_notequal('', MplusTokenDifference(MplusTokens(l:title, 90), MplusTokens(l:broken, 90), 0))
    call assert_equal(['', ''], MplusTokenCheck(['MODEL: y ON x;'], ['MODEL:', '    Y ON X;']))
    let [l:difference, l:note] = MplusTokenCheck(l:title, l:broken)
    call assert_equal('', l:difference)
    call assert_match("^as written, Mplus drops line 1 'd word word word end'", l:note)
endfunction

call RunTests()
