setlocal foldmethod=syntax
setlocal omnifunc=syntaxcomplete#Complete

" Formatting configuration
setlocal textwidth=90
setlocal formatoptions-=t
setlocal formatoptions+=croql
setlocal comments=:!
setlocal commentstring=!%s
setlocal tabstop=4 softtabstop=4 shiftwidth=4 expandtab
setlocal fileencoding=utf-8 nobomb
setlocal formatexpr=mplus#format#Format()

"" Mplus executable: override with g:mplus_executable (default: 'mplus')
if !exists('g:mplus_executable')
  let g:mplus_executable = 'mplus'
endif

command! -buffer Mout execute 'vsp ' . fnameescape(expand('%:r') . '.out') <bar> wincmd p

if has('win32')
  command! -buffer Mrun execute '!start "" ' . shellescape(g:mplus_executable) . ' ' . shellescape(expand('%'))
else
  command! -buffer Mrun execute '!' . shellescape(g:mplus_executable) . ' ' . shellescape(expand('%')) . ' &'
endif
