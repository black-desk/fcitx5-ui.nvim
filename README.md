# Fcitx5 UI inside neovim

This is a fcitx5 user interface for neovim written in lua.

![demo](./assets/screenshot.png)

## Install

### rocks.nvim

#### Command style

```vim
:Rocks install fcitx5-ui.nvim
```

#### Declare style

`~/.config/nvim/rocks.toml`:

```toml
[plugins]
"fcitx5-ui.nvim" = "scm"
```

Then

```vim
:Rocks sync
```

or:

```sh
$ luarocks --tree ~/.local/share/nvim/rocks install fcitx5-ui.nvim
# ~/.local/share/nvim/rocks is the default rocks tree path
# you can change it according to your vim.g.rocks_nvim.rocks_path
```

### packer.nvim

``` lua
require('packer').use(
  "black-desk/fcitx5-ui.nvim",
  rocks = {'lgi', 'dbus_proxy'},
)
```

### lazy.nvim

``` lua
return {
  "black-desk/fcitx5-ui.nvim",
  config = config,
}
```

**NOTE**:

1. `lgi` and `dbus_proxy` needs `gobject-introspection` to build;
2. packer.nvim need `unzip` to install lua rocks;

## Config

The most config is same as
[rime.nvim](https://github.com/rimeinn/rime.nvim#frontend).
The only difference is trigger key which is used to switch input schema.

`~/.config/fcitx5/config`:

```dosini
[Hotkey/TriggerKeys]
0=Super+space

[Behavior]
# Share Input State
ShareInputState=No
```

By default, it will parse `~/.config/fcitx5/config`. You also can customize it.

```lua
local Fcitx = require 'fcitx.nvim.fcitx'.Fcitx
local Key = require 'fcitx.key'.Key
local fcitx = Fcitx{
  trigger = Key { normal_name = "Super+space" }
}
```

Old APIs for compatibility:

`require'fcitx5-ui'.activate()` to activate first input method,
then you can use `:startinsert` to enter insert mode.

`require'fcitx5-ui'.deactivate()` to deactivate input method.

`require'fcitx5-ui'.toggle()` to toggle between activate/deactivate.

`require'fcitx5-ui'.getCurrentIM()` to get current IM.

`require'fcitx5-ui'.setup(config)` to config this plugin.

## Related Projects

- [similar projects](https://github.com/rimeinn/ime.nvim#dbus)
- [let vim use dbus](https://github.com/rimeinn/ime.nvim#dbus-1) to communicate
  with fcitx in GUI
