# pounce.nvim

Pounce is a motion plugin similar to [EasyMotion][1], [Sneak][2], [Hop][3], and
[Lightspeed][4]. It's based on incremental fuzzy search. Here's a demo:

![demo](.assets/demo.gif)

The demo shows searching for the word "ht\_mask" by typing "s" to activate
Pounce, "htm" to refine the search, and then "J" to select the match.

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
can hit that key to jump to the match, or continue refining the search. Enter
accepts the best match (highlighted in blue). Escape cancels the motion and
leaves the cursor at its previous position.

The `:PounceRepeat` command works the same way but is initialized with the
input from the previous Pounce command.

No mappings are created by default. Here's a suggestion:

```vim
nmap s <cmd>Pounce<CR>
nmap S <cmd>PounceRepeat<CR>
vmap s <cmd>Pounce<CR>
omap gs <cmd>Pounce<CR>  " 's' is used by vim-surround
```

Configuration is done with the `setup` function. It's optional to call `setup`.
Here are the defaults:

```lua
require'pounce'.setup{
  accept_keys = "JFKDLSAHGNUVRBYTMICEOXWPQZ",
  accept_best_key = "<enter>",
  multi_window = true,
  debug = false,
}
```

Note that `accept_keys` allows you to configure the order in which accept keys display – closest proximity match gets the first letter in the `accept_keys` string. Users of alternative keyboard layouts may wish to amend that string. Colemak DHm might start with `NTESIROA...` for example.

## Related Work

There are quite a few plugins in this space. Here are some alternatives to
Pounce:

- https://github.com/easymotion/vim-easymotion
- https://github.com/justinmk/vim-sneak
- https://github.com/phaazon/hop.nvim
- https://github.com/ggandor/lightspeed.nvim
- https://github.com/yuki-yano/fuzzy-motion.vim
- https://github.com/hrsh7th/vim-searchx
