# daybreak.nvim

A Vim and Neovim plugin that matches the colorscheme background with the system dark/light appearance.

## Set-Up

### Vim

Requires Vim 8.0 or newer. Add `raindev/daybreak.nvim` and set the themes
before the plugin loads:

```vim
Plug 'raindev/daybreak.nvim'

let g:daybreak_light = 'morning'
let g:daybreak_dark = 'habamax'
```

Without themes configured only `background` is set. To configure from a
function instead:

```vim
call daybreak#setup({'light': 'morning', 'dark': 'habamax'})
```

Live appearance updates need a Vim built with `+job`; without it the appearance
is read once at startup.

### Neovim

When using [lazy.nvim](https://github.com/folke/lazy.nvim) just include `raindev/daybreak.nvim` into the list of plugins:

```lua
'raindev/daybreak.nvim'
```

With different light and dark themes (make sure you don't also set
`colorscheme` in your configuration to avoid conflicts):

``` lua
{
  'raindev/daybreak.nvim',
  opts = {
    light = 'github_light_default',
    dark = 'github_dark_default',
  }
}
```

Using any other plugin manager add `raindev/daybreak.nvim` and load the plugin with

```lua
require('daybreak').setup({
  light = 'github_light_default',
  dark = 'github_dark_default',
})
```

Both editors run the same Vim script implementation; the Lua module only
forwards setup options for Neovim plugin managers.

## Goals

1. Immediately pick up appearance changes.
   - [x] Linux
   - [x] macOS
   - [ ] windows
2. Event based, no polling.
3. Support Linux, macOS and Windows.
4. Zero configuration required.

On a headless Linux host (no GUI and no `WAYLAND_DISPLAY`, `DISPLAY`,
or `MIR_SOCKET`) the plugin does not probe the desktop portal.
Appearance cannot be read there. It uses the local clock instead:
dark from 19:00 until 06:00, light otherwise.

macOS uses its native appearance API, including in terminal Neovim without
Linux display variables. Automatic zero-configuration setup is deferred under
Neovim so plugin managers can apply explicit setup options first.

## Tests

`tests/run.sh` runs the regression suite under either editor:

```sh
tests/run.sh vim
```

```sh
DAYBREAK_LAZY_PATH=/path/to/lazy.nvim \
DAYBREAK_THEME_PATH=/path/to/github-nvim-theme \
tests/run.sh nvim
```

The suite starts a fresh editor per case and fakes the Linux portal, macOS
watcher and Windows registry, so it also runs on Linux. Under Neovim it adds
real Lazy initialization and GitHub colorschemes. It checks fragmented/coalesced
notifications, zero-configuration and explicit setup, and the clock boundaries.
