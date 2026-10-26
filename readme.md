# daybreak.nvim

A Neovim Lua plugin that matches the colorscheme background with the system dark/light appearance.

## Set-Up

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
Linux display variables. Automatic zero-configuration setup is deferred so
plugin managers can apply explicit setup options first.

## Tests

Run the regression suite with Neovim 0.10 or newer and local checkouts of
[lazy.nvim](https://github.com/folke/lazy.nvim) and
[github-nvim-theme](https://github.com/projekt0n/github-nvim-theme):

```sh
DAYBREAK_LAZY_PATH=/path/to/lazy.nvim \
DAYBREAK_THEME_PATH=/path/to/github-nvim-theme \
nvim --headless -u NONE -i NONE -l tests/regression.lua
```

The suite runs real Lazy initialization and GitHub colorschemes while simulating
macOS platform detection and watcher I/O. It also checks fragmented/coalesced
notifications, zero-configuration and explicit setup, and Linux desktop/headless
dispatch with the clock boundaries.
