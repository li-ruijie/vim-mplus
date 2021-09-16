if exists("b:current_syntax")
   finish
endif
source glob('<sfile>:p:h' . '/mplus.vim') ->fnameescape()
let b:current_syntax = "mplus-inp"
