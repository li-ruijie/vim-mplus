" Mplus formatting function
" usage: setlocal formatexpr=mplus#format#Format()

function! mplus#format#Format() abort
    " Only format for normal mode or visual mode (not insert)
    if mode() =~# '[iR]'
        return 1
    endif

    let l:start = v:lnum
    let l:end = v:lnum + v:count - 1

    " 1. Buffer-wide settings (applied once)
    setlocal tabstop=4 softtabstop=4 shiftwidth=4 expandtab
    setlocal fileencoding=utf-8 nobomb endofline
    setlocal fileformat=unix

    " Abbreviation Dictionary (4+ chars)
    " Generated based on common unambiguous Mplus keywords
    let l:abbrevs = {
        \ 'ANAL': 'ANALYSIS', 'ANALY': 'ANALYSIS', 'ANALYS': 'ANALYSIS',
        \ 'VARI': 'VARIABLE', 'VARIA': 'VARIABLE', 'VARIAB': 'VARIABLE', 'VARIABL': 'VARIABLE',
        \ 'DEFI': 'DEFINE', 'DEFIN': 'DEFINE',
        \ 'MODE': 'MODEL',
        \ 'OUTP': 'OUTPUT', 'OUTPU': 'OUTPUT',
        \ 'SAVE': 'SAVEDATA', 'SAVED': 'SAVEDATA', 'SAVEDA': 'SAVEDATA', 'SAVEDAT': 'SAVEDATA',
        \ 'PLOT': 'PLOT',
        \ 'MONT': 'MONTECARLO', 'MONTE': 'MONTECARLO', 'MONTEC': 'MONTECARLO', 'MONTECA': 'MONTECARLO', 'MONTECAR': 'MONTECARLO', 'MONTECARL': 'MONTECARLO',
        \ 'TITL': 'TITLE',
        \ 'ESTI': 'ESTIMATOR', 'ESTIM': 'ESTIMATOR', 'ESTIMA': 'ESTIMATOR', 'ESTIMAT': 'ESTIMATOR', 'ESTIMATO': 'ESTIMATOR', 'EST': 'ESTIMATOR',
        \ 'DIST': 'DISTRIBUTION', 'DISTR': 'DISTRIBUTION', 'DISTRI': 'DISTRIBUTION', 'DISTRIB': 'DISTRIBUTION', 'DISTRIBU': 'DISTRIBUTION', 'DISTRIBUT': 'DISTRIBUTION', 'DISTRIBUTI': 'DISTRIBUTION', 'DISTRIBUTIO': 'DISTRIBUTION',
        \ 'PARAm': 'PARAMETERIZATION', 'PARAM': 'PARAMETERIZATION', 'PARAME': 'PARAMETERIZATION', 'PARAMET': 'PARAMETERIZATION', 'PARAMETE': 'PARAMETERIZATION', 'PARAMETE': 'PARAMETERIZATION', 'PARAMETER': 'PARAMETERIZATION', 'PARAMETERI': 'PARAMETERIZATION', 'PARAMETERIZ': 'PARAMETERIZATION', 'PARAMETERIZA': 'PARAMETERIZATION', 'PARAMETERIZAT': 'PARAMETERIZATION', 'PARAMETERIZATI': 'PARAMETERIZATION', 'PARAMETERIZATIO': 'PARAMETERIZATION',
        \ 'ALGO': 'ALGORITHM', 'ALGOR': 'ALGORITHM', 'ALGORI': 'ALGORITHM', 'ALGORIT': 'ALGORITHM', 'ALGORITH': 'ALGORITHM',
        \ 'INTE': 'INTEGRATION', 'INTEG': 'INTEGRATION', 'INTEGR': 'INTEGRATION', 'INTEGRA': 'INTEGRATION', 'INTEGRAT': 'INTEGRATION', 'INTEGRATI': 'INTEGRATION', 'INTEGRATIO': 'INTEGRATION', 'INT': 'INTEGRATION',
        \ 'ITERS': 'ITERATIONS', 'ITER': 'ITERATIONS', 'ITERA': 'ITERATIONS', 'ITERAT': 'ITERATIONS', 'ITERATI': 'ITERATIONS', 'ITERATIO': 'ITERATIONS',
        \ 'CONV': 'CONVERGENCE', 'CONVE': 'CONVERGENCE', 'CONVER': 'CONVERGENCE', 'CONVERG': 'CONVERGENCE', 'CONVERGE': 'CONVERGENCE', 'CONVERGEN': 'CONVERGENCE', 'CONVERGENC': 'CONVERGENCE',
        \ 'BOOT': 'BOOTSTRAP', 'BOOTS': 'BOOTSTRAP', 'BOOTST': 'BOOTSTRAP', 'BOOTSTR': 'BOOTSTRAP', 'BOOTSTRA': 'BOOTSTRAP',
        \ 'PROC': 'PROCESSORS', 'PROCE': 'PROCESSORS', 'PROCES': 'PROCESSORS', 'PROCESS': 'PROCESSORS', 'PROCESSO': 'PROCESSORS', 'PROCESSOR': 'PROCESSORS',
        \ 'STAR': 'STARTS', 'START': 'STARTS',
        \ 'ADAP': 'ADAPTIVE', 'ADAPT': 'ADAPTIVE', 'ADAPTI': 'ADAPTIVE', 'ADAPTIV': 'ADAPTIVE',
        \ 'INFO': 'INFORMATION', 'INFOR': 'INFORMATION', 'INFORM': 'INFORMATION', 'INFORMA': 'INFORMATION', 'INFORMAT': 'INFORMATION', 'INFORMATI': 'INFORMATION', 'INFORMATIO': 'INFORMATION',
        \ 'LINK': 'LINK',
        \ 'BITE': 'BITERATIONS', 'BITER': 'BITERATIONS', 'BITERA': 'BITERATIONS', 'BITERAT': 'BITERATIONS', 'BITERATI': 'BITERATIONS', 'BITERATIO': 'BITERATIONS', 'BITERATION': 'BITERATIONS',
        \ 'CHAI': 'CHAINS', 'CHAIN': 'CHAINS',
        \ 'THIN': 'THIN',
        \ 'USEV': 'USEVARIABLES', 'USEVA': 'USEVARIABLES', 'USEVAR': 'USEVARIABLES', 'USEVARI': 'USEVARIABLES', 'USEVARIA': 'USEVARIABLES', 'USEVARIAB': 'USEVARIABLES', 'USEVARIABL': 'USEVARIABLES', 'USEVARIABLE': 'USEVARIABLES',
        \ 'USEO': 'USEOBSERVATIONS', 'USEOB': 'USEOBSERVATIONS', 'USEOBS': 'USEOBSERVATIONS', 'USEOBSE': 'USEOBSERVATIONS', 'USEOBSER': 'USEOBSERVATIONS', 'USEOBSERV': 'USEOBSERVATIONS', 'USEOBSERVA': 'USEOBSERVATIONS', 'USEOBSERVAT': 'USEOBSERVATIONS', 'USEOBSERVATI': 'USEOBSERVATIONS', 'USEOBSERVATIO': 'USEOBSERVATIONS',
        \ 'MISS': 'MISSING', 'MISSI': 'MISSING', 'MISSIN': 'MISSING',
        \ 'CENT': 'CENTERING', 'CENTE': 'CENTERING', 'CENTER': 'CENTERING', 'CENTERI': 'CENTERING', 'CENTERIN': 'CENTERING',
        \ 'CLUS': 'CLUSTER', 'CLUST': 'CLUSTER', 'CLUSTE': 'CLUSTER',
        \ 'STRA': 'STRATIFICATION', 'STRAT': 'STRATIFICATION', 'STRATI': 'STRATIFICATION', 'STRATIF': 'STRATIFICATION', 'STRATIFI': 'STRATIFICATION', 'STRATIFIC': 'STRATIFICATION', 'STRATIFICA': 'STRATIFICATION', 'STRATIFICAT': 'STRATIFICATION', 'STRATIFICATI': 'STRATIFICATION', 'STRATIFICATIO': 'STRATIFICATION',
        \ 'WEIG': 'WEIGHT', 'WEIGH': 'WEIGHT',
        \ 'IDVA': 'IDVARIABLE', 'IDVAR': 'IDVARIABLE', 'IDVARI': 'IDVARIABLE', 'IDVARIA': 'IDVARIABLE', 'IDVARIAB': 'IDVARIABLE', 'IDVARIABL': 'IDVARIABLE',
        \ 'GROU': 'GROUPING', 'GROUP': 'GROUPING', 'GROUPI': 'GROUPING', 'GROUPIN': 'GROUPING',
        \ 'CENS': 'CENSORED', 'CENSO': 'CENSORED', 'CENSOR': 'CENSORED', 'CENSORE': 'CENSORED',
        \ 'CATE': 'CATEGORICAL', 'CATEG': 'CATEGORICAL', 'CATEGO': 'CATEGORICAL', 'CATEGOR': 'CATEGORICAL', 'CATEGORI': 'CATEGORICAL', 'CATEGORIC': 'CATEGORICAL', 'CATEGORICA': 'CATEGORICAL',
        \ 'NOMI': 'NOMINAL', 'NOMIN': 'NOMINAL', 'NOMINA': 'NOMINAL',
        \ 'COUN': 'COUNT',
        \ 'AUX': 'AUXILIARY', 'AUXI': 'AUXILIARY', 'AUXIL': 'AUXILIARY', 'AUXILI': 'AUXILIARY', 'AUXILIA': 'AUXILIARY', 'AUXILIAR': 'AUXILIARY',
        \ 'CLAS': 'CLASSES', 'CLASS': 'CLASSES', 'CLASSE': 'CLASSES',
        \ 'KNOW': 'KNOWNCLASS', 'KNOWN': 'KNOWNCLASS', 'KNOWNC': 'KNOWNCLASS', 'KNOWNCL': 'KNOWNCLASS', 'KNOWNCLA': 'KNOWNCLASS', 'KNOWNCLAS': 'KNOWNCLASS',
        \ 'WITH': 'WITHIN', 'WITHI': 'WITHIN',
        \ 'BETW': 'BETWEEN', 'BETWE': 'BETWEEN', 'BETWEE': 'BETWEEN',
        \ 'IMPU': 'IMPUTATION', 'IMPUT': 'IMPUTATION', 'IMPUTA': 'IMPUTATION', 'IMPUTAT': 'IMPUTATION', 'IMPUTATI': 'IMPUTATION', 'IMPUTATIO': 'IMPUTATION',
        \ 'NOBS': 'NOBSERVATIONS', 'NOBSE': 'NOBSERVATIONS', 'NOBSER': 'NOBSERVATIONS', 'NOBSERV': 'NOBSERVATIONS', 'NOBSERVA': 'NOBSERVATIONS', 'NOBSERVAT': 'NOBSERVATIONS', 'NOBSERVATI': 'NOBSERVATIONS', 'NOBSERVATIO': 'NOBSERVATIONS',
        \ 'NGRO': 'NGROUPS', 'NGROU': 'NGROUPS', 'NGROUP': 'NGROUPS',
        \ 'LIST': 'LISTWISE', 'LISTW': 'LISTWISE', 'LISTWI': 'LISTWISE', 'LISTWIS': 'LISTWISE',
        \ 'SAMP': 'SAMPSTAT', 'SAMPS': 'SAMPSTAT', 'SAMPST': 'SAMPSTAT', 'SAMPSTA': 'SAMPSTAT',
        \ 'STAN': 'STANDARDIZED', 'STAND': 'STANDARDIZED', 'STANDA': 'STANDARDIZED', 'STANDAR': 'STANDARDIZED', 'STANDARD': 'STANDARDIZED', 'STANDARDI': 'STANDARDIZED', 'STANDARDIZ': 'STANDARDIZED', 'STANDARDIZE': 'STANDARDIZED',
        \ 'RESI': 'RESIDUAL', 'RESID': 'RESIDUAL', 'RESIDU': 'RESIDUAL', 'RESIDUA': 'RESIDUAL',
        \ 'MODI': 'MODINDICES', 'MODIN': 'MODINDICES', 'MODIND': 'MODINDICES', 'MODINDI': 'MODINDICES', 'MODINDIC': 'MODINDICES', 'MODINDICE': 'MODINDICES',
        \ 'CINT': 'CINTERVAL', 'CINTE': 'CINTERVAL', 'CINTER': 'CINTERVAL', 'CINTERV': 'CINTERVAL', 'CINTERVA': 'CINTERVAL',
        \ 'TECH': 'TECH1', "TECH1": "TECH1", "TECH8": "TECH8"
    \ }

    let l:lnum = l:start
    while l:lnum <= l:end
        let l:line = getline(l:lnum)

        " 2. Skip if line is fully commented (starts with !) but clean whitespace
        if l:line =~? '^\s*!'
            let l:line = substitute(l:line, '	', '    ', 'g')
            let l:line = substitute(l:line, '\s\+$', '', '')
            call setline(l:lnum, l:line)
            let l:lnum += 1
            continue
        endif

        " 3. Basic Whitespace Cleanup
        " Replace tabs with 4 spaces
        let l:line = substitute(l:line, '	', '    ', 'g')
        " Remove trailing whitespace
        let l:line = substitute(l:line, '\s\+$', '', '')

        " 4. Header formatting
        " Detect section headers: start of line, keyword, colon.
        " E.g., "DATA: FILE IS..." -> "DATA:
  FILE IS..."
        let l:header_match = matchlist(l:line, '^\s*\(TITLE\|DATA\|VARIABLE\|DEFINE\|ANALYSIS\|MODEL\|OUTPUT\|SAVEDATA\|PLOT\|MONTECARLO\)\c\s*:\s*\(.\+\)')
        if !empty(l:header_match)
            " We found a header with content on the same line
            let l:header = l:header_match[1]
            let l:content = l:header_match[2]
            
            " Update current line to just "HEADER:"
            call setline(l:lnum, l:header . ':')
            
            " Insert content on next line
            call append(l:lnum, '  ' . l:content)
            
            " Adjust loop variables since we added a line
            let l:end += 1
            let l:lnum += 1 " Move to the new line to process it in next iteration? 
                            " Actually, better to process it now or let the loop handle it.
                            " If we assume the split content might need formatting, we should let the loop hit it.
            let l:line = '  ' . l:content " Continue processing the content part? 
            " No, let's just let the loop continue. The next iteration will pick up the new line.
            " But we need to make sure we don't double-process the header line.
            " For this iteration, we are done with the header line. 
            " We want to format the *new* line (l:lnum) in the *next* step.
            " So we should actually `continue` here, but check if we need to expand abbreviations in the header line? 
            " Headers are usually full words in the regex above.
            " Wait, if I split, I need to make sure the loop hits the new line.
            " v:count is fixed at start. `l:end` tracks the growing buffer.
            " So `while l:lnum <= l:end` works.
        endif

        " 5. Standardize Operators (IS/ARE -> =)
        " Avoid replacing inside strings or comments (simplified check)
        " We assume comments are handled at start of line or EOL.
        " Mplus ! comments are EOL.
        let l:code_part = l:line
        let l:comment_part = ''
        let l:bang_idx = stridx(l:line, '!')
        if l:bang_idx != -1
            let l:code_part = strpart(l:line, 0, l:bang_idx)
            let l:comment_part = strpart(l:line, l:bang_idx)
        endif

        " Replace IS/ARE with = (surrounded by whitespace)
        let l:code_part = substitute(l:code_part, '\c\<\(IS\|ARE\)\>', '=', 'g')

        " 6. Expand Abbreviations
        " We iterate words in code_part. 
        " Splitting by non-keyword characters to find words.
        " This is tricky with substitute. A callback approach is better.
        
        " Helper lambda for abbreviation replacement
        " Note: Vim script < 8 doesn't support lambdas easily, using a loop.
        " We'll use substitute with an expression.
        " Function to lookup abbreviation
        func! s:ExpandAbbrev(match) closure
            let l:word = toupper(a:match)
            if has_key(l:abbrevs, l:word)
                return l:abbrevs[l:word]
            endif
            return a:match " Return original if not found
        endfunc
        
        " Use \k to match keywords. 
        " Mplus keywords can contain hyphens? The syntax file had "CF-VARIMAX". 
        " \k usually includes letters, numbers, underscore. We might need to handle hyphens.
        " But our abbreviations list mostly has standard words.
        let l:code_part = substitute(l:code_part, '\c\<\w\+\>', '\=s:ExpandAbbrev(submatch(0))', 'g')

        " Reassemble line
        let l:new_line = l:code_part . l:comment_part
        
        " Update line in buffer
        call setline(l:lnum, l:new_line)

        let l:lnum += 1
    endwhile

    " 7. Re-indent the range
    " Using internal Vim indent logic (which uses indentexpr from indent/mplus-inp.vim)
    " We do this after all text manipulation.
    if has('unix')
        execute l:start . ',' . l:end . 'normal! =='
    else
        " Fallback for Windows if needed, though 'normal! ==' works there too.
        execute l:start . ',' . l:end . 'normal! =='
    endif

    return 0
endfunction
