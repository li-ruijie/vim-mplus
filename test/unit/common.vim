" Shared setup for the editor tests, which run in Vim and in Neovim without
" Mplus. A test file sources this file, defines functions named Test_*, and
" ends with a call to RunTests(). test/run-unit-tests.sh runs them all.

" Only the plugin and the files shipped with the editor are on the
" runtimepath, so that the configuration of the user cannot change a result.
let s:repo = expand('<sfile>:p:h:h:h')
let &runtimepath = escape(s:repo, ',') . ',' . escape($VIMRUNTIME, ',')
set noswapfile nomore hidden

" Lines for the log that are not failures, such as a skipped check.
let g:test_notes = []

" Return the Mplus example files with extension a:ext. They are searched for
" in the directory named by $MPLUS_EXAMPLES, or else in test/original/, and
" in every directory below it.
function! ExampleFiles(ext) abort
    let l:dir = empty($MPLUS_EXAMPLES) ? s:repo . '/test/original' : $MPLUS_EXAMPLES
    let l:files = glob(l:dir . '/**/*.' . a:ext, 1, 1)
    if empty(l:files)
        call add(g:test_notes, 'SKIP: no *.' . a:ext . ' examples in ' . l:dir)
    endif
    return l:files
endfunction

" Call every Test_* function, write the notes and the failures to the file
" named by $MPLUS_TEST_LOG with PASS or FAIL as the last line, and quit.
function! RunTests() abort
    for l:name in getcompletion('Test_', 'function')
        let l:name = matchstr(l:name, '^\w\+')
        try
            call call(l:name, [])
        catch
            call add(v:errors, l:name . ': ' . v:exception . ' (' . v:throwpoint . ')')
        endtry
    endfor
    call writefile(g:test_notes + v:errors + [empty(v:errors) ? 'PASS' : 'FAIL'],
        \ $MPLUS_TEST_LOG)
    qall!
endfunction
