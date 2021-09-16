if exists("b:current_syntax")
   finish
endif
source fnameescape(glob('<sfile>:p:h' . '/mplus.vim'))
let b:current_syntax = "mplus-inp"
