" Mplus formatting function
" usage: setlocal formatexpr=mplus#format#Format()

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

    " Section header keywords
    let l:hdr_re = '\%(TITLE\|DATA\|VARIABLE\|DEFINE\|ANALYSIS\|MODEL\|OUTPUT\|SAVEDATA\|PLOT\|MONTECARLO\)'

    " Abbreviation dictionary: abbreviated form -> full keyword
    " Only unambiguous 4+ char abbreviations; dangerous/identity entries removed
    let l:abbrevs = {
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

    " Track whether we're inside a TITLE section
    let l:in_title = 0

    let l:lnum = l:start
    while l:lnum <= l:end
        let l:line = getline(l:lnum)

        " Detect section headers (including compound: MODEL INDIRECT:, DATA IMPUTATION:, etc.)
        let l:is_header = (l:line =~? '^\s*' . l:hdr_re . '\%(\s\+\w\+\)\?\s*:')
        if l:is_header
            let l:in_title = (l:line =~? '^\s*TITLE\s*:')
        endif

        " TITLE body lines: whitespace cleanup only (preserve free-form text)
        if l:in_title && !l:is_header
            let l:line = substitute(l:line, '\t', '    ', 'g')
            let l:line = substitute(l:line, '\s\+$', '', '')
            call setline(l:lnum, l:line)
            let l:lnum += 1
            continue
        endif

        " Comment lines: whitespace cleanup only
        if l:line =~? '^\s*!'
            let l:line = substitute(l:line, '\t', '    ', 'g')
            let l:line = substitute(l:line, '\s\+$', '', '')
            call setline(l:lnum, l:line)
            let l:lnum += 1
            continue
        endif

        " Whitespace cleanup
        let l:line = substitute(l:line, '\t', '    ', 'g')
        let l:line = substitute(l:line, '\s\+$', '', '')

        " Header splitting: "HEADER: content" -> "HEADER:\n  content"
        " Also handles compound headers: "MODEL INDIRECT: content"
        let l:m = matchlist(l:line,
            \ '^\s*\(' . l:hdr_re . '\%(\s\+\w\+\)\?\)\s*:\s*\(.\+\)')
        if !empty(l:m)
            call setline(l:lnum, toupper(l:m[1]) . ':')
            call append(l:lnum, '  ' . l:m[2])
            let l:end += 1
            let l:lnum += 1
            continue
        endif

        " Split line into code part and comment part (! starts EOL comment)
        let l:code = l:line
        let l:comment = ''
        let l:idx = stridx(l:line, '!')
        if l:idx != -1
            let l:code = strpart(l:line, 0, l:idx)
            let l:comment = strpart(l:line, l:idx)
        endif

        " Uppercase the code part (Mplus is case-insensitive; standard style)
        let l:code = toupper(l:code)

        " Replace IS/ARE with = (these are Mplus aliases for =)
        let l:code = substitute(l:code, '\C\<\(IS\|ARE\)\>', '=', 'g')

        " Expand abbreviations (iterate dict; no \= expression needed)
        for [l:abbr, l:full] in items(l:abbrevs)
            let l:code = substitute(l:code, '\C\<' . l:abbr . '\>', l:full, 'g')
        endfor

        call setline(l:lnum, l:code . l:comment)
        let l:lnum += 1
    endwhile

    " Re-indent the range using indentexpr
    execute l:start . ',' . l:end . 'normal! =='

    return 0
endfunction
