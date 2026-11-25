" Mplus formatting function
" usage: setlocal formatexpr=mplus#format#Format()

" Abbreviation dictionary: abbreviated form -> full keyword
" Only unambiguous 4+ char abbreviations; dangerous/identity entries removed
let s:abbrevs = {
    \ 'ANAL': 'ANALYSIS', 'ANALY': 'ANALYSIS', 'ANALYS': 'ANALYSIS',
    \ 'VARI': 'VARIABLE', 'VARIA': 'VARIABLE', 'VARIAB': 'VARIABLE', 'VARIABL': 'VARIABLE',
    \ 'DEFI': 'DEFINE', 'DEFIN': 'DEFINE',
    \ 'OUTP': 'OUTPUT', 'OUTPU': 'OUTPUT',
    \ 'SAVED': 'SAVEDATA', 'SAVEDA': 'SAVEDATA', 'SAVEDAT': 'SAVEDATA',
    \ 'MONT': 'MONTECARLO', 'MONTE': 'MONTECARLO', 'MONTEC': 'MONTECARLO',
    \ 'MONTECA': 'MONTECARLO', 'MONTECAR': 'MONTECARLO', 'MONTECARL': 'MONTECARLO',
    \ 'TITL': 'TITLE',
    \ 'ESTI': 'ESTIMATOR', 'ESTIM': 'ESTIMATOR', 'ESTIMA': 'ESTIMATOR',
    \ 'ESTIMAT': 'ESTIMATOR', 'ESTIMATO': 'ESTIMATOR',
    \ 'DIST': 'DISTRIBUTION', 'DISTR': 'DISTRIBUTION', 'DISTRI': 'DISTRIBUTION',
    \ 'DISTRIB': 'DISTRIBUTION', 'DISTRIBU': 'DISTRIBUTION', 'DISTRIBUT': 'DISTRIBUTION',
    \ 'DISTRIBUTI': 'DISTRIBUTION', 'DISTRIBUTIO': 'DISTRIBUTION',
    \ 'PARAM': 'PARAMETERIZATION', 'PARAME': 'PARAMETERIZATION',
    \ 'PARAMET': 'PARAMETERIZATION', 'PARAMETE': 'PARAMETERIZATION',
    \ 'PARAMETER': 'PARAMETERIZATION', 'PARAMETERI': 'PARAMETERIZATION',
    \ 'PARAMETERIZ': 'PARAMETERIZATION', 'PARAMETERIZA': 'PARAMETERIZATION',
    \ 'PARAMETERIZAT': 'PARAMETERIZATION', 'PARAMETERIZATI': 'PARAMETERIZATION',
    \ 'PARAMETERIZATIO': 'PARAMETERIZATION',
    \ 'ALGO': 'ALGORITHM', 'ALGOR': 'ALGORITHM', 'ALGORI': 'ALGORITHM',
    \ 'ALGORIT': 'ALGORITHM', 'ALGORITH': 'ALGORITHM',
    \ 'INTE': 'INTEGRATION', 'INTEG': 'INTEGRATION', 'INTEGR': 'INTEGRATION',
    \ 'INTEGRA': 'INTEGRATION', 'INTEGRAT': 'INTEGRATION',
    \ 'INTEGRATI': 'INTEGRATION', 'INTEGRATIO': 'INTEGRATION',
    \ 'ITER': 'ITERATIONS', 'ITERA': 'ITERATIONS', 'ITERAT': 'ITERATIONS',
    \ 'ITERATI': 'ITERATIONS', 'ITERATIO': 'ITERATIONS', 'ITERATION': 'ITERATIONS',
    \ 'CONV': 'CONVERGENCE', 'CONVE': 'CONVERGENCE', 'CONVER': 'CONVERGENCE',
    \ 'CONVERG': 'CONVERGENCE', 'CONVERGE': 'CONVERGENCE',
    \ 'CONVERGEN': 'CONVERGENCE', 'CONVERGENC': 'CONVERGENCE',
    \ 'BOOT': 'BOOTSTRAP', 'BOOTS': 'BOOTSTRAP', 'BOOTST': 'BOOTSTRAP',
    \ 'BOOTSTR': 'BOOTSTRAP', 'BOOTSTRA': 'BOOTSTRAP',
    \ 'PROC': 'PROCESSORS', 'PROCE': 'PROCESSORS', 'PROCES': 'PROCESSORS',
    \ 'PROCESS': 'PROCESSORS', 'PROCESSO': 'PROCESSORS', 'PROCESSOR': 'PROCESSORS',
    \ 'STAR': 'STARTS', 'START': 'STARTS',
    \ 'ADAP': 'ADAPTIVE', 'ADAPT': 'ADAPTIVE', 'ADAPTI': 'ADAPTIVE',
    \ 'ADAPTIV': 'ADAPTIVE',
    \ 'INFOR': 'INFORMATION', 'INFORM': 'INFORMATION', 'INFORMA': 'INFORMATION',
    \ 'INFORMAT': 'INFORMATION', 'INFORMATI': 'INFORMATION',
    \ 'INFORMATIO': 'INFORMATION',
    \ 'BITE': 'BITERATIONS', 'BITER': 'BITERATIONS', 'BITERA': 'BITERATIONS',
    \ 'BITERAT': 'BITERATIONS', 'BITERATI': 'BITERATIONS',
    \ 'BITERATIO': 'BITERATIONS', 'BITERATION': 'BITERATIONS',
    \ 'CHAI': 'CHAINS', 'CHAIN': 'CHAINS',
    \ 'USEV': 'USEVARIABLES', 'USEVA': 'USEVARIABLES',
    \ 'USEVAR': 'USEVARIABLES', 'USEVARI': 'USEVARIABLES',
    \ 'USEVARIA': 'USEVARIABLES', 'USEVARIAB': 'USEVARIABLES',
    \ 'USEVARIABL': 'USEVARIABLES', 'USEVARIABLE': 'USEVARIABLES',
    \ 'USEO': 'USEOBSERVATIONS', 'USEOB': 'USEOBSERVATIONS',
    \ 'USEOBS': 'USEOBSERVATIONS', 'USEOBSE': 'USEOBSERVATIONS',
    \ 'USEOBSER': 'USEOBSERVATIONS', 'USEOBSERV': 'USEOBSERVATIONS',
    \ 'USEOBSERVA': 'USEOBSERVATIONS', 'USEOBSERVAT': 'USEOBSERVATIONS',
    \ 'USEOBSERVATI': 'USEOBSERVATIONS', 'USEOBSERVATIO': 'USEOBSERVATIONS',
    \ 'MISS': 'MISSING', 'MISSI': 'MISSING', 'MISSIN': 'MISSING',
    \ 'CENTERI': 'CENTERING', 'CENTERIN': 'CENTERING',
    \ 'CLUS': 'CLUSTER', 'CLUST': 'CLUSTER', 'CLUSTE': 'CLUSTER',
    \ 'STRA': 'STRATIFICATION', 'STRAT': 'STRATIFICATION',
    \ 'STRATI': 'STRATIFICATION', 'STRATIF': 'STRATIFICATION',
    \ 'STRATIFI': 'STRATIFICATION', 'STRATIFIC': 'STRATIFICATION',
    \ 'STRATIFICA': 'STRATIFICATION', 'STRATIFICAT': 'STRATIFICATION',
    \ 'STRATIFICATI': 'STRATIFICATION', 'STRATIFICATIO': 'STRATIFICATION',
    \ 'WEIG': 'WEIGHT', 'WEIGH': 'WEIGHT',
    \ 'IDVA': 'IDVARIABLE', 'IDVAR': 'IDVARIABLE', 'IDVARI': 'IDVARIABLE',
    \ 'IDVARIA': 'IDVARIABLE', 'IDVARIAB': 'IDVARIABLE',
    \ 'IDVARIABL': 'IDVARIABLE',
    \ 'GROU': 'GROUPING', 'GROUP': 'GROUPING', 'GROUPI': 'GROUPING',
    \ 'GROUPIN': 'GROUPING',
    \ 'CENS': 'CENSORED', 'CENSO': 'CENSORED', 'CENSOR': 'CENSORED',
    \ 'CENSORE': 'CENSORED',
    \ 'CATE': 'CATEGORICAL', 'CATEG': 'CATEGORICAL', 'CATEGO': 'CATEGORICAL',
    \ 'CATEGOR': 'CATEGORICAL', 'CATEGORI': 'CATEGORICAL',
    \ 'CATEGORIC': 'CATEGORICAL', 'CATEGORICA': 'CATEGORICAL',
    \ 'NOMI': 'NOMINAL', 'NOMIN': 'NOMINAL', 'NOMINA': 'NOMINAL',
    \ 'COUN': 'COUNT',
    \ 'AUXI': 'AUXILIARY', 'AUXIL': 'AUXILIARY', 'AUXILI': 'AUXILIARY',
    \ 'AUXILIA': 'AUXILIARY', 'AUXILIAR': 'AUXILIARY',
    \ 'CLAS': 'CLASSES', 'CLASS': 'CLASSES', 'CLASSE': 'CLASSES',
    \ 'KNOW': 'KNOWNCLASS', 'KNOWN': 'KNOWNCLASS', 'KNOWNC': 'KNOWNCLASS',
    \ 'KNOWNCL': 'KNOWNCLASS', 'KNOWNCLA': 'KNOWNCLASS',
    \ 'KNOWNCLAS': 'KNOWNCLASS',
    \ 'WITHI': 'WITHIN',
    \ 'BETW': 'BETWEEN', 'BETWE': 'BETWEEN', 'BETWEE': 'BETWEEN',
    \ 'IMPU': 'IMPUTATION', 'IMPUT': 'IMPUTATION', 'IMPUTA': 'IMPUTATION',
    \ 'IMPUTAT': 'IMPUTATION', 'IMPUTATI': 'IMPUTATION',
    \ 'IMPUTATIO': 'IMPUTATION',
    \ 'NOBS': 'NOBSERVATIONS', 'NOBSE': 'NOBSERVATIONS',
    \ 'NOBSER': 'NOBSERVATIONS', 'NOBSERV': 'NOBSERVATIONS',
    \ 'NOBSERVA': 'NOBSERVATIONS', 'NOBSERVAT': 'NOBSERVATIONS',
    \ 'NOBSERVATI': 'NOBSERVATIONS', 'NOBSERVATIO': 'NOBSERVATIONS',
    \ 'NGRO': 'NGROUPS', 'NGROU': 'NGROUPS', 'NGROUP': 'NGROUPS',
    \ 'LISTW': 'LISTWISE', 'LISTWI': 'LISTWISE', 'LISTWIS': 'LISTWISE',
    \ 'SAMP': 'SAMPSTAT', 'SAMPS': 'SAMPSTAT', 'SAMPST': 'SAMPSTAT',
    \ 'SAMPSTA': 'SAMPSTAT',
    \ 'RESI': 'RESIDUAL', 'RESID': 'RESIDUAL', 'RESIDU': 'RESIDUAL',
    \ 'RESIDUA': 'RESIDUAL',
    \ 'MODI': 'MODINDICES', 'MODIN': 'MODINDICES', 'MODIND': 'MODINDICES',
    \ 'MODINDI': 'MODINDICES', 'MODINDIC': 'MODINDICES',
    \ 'MODINDICE': 'MODINDICES',
    \ 'CINTE': 'CINTERVAL', 'CINTER': 'CINTERVAL', 'CINTERV': 'CINTERVAL',
    \ 'CINTERVA': 'CINTERVAL'
\ }

" Section names in full. An input file may shorten each to four letters.
let s:headers = ['TITLE', 'DATA', 'VARIABLE', 'DEFINE', 'ANALYSIS', 'MODEL',
    \ 'OUTPUT', 'SAVEDATA', 'PLOT', 'MONTECARLO']

" Sections whose statements start with an option name. MODEL and DEFINE
" statements start with a variable name, and TITLE holds free text.
let s:option_sections = ['DATA', 'VARIABLE', 'ANALYSIS', 'SAVEDATA', 'PLOT',
    \ 'MONTECARLO']

" Options whose value is a file name, which is kept exactly as written.
let s:file_options = ['FILE', 'SAMPLE', 'COVARIANCE', 'SIGBETWEEN', 'SWMATRIX',
    \ 'RESULTS', 'STDRESULTS', 'STDDISTRIBUTION', 'ESTIMATES', 'DIFFTEST',
    \ 'TECH3', 'TECH4', 'KAPLANMEIER', 'BASEHAZARD', 'ESTBASELINE', 'RESPONSE',
    \ 'MULTIPLIER', 'BPARAMETERS', 'RANKING', 'H5RESULTS', 'MFILE',
    \ 'LRESPONSES', 'POPULATION', 'COVERAGE', 'STARTING']

" Pieces of a code line: a quoted string, a statement end, a comment, or a
" run of anything else.
let s:piece_re = '"[^"]*"\?\|''[^'']*''\?\|;\|!.*$\|[^"'';!]\+'

" Return the full section name that a:word names or abbreviates, or ''.
function! s:HeaderName(word) abort
    let l:word = toupper(a:word)
    for l:name in s:headers
        if l:word ==# l:name || (strlen(l:word) >= 4 && stridx(l:name, l:word) == 0)
            return l:name
        endif
    endfor
    return ''
endfunction

" Parse a:line as a section header. Return [] for any other line, else
" [name, subtype, content], where content is the text after the colon.
function! s:ParseHeader(line) abort
    let l:m = matchlist(a:line, '^\s*\(\a\+\)\%(\s\+\([^: \t]\+\)\)\?\s*:\s*\(.*\)$')
    if empty(l:m)
        return []
    endif
    let l:name = s:HeaderName(l:m[1])
    return l:name ==# '' ? [] : [l:name, toupper(l:m[2]), l:m[3]]
endfunction

" Return whether the value of option a:name is a file name in the section
" described by a:state. An abbreviated name counts when it is a prefix.
function! s:IsFileOption(name, state) abort
    if a:name ==# 'SAVE'
        return a:state.section ==# 'MONTECARLO' || a:state.subtype ==# 'IMPUTATION'
    endif
    for l:option in s:file_options
        if a:name ==# l:option || (strlen(a:name) >= 4 && stridx(l:option, a:name) == 0)
            return 1
        endif
    endfor
    return 0
endfunction

" Return the code part of a:line, without quoted strings and the comment.
function! s:CodeOnly(line) abort
    let l:code = ''
    let l:pos = 0
    while 1
        let [l:piece, l:start, l:pos] = matchstrpos(a:line, s:piece_re, l:pos)
        if l:start < 0 || l:piece[0] ==# '!'
            return l:code
        endif
        let l:code .= l:piece =~# '^["'']' ? '' : l:piece
    endwhile
endfunction

" Describe the text above line a:lnum: the section it belongs to, whether it
" is TITLE text, whether it is inside a block comment, and whether a new
" statement starts on a:lnum.
function! s:StateBefore(lnum) abort
    let l:state = {'section': '', 'subtype': '', 'in_title': 0, 'in_block': 0,
        \ 'at_start': 1, 'verbatim': 0}
    let l:have_code = 0
    let l:have_block = 0
    let l:lnum = a:lnum - 1
    while l:lnum >= 1
        let l:line = getline(l:lnum)
        let l:lnum -= 1
        if !l:have_block && l:line =~# '\*!\|^\s*!\*'
            let l:state.in_block = l:line !~# '\*!'
            let l:have_block = 1
        endif
        if l:line =~# '^\s*\%(!.*\)\?$'
            continue
        endif
        let l:header = s:ParseHeader(l:line)
        if !l:have_code
            let l:state.at_start = !empty(l:header) || s:CodeOnly(l:line) =~# ';\s*$'
            let l:have_code = 1
        endif
        if !empty(l:header)
            let l:state.section = l:header[0]
            let l:state.subtype = l:header[1]
            let l:state.in_title = l:header[0] ==# 'TITLE'
            break
        endif
    endwhile
    return l:state
endfunction

" Format one run of code outside strings and comments. Everything is
" uppercased. An abbreviation is expanded only where Mplus reads a keyword:
" every word of the OUTPUT list, and the option name that starts a statement
" in the sections listed in s:option_sections. Variable names keep their
" spelling, and so does a file name.
function! s:FormatText(text, state) abort
    if a:state.verbatim
        return a:text
    endif
    if a:state.section ==# 'OUTPUT'
        return substitute(toupper(a:text), '\<\a\w*\>',
            \ '\=get(s:abbrevs, submatch(0), submatch(0))', 'g')
    endif
    if a:text !~# '\S'
        return a:text
    endif
    let l:at_start = a:state.at_start
    let a:state.at_start = 0
    if !l:at_start || index(s:option_sections, a:state.section) < 0
        return toupper(a:text)
    endif
    " lead, option name, optional (qualifier), then =, IS, or ARE
    let l:m = matchlist(a:text,
        \ '\c^\(\s*\)\(\a\w*\)\(\s*\%(([^)]*)\s*\)\?\)\%(=\|\<\%(IS\|ARE\)\>\)\(.*\)$')
    if empty(l:m)
        return toupper(a:text)
    endif
    let l:name = toupper(l:m[2])
    let l:name = get(s:abbrevs, l:name, l:name)
    let a:state.verbatim = s:IsFileOption(l:name, a:state)
    return l:m[1] . l:name . toupper(l:m[3]) . '='
        \ . (a:state.verbatim ? l:m[4] : toupper(l:m[4]))
endfunction

" Format one line of code, statement by statement. Quoted strings and the
" trailing comment are copied unchanged.
function! s:FormatCode(line, state) abort
    let l:out = ''
    let l:pos = 0
    while 1
        let [l:piece, l:start, l:pos] = matchstrpos(a:line, s:piece_re, l:pos)
        if l:start < 0
            return l:out
        endif
        if l:piece ==# ';'
            let a:state.at_start = 1
            let a:state.verbatim = 0
            let l:out .= l:piece
        elseif l:piece =~# '^["''!]'
            let l:out .= l:piece
        else
            let l:out .= s:FormatText(l:piece, a:state)
        endif
    endwhile
endfunction

function! mplus#format#Format() abort
    if mode() =~# '[iR]'
        return 1
    endif

    let l:start = v:lnum
    let l:end = v:lnum + v:count - 1

    " Buffer-wide settings
    setlocal tabstop=4 softtabstop=4 shiftwidth=4 expandtab
    setlocal fileencoding=utf-8 nobomb endofline
    setlocal fileformat=unix

    " The range may start anywhere, so take the section, the TITLE and block
    " comment state, and the statement state from the lines above it.
    let l:state = s:StateBefore(l:start)

    let l:lnum = l:start
    while l:lnum <= l:end
        " Whitespace cleanup, on every line
        let l:line = substitute(getline(l:lnum), '\t', '    ', 'g')
        let l:line = substitute(l:line, '\s\+$', '', '')

        " Block comment (!* ... *!): whitespace cleanup only
        if l:state.in_block || l:line =~# '^\s*!\*'
            let l:state.in_block = l:line !~# '\*!'
            call setline(l:lnum, l:line)
            let l:lnum += 1
            continue
        endif

        " Comment line: whitespace cleanup only
        if l:line =~# '^\s*!'
            call setline(l:lnum, l:line)
            let l:lnum += 1
            continue
        endif

        " Section header, also abbreviated (ANAL:) or compound (MODEL
        " INDIRECT:). The name is written in full and any content after
        " the colon moves to a line of its own.
        let l:header = s:ParseHeader(l:line)
        if !empty(l:header)
            let l:state.section = l:header[0]
            let l:state.subtype = l:header[1]
            let l:state.in_title = l:header[0] ==# 'TITLE'
            let l:state.at_start = 1
            let l:state.verbatim = 0
            call setline(l:lnum, l:header[0]
                \ . (l:header[1] ==# '' ? '' : ' ' . l:header[1]) . ':')
            if l:header[2] !=# ''
                call append(l:lnum, '  ' . l:header[2])
                let l:end += 1
            endif
            let l:lnum += 1
            continue
        endif

        " TITLE body: free-form text, kept as written
        call setline(l:lnum, l:state.in_title ? l:line : s:FormatCode(l:line, l:state))
        let l:lnum += 1
    endwhile

    " Re-indent the range using indentexpr
    execute l:start . ',' . l:end . 'normal! =='

    return 0
endfunction
