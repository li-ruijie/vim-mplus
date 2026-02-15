setlocal foldmethod=syntax
setlocal omnifunc=syntaxcomplete#Complete
autocmd BufRead,BufNewFile *.out setlocal autoread

"" Mplus executable: override with g:mplus_executable (default: 'mplus')
if !exists('g:mplus_executable')
  let g:mplus_executable = 'mplus'
endif

command! Mout vsp <bar> e %:r.out <bar> exe "normal \<c-w>\<c-w>"

if has('win32')
  command! Mrun execute '!start cmd /c ' . g:mplus_executable . ' ' . shellescape(expand('%'))
else
  command! Mrun execute '!' . g:mplus_executable . ' ' . shellescape(expand('%')) . ' &'
endif
