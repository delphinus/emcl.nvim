# emcl.nvim

Yet another plugin to use Emacs shortcut in Neovim's command line.

## What's this?

This is a port of [vim-emacscommandline][] written in Lua for Neovim. Pros/Cons
for the original are below.

[vim-emacscommandline]: https://github.com/houtsnip/vim-emacscommandline

<dl>
<dt>Pros</dt>
<dd>
<ul>
<li>emcl.nvim has tests for all funcs.</li>
<li>emcl.nvim is written in Lua, so it is more readable and extensible than Vimscript.</li>
</ul>
</dd>
<dt>Cons</dt>
<dd>
<ul>
<li>emcl.nvim does not work on Vim ;( This is for Neovim only.</li>
</ul>
</dd>
</dl>

## Installation

### [Vim packages][]

[Vim packages]: https://neovim.io/doc/user/repeat.html#packages

```sh
git clone https://github.com/delphinus/emcl.nvim \
  ~/.local/share/nvim/site/pack/foo/start/emcl.nvim
```

And in your `init.lua`……

```lua
require("emcl").setup {}
```

### [packer.nvim][]

[packer.nvim]: https://github.com/wbthomason/packer.nvim

```lua
use {
  "delphinus/emcl.nvim' ,
  config = function()
    require("emcl").setup {}
  end,
}
```

## Features

| Feature                     | Default mapping       |
|-----------------------------|-----------------------|
| ForwardChar                 | `<C-f>`               |
| BackwardChar                | `<C-b>`               |
| BeginningOfLine             | `<C-a>`               |
| EndOfLine                   | `<C-e>`               |
| OlderMatchingCommandLine    | `<C-p>`               |
| NewerMatchingCommandLine    | `<C-n>`               |
| FirstLineInHistory          | `<M-<>`               |
| LastLineInHistory           | `<M->>`               |
| SearchCommandLine           | `<C-r>`               |
| AbortCommand                | `<C-g>`               |
| ForwardWord                 | `<M-f>`               |
| BackwardWord                | `<M-b>`               |
| DeleteChar                  | `<Del>`, `<C-d>`      |
| BackwardDeleteChar          | `<BS>`, `<C-h>`       |
| KillWord                    | `<M-d>`               |
| DeleteBackwardsToWhiteSpace | `<C-w>`               |
| BackwardKillWord            | `<M-BS>`              |
| TransposeChar               | `<C-t>`               |
| TransposeWord               | `<M-t>`               |
| Yank                        | `<C-y>`               |
| Undo                        | `<C-_>`, `<C-x><C-y>` |
| YankLastArg                 | `<M-.>, `<M-_>`       |
| ToggleExternalCommand       | `<C-z>`               |

## Options

TBD

## Todo

* [ ] Tests for TransposeWord
  * TransposeWord may have bugs.
