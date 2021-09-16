if exists("b:current_syntax")
   finish
endif
source fnameescape(glob('<sfile>:p:h' . '/mplus.vim'))
syn match mplusHeader "^\u[A-Z ]\+$"
let b:current_syntax = "mplus-out"
