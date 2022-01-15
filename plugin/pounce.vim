highlight PounceSelectedMatchHit cterm=bold ctermfg=black ctermbg=green gui=bold guifg=#555555 guibg=#11dd11
highlight PounceSelectedMatchMiss cterm=bold ctermfg=black ctermbg=darkgreen gui=bold guifg=#555555 guibg=#00aa00
highlight PounceUnselectedMatchHit ctermfg=black ctermbg=red guifg=#d8d873 guibg=#a85f38
highlight PounceUnselectedMatchMiss ctermfg=black ctermbg=darkred guifg=#d8a873 guibg=#784f38
highlight PounceAccept ctermfg=black ctermbg=blue guifg=#d8a8ff guibg=#784fff

command! Pounce :lua require('pounce').pounce()
