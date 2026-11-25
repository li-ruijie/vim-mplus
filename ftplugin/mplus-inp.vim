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

"" An output file that Mplus has not written yet has no content to detect
"" the type from, so the type is set here.
command! -buffer Mout execute 'vsp ' . fnameescape(expand('%:r') . '.out')
    \ <bar> if empty(&filetype) <bar> setlocal filetype=mplus-out <bar> endif
    \ <bar> wincmd p

"" The second argument of shellescape() also escapes !, %, and #, which :!
"" would otherwise expand inside a file name.
if has('win32')
  "" Vim runs the program itself and takes the first argument as the program,
  "" so an empty window title makes it start nothing. Neovim passes the line
  "" to cmd.exe, whose start reads the first quoted argument as the title.
  command! -buffer Mrun execute '!start ' . (has('nvim') ? '"" ' : '')
      \ . shellescape(g:mplus_executable, 1) . ' ' . shellescape(expand('%'), 1)
else
  command! -buffer Mrun execute '!' . shellescape(g:mplus_executable, 1) . ' ' . shellescape(expand('%'), 1) . ' &'
endif
