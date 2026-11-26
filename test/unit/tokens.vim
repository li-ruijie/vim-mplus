" The tokens of an Mplus input as Mplus 9.1.1 reads it. test_format.vim
" checks with them that gq changes nothing that Mplus reads, without a run
" of Mplus. Each rule was found by running small inputs through mplus.exe.
"
" Lines           Mplus reads the first 90 characters of a line, a tab
"                 counted as one, and drops the rest, in a title as well.
" Block comments  Outside the lines of a title, !* opens and *! closes a
"                 block comment anywhere on a line, also inside a ! comment
"                 or a quoted string, and block comments nest. A line on
"                 which a block comment opens and is still open at its end
"                 is dropped as a whole, the text before !* included. Where
"                 a block comment closes, the text after *! is read. Where
"                 it closes on the line on which it opened, the text before
"                 !* loses its trailing white space and the text after *!
"                 follows it. *! with no block comment open is a * and the
"                 start of a ! comment.
" Comments        Outside the lines of a title, ! starts a comment that runs
"                 to the end of the line, also inside a word or a quoted
"                 string.
" Title           The text after the colon of the TITLE line is read as code
"                 is, with its comments, and is the first line of the title.
"                 The lines below it, up to the next header, are title text
"                 with no comments in them, except that a line whose first
"                 character after the indent is a ! that no * follows is a
"                 comment line. Mplus prints a line of title text without
"                 its indent and its trailing white space and with each tab
"                 as one space, so these are the title tokens. An empty line
"                 is printed as an empty line, and is no token.
" Headers         mplus#section#Parse() gives the rule, which mplus-rules.sh
"                 checks against Mplus. A header in a block comment starts
"                 nothing, and Mplus does not read the lines of a section
"                 that it passes over.
" Code            Words are read without regard to case. A run of spaces,
"                 tabs, and line breaks separates two words, whatever its
"                 length. A line break separates them also after a minus
"                 sign. A semicolon ends a statement, also inside a quoted
"                 string.
" Strings         A quoted string keeps its case. In it a run of spaces is
"                 one space and a tab is a tab. A string that goes on to the
"                 next line is joined without the white space at the break.
" File names      Mplus keeps the case of a file name, quoted or not. It
"                 prints the name as written and gives it to the system.
" Connectors      IS, ARE, and = after an option name are one connector.
"                 Elsewhere IS is a word as any other (NAMES = y is).
"
" An abbreviation is read as the keyword that it shortens. The tokens give
" an option name and a word of OUTPUT the kind K, and the written word of
" such a token may be the start of the formatted one. Which keyword Mplus
" takes for it is left to the tests of the abbreviations by section.

" Sections whose statements start with an option name.
let s:option_sections = ['DATA', 'VARIABLE', 'ANALYSIS', 'SAVEDATA', 'PLOT',
    \ 'MONTECARLO']

" Options whose value is a file name, by section, from chapter 20 of the
" user's guide. A name shortened to four or more letters counts.
let s:file_options = {
    \ 'DATA': ['FILE', 'SWMATRIX', 'SAVE'],
    \ 'ANALYSIS': ['DIFFTEST', 'MULTIPLIER', 'INTERACTIVE'],
    \ 'SAVEDATA': ['FILE', 'SAMPLE', 'COVARIANCE', 'SIGBETWEEN', 'SWMATRIX',
    \     'RESULTS', 'STDRESULTS', 'STDDISTRIBUTION', 'ESTIMATES', 'DIFFTEST',
    \     'TECH3', 'TECH4', 'KAPLANMEIER', 'BASEHAZARD', 'ESTBASELINE',
    \     'RESPONSE', 'MULTIPLIER', 'BPARAMETERS', 'RANKING', 'H5RESULTS',
    \     'MFILE'],
    \ 'MONTECARLO': ['POPULATION', 'COVERAGE', 'STARTING', 'SAVE', 'RESULTS',
    \     'BPARAMETERS']
\ }

" Return whether option a:name of section a:section takes a file name.
function! s:IsFileOption(name, section) abort
    return strlen(a:name) >= 4
        \ && !empty(filter(copy(get(s:file_options, a:section, [])), 'stridx(v:val, a:name) == 0'))
endfunction

" Return the text of line a:line that is left when its block comments are
" taken out. a:state.depth is the depth of the block comments at the start
" of the line, and it is set to the depth at its end.
function! s:Uncomment(line, state) abort
    let l:out = ''
    let l:pos = 0
    while 1
        if a:state.depth > 0
            let l:at = match(a:line, '!\*\|\*!', l:pos)
            if l:at < 0
                break
            endif
            let a:state.depth += a:line[l:at] ==# '!' ? 1 : -1
            let l:pos = l:at + 2
        else
            let l:at = stridx(a:line, '!*', l:pos)
            if l:at < 0
                let l:out .= strpart(a:line, l:pos)
                break
            endif
            let l:out = substitute(l:out . strpart(a:line, l:pos, l:at - l:pos), '\s\+$', '', '')
            let a:state.depth = 1
            let l:pos = l:at + 2
        endif
    endwhile
    return a:state.depth > 0 ? '' : l:out
endfunction

" Return a line of title text as Mplus prints it.
function! s:TitleText(text) abort
    return substitute(substitute(a:text, '\t', ' ', 'g'), '^ \+\| \+$', '', 'g')
endfunction

" Add a token of kind a:kind with text a:text from line a:lnum.
function! s:Add(state, kind, text, lnum) abort
    call add(a:state.tokens, [a:kind, a:text, a:lnum])
endfunction

" Add the token of the quoted string that a:state holds.
function! s:CloseString(state) abort
    call s:Add(a:state, 'Q', substitute(a:state.string, ' \+', ' ', 'g'), a:state.string_lnum)
    let a:state.quote = ''
    let a:state.pos += 1
endfunction

" Add the token of word a:word of line a:lnum, by its place in the
" statement and the section.
function! s:Word(state, word, lnum) abort
    if a:word ==# ';'
        call s:Add(a:state, ';', ';', a:lnum)
        let a:state.pos = 0
        let a:state.file = 0
        return
    endif
    let l:upper = toupper(a:word)
    if a:state.section ==# 'OUTPUT'
        call s:Add(a:state, 'K', l:upper, a:lnum)
    elseif index(s:option_sections, a:state.section) < 0
        call s:Add(a:state, 'C', l:upper, a:lnum)
    elseif a:state.pos == 0
        call s:Add(a:state, 'K', l:upper, a:lnum)
        let a:state.file = s:IsFileOption(l:upper, a:state.section)
    elseif a:state.pos == 1 && (l:upper ==# 'IS' || l:upper ==# 'ARE')
        call s:Add(a:state, 'C', '=', a:lnum)
    elseif a:state.file && a:state.pos >= 2
        call s:Add(a:state, 'F', a:word, a:lnum)
    else
        call s:Add(a:state, 'C', l:upper, a:lnum)
    endif
    let a:state.pos += 1
endfunction

" Add the tokens of a:text, the code of line a:lnum.
function! s:Code(text, state, lnum) abort
    let l:text = a:state.quote ==# '' ? a:text : substitute(a:text, '^\s\+', '', '')
    if a:state.quote ==# '' && l:text !~# '["'']'
        let l:words = split(substitute(l:text, '[;=]', ' & ', 'g'))
        if a:state.section !=# 'OUTPUT' && index(s:option_sections, a:state.section) < 0
            " The place of a word in the statement does not matter here.
            call extend(a:state.tokens,
                \ map(l:words, '[v:val ==# ";" ? ";" : "C", toupper(v:val), a:lnum]'))
            return
        endif
        for l:word in l:words
            call s:Word(a:state, l:word, a:lnum)
        endfor
        return
    endif
    let l:pos = 0
    while 1
        if a:state.quote !=# ''
            " The string ends at its closing quote or at a semicolon.
            let l:at = match(l:text, '[;' . a:state.quote . ']', l:pos)
            if l:at < 0
                let a:state.string .= substitute(strpart(l:text, l:pos), '\s\+$', '', '')
                return
            endif
            let a:state.string .= strpart(l:text, l:pos, l:at - l:pos)
            call s:CloseString(a:state)
            let l:pos = l:text[l:at] ==# ';' ? l:at : l:at + 1
            continue
        endif
        let [l:word, l:start, l:pos] = matchstrpos(l:text, '[;="'']\|[^ \t;="'']\+', l:pos)
        if l:start < 0
            return
        elseif l:word =~# '^["'']'
            let a:state.quote = l:word
            let a:state.string = ''
            let a:state.string_lnum = a:lnum
        else
            call s:Word(a:state, l:word, a:lnum)
        endif
    endwhile
endfunction

" Return the tokens of the input a:lines as Mplus reads it, with each line
" cut to a:width characters, or read whole when a:width is 0. A token is
" [kind, text, line number]. The kinds are H for a header that Mplus reads,
" X for one that it passes over, T for a line of title text, K for an
" option name or a word of OUTPUT, C for any other word, F for a word of a
" file name, Q for a quoted string, and ; for the end of a statement.
function! MplusTokens(lines, width) abort
    let l:state = {'tokens': [], 'depth': 0, 'title': 0, 'section': '', 'read': 1,
        \ 'pos': 0, 'file': 0, 'quote': ''}
    let l:lnum = 0
    for l:line in a:lines
        let l:lnum += 1
        let l:line = substitute(l:line, '\r$', '', '')
        if a:width > 0
            let l:line = strpart(l:line, 0, a:width)
        endif
        if l:state.title && l:state.depth == 0 && empty(mplus#section#Parse(l:line))
            if l:line !~# '^\s*!\%(\*\)\@!' && s:TitleText(l:line) !=# ''
                call s:Add(l:state, 'T', s:TitleText(l:line), l:lnum)
            endif
            continue
        endif
        let l:state.title = 0
        let l:text = substitute(s:Uncomment(l:line, l:state), '!.*', '', '')
        let l:header = mplus#section#Parse(l:text)
        if !empty(l:header)
            if l:state.quote !=# ''
                call s:CloseString(l:state)
            endif
            call s:Add(l:state, l:header[3] ? 'H' : 'X',
                \ l:header[0] . (l:header[1] ==# '' ? '' : ' ' . l:header[1]), l:lnum)
            let l:state.section = l:header[0]
            let l:state.read = l:header[3]
            let l:state.title = l:header[3] && l:header[0] ==# 'TITLE'
            let l:state.pos = 0
            let l:state.file = 0
            let l:text = l:header[2]
            if l:state.title
                if s:TitleText(l:text) !=# ''
                    call s:Add(l:state, 'T', s:TitleText(l:text), l:lnum)
                endif
                continue
            endif
        endif
        if l:state.read
            call s:Code(l:text, l:state, l:lnum)
        endif
    endfor
    if l:state.quote !=# ''
        call s:CloseString(l:state)
    endif
    return l:state.tokens
endfunction

" Return whether the written token a:written and the formatted token
" a:formatted are read alike. The word of an option name or of OUTPUT may
" be written in full, each of its words longer than in a:written.
function! s:Alike(written, formatted) abort
    if a:written[0] !=# a:formatted[0]
        return 0
    elseif a:written[1] ==# a:formatted[1]
        return 1
    endif
    return a:written[0] ==# 'K' && a:formatted[1] =~# '\V\^'
        \ . substitute(escape(a:written[1], '\'), '\a\w*', '&\\w\\*', 'g') . '\$'
endfunction

" Return a token for a message.
function! s:Show(token) abort
    return empty(a:token) ? 'nothing'
        \ : printf('%s %s (line %d)', a:token[0], string(a:token[1]), a:token[2])
endfunction

" Return '' when the formatted tokens a:formatted are read as the written
" tokens a:written are, and else the first difference. Where a:whole is
" true the written input was read with its lines whole, and a line of title
" text may stand in the formatted input as several lines, broken at white
" space, as gq breaks a line that is longer than Mplus reads.
function! MplusTokenDifference(written, formatted, whole) abort
    let l:i = 0
    let l:j = 0
    while l:i < len(a:written) && l:j < len(a:formatted)
        let l:w = a:written[l:i]
        let l:f = a:formatted[l:j]
        if s:Alike(l:w, l:f)
            let l:i += 1
            let l:j += 1
            continue
        endif
        let l:k = l:j
        let l:parts = []
        while a:whole && l:w[0] ==# 'T' && l:k < len(a:formatted) && a:formatted[l:k][0] ==# 'T'
            call add(l:parts, escape(a:formatted[l:k][1], '\'))
            let l:k += 1
            if len(l:parts) > 1 && l:w[1] =~# '\V\^' . join(l:parts, '\s\+') . '\$'
                break
            endif
        endwhile
        if len(l:parts) > 1 && l:w[1] =~# '\V\^' . join(l:parts, '\s\+') . '\$'
            let l:i += 1
            let l:j = l:k
            continue
        endif
        return 'written ' . s:Show(l:w) . ', formatted ' . s:Show(l:f)
    endwhile
    if l:i < len(a:written) || l:j < len(a:formatted)
        return 'written ' . s:Show(get(a:written, l:i, [])) . ', formatted '
            \ . s:Show(get(a:formatted, l:j, []))
    endif
    return ''
endfunction

" Return whether one of the lines a:lines is longer than Mplus reads.
function! s:Long(lines) abort
    return !empty(filter(copy(a:lines), 'strlen(substitute(v:val, "\r$", "", "")) > 90'))
endfunction

" Compare the input a:written with its formatted form a:formatted, both
" lists of lines. Return [difference, note]. The difference is '' when gq
" changed nothing that Mplus reads. Where Mplus cuts a line of the written
" input, the formatted input has to hold the tokens of the whole line,
" which is what the author wrote, and the note tells what Mplus drops from
" the written input and how its tokens then differ. Mplus may cut no line
" of the formatted input.
function! MplusTokenCheck(written, formatted) abort
    let l:after = MplusTokens(a:formatted, 90)
    if s:Long(a:formatted)
        let l:cut = MplusTokenDifference(MplusTokens(a:formatted, 0), l:after, 0)
        if l:cut !=# ''
            return ['Mplus cuts a line of the formatted input: ' . l:cut, '']
        endif
    endif
    let l:read = MplusTokens(a:written, 90)
    let l:whole = s:Long(a:written) ? MplusTokens(a:written, 0) : l:read
    if l:read == l:whole
        return [MplusTokenDifference(l:read, l:after, 0), '']
    endif
    let l:dropped = []
    let l:lnum = 0
    for l:line in a:written
        let l:lnum += 1
        let l:line = substitute(l:line, '\r$', '', '')
        if strlen(l:line) > 90
            call add(l:dropped, 'line ' . l:lnum . ' ' . string(strpart(l:line, 90)))
        endif
    endfor
    return [MplusTokenDifference(l:whole, l:after, 1), 'as written, Mplus drops '
        \ . join(l:dropped, ', ') . ', and the first token that differs is '
        \ . MplusTokenDifference(l:read, l:after, 0)]
endfunction
