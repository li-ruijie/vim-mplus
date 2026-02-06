autocmd BufRead,BufNewFile *.out setlocal autoread
:command! Mout vsp <bar> e %:r.out <bar> exe "normal \<c-w>\<c-w>"
:command! Mrun !start cmd /c mplus %
