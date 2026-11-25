" Mplus formatting function
" usage: setlocal formatexpr=mplus#format#Format()

" Keywords that are written in full, by the section that reads them. The
" number is the length of the shortest abbreviation that Mplus 9.1.1 reads
" as the keyword. That is four letters, also where a second option of the
" section starts with the same four. PARA is PARAMETERIZATION, and PARALLEL
" needs five letters. INTE is INTEGRATION, and INTERACTIVE needs five,
" which is why it has a 5 here.
"
" An abbreviation is looked up in the table of its own section only, since
" the same letters name different options in different sections. ESTI is
" ESTIMATOR in ANALYSIS and ESTIMATES in SAVEDATA, and STAR is STARTS in
" ANALYSIS and STARTING in MONTECARLO. DATA includes the options of its
" subcommands (DATA IMPUTATION, DATA WIDETOLONG).
let s:keywords = {
    \ 'DATA': {'IDVARIABLE': 4, 'IMPUTE': 4, 'LISTWISE': 4, 'NGROUPS': 4,
    \     'NOBSERVATIONS': 4, 'VARIANCES': 4},
    \ 'VARIABLE': {'AUXILIARY': 4, 'BETWEEN': 4, 'CATEGORICAL': 4,
    \     'CENSORED': 4, 'CENTERING': 4, 'CLASSES': 4, 'CLUSTER': 4,
    \     'COUNT': 4, 'GROUPING': 4, 'IDVARIABLE': 4, 'KNOWNCLASS': 4,
    \     'MISSING': 4, 'NOMINAL': 4, 'STRATIFICATION': 4,
    \     'USEOBSERVATIONS': 4, 'USEVARIABLES': 4, 'WEIGHT': 4, 'WITHIN': 4},
    \ 'ANALYSIS': {'ADAPTIVE': 4, 'ALGORITHM': 4, 'BITERATIONS': 4,
    \     'BOOTSTRAP': 4, 'CHAINS': 4, 'CONVERGENCE': 4, 'DISTRIBUTION': 4,
    \     'ESTIMATOR': 4, 'INFORMATION': 4, 'INTEGRATION': 4, 'INTERACTIVE': 5,
    \     'ITERATIONS': 4,
    \     'PARAMETERIZATION': 4, 'PROCESSORS': 4, 'STARTS': 4, 'VARIANCE': 4},
    \ 'SAVEDATA': {'ESTIMATES': 4, 'MISSFLAG': 4, 'SAMPLE': 4},
    \ 'MONTECARLO': {'AUXILIARY': 4, 'BETWEEN': 4, 'CATEGORICAL': 4,
    \     'CENSORED': 4, 'CLASSES': 4, 'COUNT': 4, 'MISSING': 4,
    \     'NGROUPS': 4, 'NOBSERVATIONS': 4, 'NOMINAL': 4, 'STARTING': 4,
    \     'WITHIN': 4}
\ }

" Short forms in the OUTPUT list, with the settings that follow an option
" in parentheses. Mplus takes an OUTPUT option in full or in the one short
" form given here, and it rejects any other shortening (RESI, MODI, CINTE),
" which therefore stays as written.
let s:output_forms = {'SAMP': 'SAMPSTAT', 'RES': 'RESIDUAL',
    \ 'MOD': 'MODINDICES', 'CINT': 'CINTERVAL', 'BOOT': 'BOOTSTRAP',
    \ 'CLUS': 'CLUSTER'}

" Sections whose statements start with an option name. MODEL and DEFINE
" statements start with a variable name, and TITLE holds free text.
let s:option_sections = ['DATA', 'VARIABLE', 'ANALYSIS', 'SAVEDATA', 'PLOT',
    \ 'MONTECARLO']

" Options whose value is a file name, which is kept exactly as written.
let s:file_options = ['FILE', 'SAMPLE', 'COVARIANCE', 'SIGBETWEEN', 'SWMATRIX',
    \ 'RESULTS', 'STDRESULTS', 'STDDISTRIBUTION', 'ESTIMATES', 'DIFFTEST',
    \ 'TECH3', 'TECH4', 'KAPLANMEIER', 'BASEHAZARD', 'ESTBASELINE', 'RESPONSE',
    \ 'MULTIPLIER', 'BPARAMETERS', 'RANKING', 'H5RESULTS', 'MFILE',
    \ 'LRESPONSES', 'POPULATION', 'COVERAGE', 'STARTING', 'INTERACTIVE']

" Pieces of a code line: a quoted string, a statement end, a comment, or a
" run of anything else.
let s:piece_re = '"[^"]*"\?\|''[^'']*''\?\|;\|!.*$\|[^"'';!]\+'

" Return the keyword of section a:section that the uppercase a:word names or
" abbreviates. Any other word is returned as it is.
function! s:Expand(word, section) abort
    for [l:keyword, l:shortest] in items(get(s:keywords, a:section, {}))
        if strlen(a:word) >= l:shortest && stridx(l:keyword, a:word) == 0
            return l:keyword
        endif
    endfor
    return a:word
endfunction

" Enter in a:state the section that starts with a:header, which is a result
" of mplus#section#Parse(). The lines of a TITLE are free text. So are the
" lines under a header that Mplus does not read, since it passes over them.
function! s:Enter(state, header) abort
    let a:state.section = a:header[0]
    let a:state.subtype = a:header[1]
    let a:state.free = a:header[0] ==# 'TITLE' || !a:header[3]
    let a:state.at_start = 1
    let a:state.verbatim = 0
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
" is free text, whether it is inside a block comment, and whether a new
" statement starts on a:lnum.
function! s:StateBefore(lnum) abort
    let l:state = {'section': '', 'subtype': '', 'free': 0, 'in_block': 0,
        \ 'at_start': 1, 'verbatim': 0}
    let l:have_code = 0
    let l:have_block = 0
    let l:at_start = 1
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
        let l:header = mplus#section#Parse(l:line)
        if !l:have_code
            let l:at_start = !empty(l:header) || s:CodeOnly(l:line) =~# ';\s*$'
            let l:have_code = 1
        endif
        if !empty(l:header)
            call s:Enter(l:state, l:header)
            break
        endif
    endwhile
    let l:state.at_start = l:at_start
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
            \ '\=get(s:output_forms, submatch(0), submatch(0))', 'g')
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
    let l:name = s:Expand(toupper(l:m[2]), a:state.section)
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

    " The range may start anywhere, so take the section, the free text and
    " block comment state, and the statement state from the lines above it.
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

        " Section header, also abbreviated (ANAL:) or with a second word
        " (MODEL INDIRECT:). The name is written in full and any content
        " after the colon moves to a line of its own. A header that Mplus
        " does not read (MODE INDIRECT:) stays as written, since the full
        " name would make Mplus read the section.
        let l:header = mplus#section#Parse(l:line)
        if !empty(l:header)
            call s:Enter(l:state, l:header)
            if !l:header[3]
                call setline(l:lnum, l:line)
            else
                call setline(l:lnum, l:header[0]
                    \ . (l:header[1] ==# '' ? '' : ' ' . l:header[1]) . ':')
                if l:header[2] !=# ''
                    call append(l:lnum, '  ' . l:header[2])
                    let l:end += 1
                endif
            endif
            let l:lnum += 1
            continue
        endif

        " Free text, which is a TITLE or a section that Mplus passes over,
        " is kept as written.
        call setline(l:lnum, l:state.free ? l:line : s:FormatCode(l:line, l:state))
        let l:lnum += 1
    endwhile

    " Re-indent the range using indentexpr
    execute l:start . ',' . l:end . 'normal! =='

    return 0
endfunction
