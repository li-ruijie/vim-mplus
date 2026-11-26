" Tests for the kinds of line and the folds of an Mplus output.
"
" The fixtures in test/data/ are outputs of Mplus 9.1.1 for inputs and data
" written for the purpose: kinds-lca.out is a latent class analysis with
" random starts, CROSSTABS, TECH1, and TECH8, kinds-boot.out a factor model
" with bootstrap draws, TECH9, and an OUTPUT option that Mplus ignores with
" an error, kinds-efa.out an exploratory factor analysis of binary items
" with warnings, and kinds-groups.out CROSSTABS in an analysis of two
" groups. test/corpus/check-syntax.sh holds the syntax to the same rules on
" every line of the example outputs.

source <sfile>:p:h/common.vim

filetype plugin on
syntax on

let s:data = expand('<sfile>:p:h:h') . '/data/'

" The groups of the input syntax, which apply in the echoed input only. The
" output has groups of its own for comments and class labels.
let s:input_groups = ['mplusStatement', 'mplusCommand', 'mplusModel', 'mplusNumber',
    \ 'mplusString', 'mplusSpeccom', 'mplusFold', 'mplusBlockComment', 'mplusTitleComment',
    \ 'mplusTitleBlockComment']

function! s:Edit(name) abort
    execute 'edit' fnameescape(s:data . a:name)
    call assert_equal('mplus-out', &filetype, a:name)
endfunction

" Return the innermost group at the first character of line a:lnum that is
" no space, or '' on an empty line.
function! s:Group(lnum) abort
    let l:col = match(getline(a:lnum), '\S') + 1
    return l:col ? synIDattr(synID(a:lnum, l:col, 0), 'name') : ''
endfunction

" Return the first line of every fold of level a:level.
function! s:Starts(level) abort
    setlocal foldminlines=0
    let &l:foldlevel = a:level - 1
    return filter(range(1, line('$')), 'foldclosed(v:val) == v:val')
endfunction

" Return the line of INPUT INSTRUCTIONS and the last line of the echoed
" input, which ends above the first line with text at column 0.
function! s:Echo() abort
    let l:head = search('^INPUT INSTRUCTIONS\s*$', 'nw')
    let l:last = l:head
    while l:last < line('$') && getline(l:last + 1) !~# '^\S'
        let l:last += 1
    endwhile
    return [l:head, l:last]
endfunction

function! s:CheckLines(name, cases) abort
    call s:Edit(a:name)
    for [l:lnum, l:group, l:level] in a:cases
        let l:where = a:name . ' line ' . l:lnum . ': ' . getline(l:lnum)
        call assert_equal(l:group, s:Group(l:lnum), l:where)
        call assert_equal(l:level, foldlevel(l:lnum), l:where)
    endfor
    bwipeout!
endfunction

function! Test_kinds_of_lines() abort
    " The group at the first character and the fold level: the banner, the
    " echoed input with a section of one line (DATA) and sections of more,
    " the message that ends the reading of the input, the printed title, a
    " part, a part of two lines, a sub-header, a sub-header of two lines,
    " the pairs of CROSSTABS and their rows, the verdict on the random starts
    " and the status line in the status block, a sub-header in TECH1 and the
    " name of a matrix under it, the heads of the columns of TECH8, and the
    " footer.
    call s:CheckLines('kinds-lca.out', [
        \ [1, 'mplusBanner', 0], [3, 'mplusBanner', 0], [5, 'mplusPart', 1],
        \ [7, 'mplusStatement', 1], [8, 'mplusSection', 1], [9, 'mplusSection', 2],
        \ [16, 'mplusSection', 2], [20, '', 0], [24, 'mplusTitle', 0], [26, 'mplusPart', 1],
        \ [36, 'mplusSub', 2], [103, 'mplusPart', 1], [105, 'mplusSub', 2],
        \ [108, 'mplusSubFold', 2], [116, 'mplusSubFold', 2], [121, 'mplusSub', 2],
        \ [203, 'mplusPart', 1], [205, 'mplusSub', 2], [213, 'mplusSubFold', 2],
        \ [218, 'mplusStatusBlock', 0], [219, 'mplusStatusBlock', 0], [224, 'mplusStatus', 0],
        \ [227, '', 0], [228, 'mplusPart', 1], [232, 'mplusSub', 2], [245, 'mplusSub', 2],
        \ [246, 'mplusSub', 2], [248, 'mplusSub', 2], [262, 'mplusPart', 1],
        \ [263, 'mplusPart', 1], [299, 'mplusSub', 2], [300, 'mplusSub', 2],
        \ [449, 'mplusPart', 1], [452, 'mplusSub', 2], [461, 'mplusTable', 3],
        \ [464, 'mplusTableFold', 3], [515, 'mplusSubFold', 2], [961, 'mplusFooter', 0],
        \ [968, 'mplusFooter', 0], [977, 'mplusFooter', 0]])
    " An error about an option that Mplus ignores, with the line that counts
    " the errors, then the printed title, which follows that line. The
    " status lines of the bootstrap draws in TECH9 are plain text in its fold.
    call s:CheckLines('kinds-boot.out', [
        \ [9, 'mplusSection', 1], [11, 'mplusSection', 2], [20, 'mplusError', 0],
        \ [22, 'mplusError', 0], [23, 'mplusError', 0], [27, 'mplusTitle', 0],
        \ [28, 'mplusTitle', 0], [30, 'mplusPart', 1], [85, 'mplusStatus', 0],
        \ [89, 'mplusPart', 1], [93, 'mplusSub', 2], [256, 'mplusPart', 1],
        \ [260, 'mplusPart', 1], [262, 'mplusPartFold', 1], [265, 'mplusPartFold', 1],
        \ [273, 'mplusPartFold', 1], [281, 'mplusFooter', 0]])
    " Warnings inside a part, and the name of a matrix directly under a part.
    call s:CheckLines('kinds-efa.out', [
        \ [57, 'mplusPart', 1], [73, 'mplusWarning', 1], [76, 'mplusWarning', 1],
        \ [77, 'mplusWarning', 1], [82, 'mplusPart', 1], [85, 'mplusTable', 2],
        \ [86, 'mplusTableFold', 2], [91, 'mplusPart', 1], [94, 'mplusPart', 1]])
    " In an analysis of groups the pair of CROSSTABS stands directly below the
    " line that names the group, and is a sub-header there too.
    call s:CheckLines('kinds-groups.out', [
        \ [77, 'mplusPart', 1], [79, 'mplusPartFold', 1], [80, 'mplusSub', 2],
        \ [83, 'mplusSubFold', 2], [91, 'mplusSubFold', 2], [97, 'mplusSubFold', 2],
        \ [98, 'mplusSub', 2], [117, 'mplusStatus', 0]])
endfunction

function! Test_fold_starts() abort
    " Three levels: the echoed input and the parts, the sections of the
    " echoed input and the sub-headers, and the names of matrices and
    " tables. A section of one line starts no fold, and neither does the
    " second line of a header of two lines or a row of a table of CROSSTABS.
    call s:Edit('kinds-boot.out')
    call assert_equal([5, 30, 67, 89, 134, 159, 256, 260], s:Starts(1))
    call assert_equal([7, 11, 13, 16, 39, 70, 93, 98, 105, 111, 117, 122, 128, 162, 209],
        \ s:Starts(2))
    call assert_equal([165, 171, 180, 189, 195, 202, 212, 218, 227, 236, 242, 249], s:Starts(3))
    bwipeout!
    call s:Edit('kinds-lca.out')
    let l:starts = [s:Starts(1), s:Starts(2), s:Starts(3)]
    for [l:lnum, l:level] in [[5, 1], [9, 2], [13, 2], [16, 2], [26, 1], [103, 1], [105, 2],
        \ [121, 2], [262, 1], [272, 1], [245, 2], [299, 2], [452, 2], [461, 3], [509, 2]]
        call assert_notequal(-1, index(l:starts[l:level - 1], l:lnum), 'start ' . l:lnum)
    endfor
    for l:lnum in [7, 8, 108, 112, 116, 218, 224, 246, 263, 300, 515]
        call assert_equal([-1, -1, -1], map(copy(l:starts), 'index(v:val, l:lnum)'),
            \ 'no start ' . l:lnum)
    endfor
    bwipeout!
    call s:Edit('kinds-groups.out')
    call assert_equal([80, 98], filter(s:Starts(2), 'v:val > 77 && v:val < 117'))
    bwipeout!
endfunction

function! Test_status_block_shows_with_every_fold_closed() abort
    " The status block, from the verdict on the random starts to the line
    " above the next part, stands outside every fold, as the title and the
    " footer do. The status lines in TECH9 stay in its fold.
    call s:Edit('kinds-lca.out')
    setlocal foldminlines=0
    normal! zM
    call assert_equal(203, foldclosed(217))
    call assert_equal(repeat([-1], 10), map(range(218, 227), 'foldclosed(v:val)'))
    call assert_equal(228, foldclosed(228))
    call assert_equal(-1, foldclosed(24))
    call assert_equal(-1, foldclosed(977))
    bwipeout!
    call s:Edit('kinds-boot.out')
    setlocal foldminlines=0
    normal! zM
    call assert_equal(repeat([-1], 4), map(range(85, 88), 'foldclosed(v:val)'))
    call assert_equal(260, foldclosed(265))
    bwipeout!
endfunction

function! Test_echoed_input_has_the_input_syntax() abort
    " The echoed input is highlighted as an input, and no group of the input
    " syntax applies outside it.
    for l:name in ['kinds-lca.out', 'kinds-boot.out', 'kinds-efa.out']
        call s:Edit(l:name)
        let [l:head, l:last] = s:Echo()
        call assert_true(l:head > 0 && l:last > l:head, l:name)
        let l:inside = []
        for l:lnum in range(1, line('$'))
            for l:col in range(1, col([l:lnum, '$']) - 1)
                let l:names = map(synstack(l:lnum, l:col), 'synIDattr(v:val, "name")')
                if l:lnum > l:head && l:lnum <= l:last
                    call extend(l:inside, l:names)
                else
                    for l:group in s:input_groups
                        call assert_equal(-1, index(l:names, l:group),
                            \ l:name . ' line ' . l:lnum . ' column ' . l:col)
                    endfor
                endif
            endfor
        endfor
        for l:group in ['mplusStatement', 'mplusCommand', 'mplusModel', 'mplusFold']
            call assert_notequal(-1, index(l:inside, l:group), l:name . ': ' . l:group)
        endfor
        bwipeout!
    endfor
endfunction

function! s:Link(group) abort
    return matchstr(execute('highlight ' . a:group), 'links to \zs\w\+')
endfunction

function! Test_highlight_links() abort
    call s:Edit('kinds-lca.out')
    for [l:group, l:target] in [['mplusPart', 'mplusHeader'], ['mplusSub', 'mplusHeader'],
        \ ['mplusTable', 'mplusHeader'], ['mplusBanner', 'mplusHeader'],
        \ ['mplusHeader', 'Type'], ['mplusFooter', 'Comment'], ['mplusStatus', 'Special'],
        \ ['mplusWarning', 'WarningMsg'], ['mplusError', 'ErrorMsg'], ['mplusTitle', 'String']]
        call assert_equal(l:target, s:Link(l:group), l:group)
    endfor
    " A link that the user made before the syntax was loaded is kept.
    highlight link mplusSub Identifier
    set filetype=mplus-out
    call assert_equal('Identifier', s:Link('mplusSub'))
    highlight link mplusSub mplusHeader
    bwipeout!
endfunction

call RunTests()
