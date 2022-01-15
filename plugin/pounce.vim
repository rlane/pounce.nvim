highlight PounceMatch cterm=bold ctermfg=black ctermbg=green gui=bold guifg=#555555 guibg=#11dd11
highlight PounceGap cterm=bold ctermfg=black ctermbg=darkgreen gui=bold guifg=#555555 guibg=#00aa00
highlight PounceAccept cterm=bold ctermfg=black ctermbg=blue gui=bold guifg=#111111 guibg=#de940b

command! Pounce :lua require('pounce').pounce()
