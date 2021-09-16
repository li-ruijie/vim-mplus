if exists("b:current_syntax")
   finish
endif
source glob('%:p:h' . '/mplus.vim') ->fnameescape()
syn match mplusHeader "^\u[A-Z ]\+$"
let b:current_syntax = "mplus-out"
