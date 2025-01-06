# Ani-cli.nvim

Plugin to watch anime in Vim/NeoVim

# Install

Using [lazy.vim](https://github.com/folke/lazy.nvim):
```lua
{
  "TwoSpikes/ani-cli.nvim",
}
```

Using [vim-plug](https://github.com/junegunn/vim-plug):
```vim
Plug 'TwoSpikes/ani-cli.nvim'
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):
```lua
use 'TwoSpikes/ani-cli.nvim'
```

Using [pckr.nvim](https://github.com/lewis6991/pckr.nvim):
```lua
'TwoSpikes/ani-cli.nvim'
```

Using [dein](https://github.com/Shougo/dein.vim):
```vim
call dein#add('TwoSpikes/ani-cli.nvim')
```

Using [paq-nvim](https://github.com/savq/paq-nvim):
```lua
'TwoSpikes/ani-cli.nvim'
```

Using [Pathogen](https://github.com/tpope/vim-pathogen):
```console
$ cd ~/.vim/bundle && git clone https://github.com/TwoSpikes/ani-cli.nvim
```

Using Vim built-in package manager (requires Vim v.8.0+) ([help](https://vimhelp.org/repeat.txt.html#packages) or `:h packages`):
```console
$ cd ~/.vim/pack/test/start/ && git clone https://github.com/TwoSpikes/ani-cli.nvim
```

# How to use it

## Show help

```vim
:Ani -h
```

## Examples of usage

```
:Ani -q 720p banana fish
:Ani --skip --skip-title "one piece" -S 2 one piece
:Ani -d -e 2 cyberpunk edgerunners
:Ani --vlc cyberpunk edgerunners -q 1080p -e 4
:Ani blue lock -e 5-6
:Ani -e "5-6" blue lock
```
