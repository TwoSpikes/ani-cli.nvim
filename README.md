> [!Important]
> I just rewrote [ani-cli](https://github.com/pystardust/ani-cli) to Vimscript

# Ani-cli.nvim

Plugin to watch anime in Vim/NeoVim

> [!Note]
> 100%-compatible with [Termux](https://github.com/termux/termux-app)

> [!Note]
> Supports [ani-cli](https://github.com/pystardust/ani-cli) history

# Dependencies

- [Vim](https://github.com/vim/vim) or [NeoVim](https://github.com/neovim/neovim)
- [vim-quickui](https://github.com/skywind3000/vim-quickui)
- [curl](https://github.com/curl/curl)
- [ani-skip](https://github.com/synacktraa/ani-skip) (Optional)
- ([ffmpeg](https://git.ffmpeg.org/ffmpeg.git) or [yt-dlp](https://github.com/yt-dlp/yt-dlp)) and [aria2c](https://aria2.github.io/) (For downloading)

# How to use on Android

Install `mpv` app: https://github.com/mpv-android/mpv-android/releases

# How to use on iOS (iSH)

No way yet, use original [ani-cli](https://github.com/pystardust/ani-cli)

# Installation

Using [lazy.vim](https://github.com/folke/lazy.nvim):
```lua
{
  "TwoSpikes/ani-cli.nvim",
  dependencies = {
    "skywind3000/vim-quickui",
  }
}
```

Using [vim-plug](https://github.com/junegunn/vim-plug):
```vim
Plug 'skywind3000/vim-quickui'
Plug 'TwoSpikes/ani-cli.nvim'
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):
```lua
use {
    'TwoSpikes/ani-cli.nvim',
    requires = {
        'skywind3000/vim-quickui',
    }
}
```

Using [pckr.nvim](https://github.com/lewis6991/pckr.nvim):
```lua
{
    'TwoSpikes/ani-cli.nvim',
    requires = {
        'skywind3000/vim-quickui'
    }
}
```

Using [dein](https://github.com/Shougo/dein.vim):
```vim
call dein#add('skywind3000/vim-quickui')
call dein#add('TwoSpikes/ani-cli.nvim')
```

Using [paq-nvim](https://github.com/savq/paq-nvim):
```lua
'skywind3000/vim-quickui',
'TwoSpikes/ani-cli.nvim',
```

Using [Pathogen](https://github.com/tpope/vim-pathogen):
```console
$ cd ~/.vim/bundle
$ git clone --depth=1 https://github.com/skywind3000/vim-quickui
$ git clone --depth=1 https://github.com/TwoSpikes/ani-cli.nvim
```

Using Vim built-in package manager (requires Vim v.8.0+) ([help](https://vimhelp.org/repeat.txt.html#packages) or `:h packages`):
```console
$ cd ~/.vim/pack/test/start/
$ git clone --depth=1 https://github.com/skywind3000/vim-quickui
$ git clone --depth=1 https://github.com/TwoSpikes/ani-cli.nvim
```

# Keymaps

You can add keyboard shourtcuts similar to these

```vim
:let g:ani_cli_options = "-v --dub"
:noremap <leader>xa <cmd>execute "Ani ".g:ani_cli_options." -c"<cr>
:noremap <leader>xA <cmd>execute "Ani ".g:ani_cli_options<cr>
```

# How to use it

## Show help

```vim
:Ani -h
```

Press <kbd>q</kbd> to close help window

## See most popular anime

```vim
:Ani
```

Then, when you see input, press <kbd>Escape</kbd>

## Continue watching from history

```vim
:Ani -c
```

## Examples of usage

```vim
:Ani -q 720p banana fish
:Ani --skip --skip-title "one piece" -S 2 one piece
:Ani -d -e 2 cyberpunk edgerunners
:Ani --vlc cyberpunk edgerunners -q 1080p -e 4
:Ani blue lock -e 5-6
:Ani -e "5-6" blue lock
```
