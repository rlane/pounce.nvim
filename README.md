# pounce.nvim

Pounce is a motion plugin similar to [EasyMotion][1], [Sneak][2], [Hop][3], and
[Lightspeed][4]. It's based on incremental fuzzy search. Here's a demo:

[![asciicast](https://asciinema.org/a/7iNjH7JjHoPSskD2kovijjVfP.svg)](https://asciinema.org/a/7iNjH7JjHoPSskD2kovijjVfP)

The demo shows searching for the word "ht\_mask" by typing "htm" and then "J"
to select a match.

[1]: https://github.com/easymotion/vim-easymotion
[2]: https://github.com/justinmk/vim-sneak
[3]: https://github.com/phaazon/hop.nvim
[4]: https://github.com/ggandor/lightspeed.nvim

## Installation

Using vim-plug:

```
Plug 'rlane/pounce.nvim'
```

## Usage

The `:Pounce` command starts the motion. Type the character at the destination
and Pounce will highlight all matches on screen. Next, refine the matches by
typing more characters (in order) that are present after the destination. The
first letter of the match will be replaced with an uppercase "accept key". You
can hit that key to jump to the match, or continue refining the search. Escape
cancels the motion and leaves the cursor at its previous position.

No mappings are created by default. Here's a suggestion:

```vim
nmap s <cmd>Pounce<CR>
vmap s <cmd>Pounce<CR>
omap gs <cmd>Pounce<CR>  " 's' is used by vim-surround
```

Configuration is done with the `setup` function. The defaults:

```lua
require'pounce'.setup{
  accept_keys = "JFKDLSAHGNUVRBYTMICEOXWPQZ",
  debug = false,
}
```
