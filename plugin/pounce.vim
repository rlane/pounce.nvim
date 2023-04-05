if !has("nvim")
  echo "pounce.nvim requires neovim"
  finish
endif

lua require'pounce'.setup()
