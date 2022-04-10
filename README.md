# Fcitx5 UI inside neovim

**WARNING** This program is in very early stage and may break or change
frequently!

This is a fcitx5 user interface for neovim written in lua.

Basical fcitx5 functions seems work after a simple setup.

![demo](./assets/screenshot.png)

## Install

```lua
require('packer').use(
  "black-desk/fcitx5-ui.nvim",
  rocks = {'lgi', 'dbus_proxy'},
)
```

You **MUST** config fcitx to `ShareInputState=No`

**NOTE**:

1. `lgi` and `dbus_proxy` needs `gobject-introspection`
2. packer.nvim need `unzip` to install lua rocks
3. You will recive a message (`:messages`) if any dependency is missing.
   `ignore_module_missing_warning = true` will disable this warning message.

## Use

`require'fcitx5-ui'.activate()` to activate first input method, this will bring
you to insert mode.

`require'fcitx5-ui'.deactivate()` to deactivate input method.

`require'fcitx5-ui'.toggle()` to toggle between activate/deactivate.

`require'fcitx5-ui'.getCurrentIM()` to get current IM.

`require'fcitx5-ui'.setup(config)` to config this plugin.

## Config

### Map

This plugin needs you to config some key maps.

default config is:

```lua
local consts = require("fcitx5-ui.consts")

local default_cfg = {
  keys = {
    trigger = { '<C-Space>', consts.FcitxKey.space, consts.FcitxKeyState.ctrl },
    up = { '<Up>', consts.FcitxKey.up, consts.FcitxKeyState.no },
    down = { '<Down>', consts.FcitxKey.down, consts.FcitxKeyState.no },
    left = { '<Left>', consts.FcitxKey.left, consts.FcitxKeyState.no },
    right = { '<Right>', consts.FcitxKey.right, consts.FcitxKeyState.no },
    enter = { '<CR>', consts.FcitxKey.enter, consts.FcitxKeyState.no },
    backspace = { '<BS>', consts.FcitxKey.backspace, consts.FcitxKeyState.no },
    tab = { '<Tab>', consts.FcitxKey.tab, consts.FcitxKeyState.no },
    stab = { '<S-Tab>', consts.FcitxKey.tab, consts.FcitxKeyState.shift },
  },
  ignore_module_missing_warning = false,
  prev = "<|",
  next = "|>",
}
```

every key in `keys` is a table contains 3 entries:

  - keycode, (check `:help keycodes`), means the key you want to map.
  - [FcitxKey][link1]
  - [FcitxKeyState][link2]

FcitxKeyState and FcitxKey define the key event you want to send to fcitx.

`trigger` **MUST** be set to one of `[Hotkey/TriggerKeys]` in your fcitx config.

You can pass config of your own to `setup` function like this:

```lua
require'fcitx5-ui'.setup{
  keys = {
    up = {'<C-k>', consts.FcitxKey.up, consts.FcitxKeyState.no}
  }
}
```

Above config means that fcitx5 will recive a up key, when you press `<C-k>` in
insert mode of neovim with input method activating.

You might want to map `:lua require"fcitx5-ui".toggle()` also, check
[this][link5].

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

- [ ] fix update client side ui signal issue

## Thanks

[fcitx5.nvim][link3]

[lua-dbus_proxy][link4]

[fcitx.vim][link6]

[link1]: https://github.com/fcitx/fcitx5/blob/master/src/lib/fcitx-utils/keysymgen.h
[link2]: https://github.com/fcitx/fcitx5/blob/master/src/lib/fcitx-utils/keysym.h
[link3]: https://github.com/tonyfettes/fcitx5.nvim
[link4]: https://github.com/stefano-m/lua-dbus_proxy
[link5]: https://github.com/black-desk/dotfiles/blob/e0af17d86b7719bac6d3c936b9ebdf4ffc3c22af/private_dot_config/nvim/lua/plugins-d/_fcitx.lua#L6-L28
[link6]: https://github.com/lilydjwg/fcitx.vim
