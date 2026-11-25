" Many programs write *.out files, so the type is set only for a file that
" starts as Mplus output does, with the lines "Mplus VERSION 8.8" and
" "MUTHEN & MUTHEN". Either line among the first ten is enough.
autocmd BufRead *.out
    \ if match(getline(1, 10), '\C^\s*\%(Mplus VERSION\>\|MUTHEN & MUTHEN\s*$\)') >= 0
    \ |   setfiletype mplus-out
    \ | endif
