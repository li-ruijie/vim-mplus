" Compare the tokens of the input named by $MPLUS_WRITTEN with those of its
" formatted form named by $MPLUS_FORMATTED, as test/unit/tokens.vim reads
" them, and write the verdict as one line to the file named by
" $MPLUS_TOKEN_OUT. run-tests.sh runs this for an example that Mplus has
" not finished within the time limit, since the tokens tell without a run
" of Mplus whether gq changed what Mplus reads.
let s:test = expand('<sfile>:p:h')
let &runtimepath = escape(fnamemodify(s:test, ':h'), ',') . ',' . escape($VIMRUNTIME, ',')
execute 'source' fnameescape(s:test . '/unit/tokens.vim')
let [s:difference, s:note] = MplusTokenCheck(readfile($MPLUS_WRITTEN), readfile($MPLUS_FORMATTED))
call writefile([(s:difference ==# '' ? 'same' : 'different: ' . s:difference)
    \ . (s:note ==# '' ? '' : ' (' . s:note . ')')], $MPLUS_TOKEN_OUT)
qall!
