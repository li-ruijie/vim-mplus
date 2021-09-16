if exists("b:current_syntax")
   finish
endif
source mplus.vim
syn match mplusHeader "^\u[A-Z ]\+$"
let b:current_syntax = "mplus-out"
