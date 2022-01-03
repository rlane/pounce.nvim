highlight PounceSelectedMatchHit gui=reverse guifg=#385f38 guibg=#f8f893
highlight PounceSelectedMatchMiss gui=reverse guifg=#384f38 guibg=#f8c893
highlight PounceUnselectedMatchHit gui=reverse guifg=#a85f38 guibg=#f8f893
highlight PounceUnselectedMatchMiss gui=reverse guifg=#784f38 guibg=#f8c893

command! Pounce :lua require('pounce').pounce()
