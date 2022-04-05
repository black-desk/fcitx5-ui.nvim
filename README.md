# Fcitx5 UI inside neovim

**WARNING** This program is in very early stage and may break or change frequently!

This is a fcitx5 user interface for neovim written in lua.

Basical fcitx5 functions seems work after a simple setup.

![demo](../assets/demo.gif)

## Install

```lua
require('packer').use(
  "black-desk/fcitx5-ui.nvim",
  rocks = {'lgi', 'dbus_proxy'},
)
```

You **MUST** config fcitx to `ShareInputState=No`

## Use

`require'fcitx5-ui'.activate()` to activate first input method, this will bring you to insert mode.

`require'fcitx5-ui'.deactivate()` to deactivate input method, this will bring you back to normal mode.

leave insert mode will invoke `deactivate()`

`require'fcitx5-ui'.getCurrentIM()` to get current IM.

`require'fcitx5-ui'.setup(config)` to config this plugin.

## Config

### Map

This plugin needs you to config some key maps.

default config is:

```lua
local consts = require("fcitx5-ui.consts")

local function get_trigger()
  return {'<C-Space>', consts.FcitxKey.space, consts.FcitxKeyState.ctrl }
end

local default_cfg = {
  keys = {
    trigger = get_trigger(),
    up = { '<Up>', consts.FcitxKey.up, consts.FcitxKeyState.no },
    down = { '<Down>', consts.FcitxKey.down, consts.FcitxKeyState.no },
    left = { '<Left>', consts.FcitxKey.left, consts.FcitxKeyState.no },
    right = { '<Right>', consts.FcitxKey.right, consts.FcitxKeyState.no },
    enter = { '<CR>', consts.FcitxKey.enter, consts.FcitxKeyState.no },
    backspace = { '<BS>', consts.FcitxKey.backspace, consts.FcitxKeyState.no },
  }
}
```

every key in `keys` is a table contains 3 entries:

  - keycode, (check `:help keycodes`), means the key you want to map.
  - [FcitxKey](https://github.com/fcitx/fcitx5/blob/master/src/lib/fcitx-utils/keysymgen.h) 
  - [FcitxKeyState](https://github.com/fcitx/fcitx5/blob/master/src/lib/fcitx-utils/keysym.h)

FcitxKeyState and FcitxKey define the key event you want to send to fcitx.

`trigger` **MUST** be set to one of `[Hotkey/TriggerKeys]` in your fcitx config.

### lualine

```lua
local cfg = require('lualine').get_config()
table.insert(
  cfg.sections.lualine_y,
  'require("fcitx5-ui").getCurrentIM()'
)
require('lualine').setup(cfg)
```

## TODO

- [ ] support switch between input methods
- [ ] auto config keymaps
- [ ] support vertical candidates layout

## Thanks

[fcitx5.nvim](https://github.com/tonyfettes/fcitx5.nvim)

[lua-dbus_proxy](https://github.com/stefano-m/lua-dbus_proxy)
