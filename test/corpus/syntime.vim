" Time the syntax of one output: open it, compute the fold level of its last
" line, which parses the whole buffer, and write one line with the wall time
" and the sum of the pattern times of :syntime to the file named by
" $SYNTIME_OUT. It runs in Vim with no configuration of the user:
"
"   SYNTIME_FILE=out SYNTIME_OUT=log vim -N -u NONE -i NONE -es -S syntime.vim </dev/null
"
" $SYNTIME_RTP names another copy of the plugin to time instead of this one,
" such as an older version written out with git archive, and $SYNTIME_LABEL
" starts the line. Times vary between runs on the same machine, so compare
" two versions in turns, in one sitting, several times each.

let s:repo = empty($SYNTIME_RTP) ? expand('<sfile>:p:h:h:h') : $SYNTIME_RTP
let &runtimepath = escape(s:repo, ',') . ',' . escape($VIMRUNTIME, ',')
set noswapfile nomore hidden
filetype plugin on
syntax on
syntime on
let s:start = reltime()
execute 'edit' fnameescape($SYNTIME_FILE)
call foldlevel(line('$'))
let s:wall = reltimefloat(reltime(s:start))
let s:report = split(execute('syntime report'), "\n")
let s:pattern = 0.0
for s:row in s:report
    let s:match = matchlist(s:row, '^\s*\(\d\+\.\d\+\)\s\+\d\+')
    if !empty(s:match)
        let s:pattern += str2float(s:match[1])
    endif
endfor
call writefile([printf('%s lines=%d wall=%.2f pattern=%.2f', $SYNTIME_LABEL, line('$'), s:wall,
    \ s:pattern)], $SYNTIME_OUT, 'a')
qall!
