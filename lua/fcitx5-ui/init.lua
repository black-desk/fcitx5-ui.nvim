local M = {}

local consts = require("fcitx5-ui.consts")
local sighdlr = require("fcitx5-ui.sighdlr")

local function get_trigger()
  -- TODO: Read [Hotkey/TriggerKeys] from ~/.config/fcitx5/config
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

local effective_cfg = default_cfg

-- TODO: check session bus exists

local ctx = require('lgi').GLib.MainLoop():get_context()
local p = require("dbus_proxy")

local InputMethod1 = p.Proxy:new({
  bus = p.Bus.SESSION,
  name = consts.FcitxDBusName,
  interface = consts.FcitxInputMethod1DBusInterface,
  path = consts.FcitxInputMethod1DBusPath,
})

local ret, err = InputMethod1:CreateInputContext({
  { "program", consts.PluginName },
  { "display", consts.PluginName },
})

ret = assert(ret, tostring(err))

local path, _ = unpack(ret) -- uuid ignored

local InputContext = p.Proxy:new({
  bus = p.Bus.SESSION,
  name = consts.FcitxDBusName,
  interface = consts.FcitxInputContext1DBusInterface,
  path = path,
})

InputContext:connect_signal(
  sighdlr.CurrentIM,
  "CurrentIM"
)

InputContext:connect_signal(
  sighdlr.CommitString,
  "CommitString"
)

InputContext:connect_signal(
  sighdlr.UpdateClientSideUI,
  "UpdateClientSideUI"
)

InputContext:connect_signal(
  sighdlr.ForwardKey,
  "ForwardKey"
)

ret, err = InputContext:SetCapability(consts.PluginCapabilities)

assert(ret, tostring(err))

local function sendFcitxTriggerKey()
  M.process_key("trigger")
end

local function setupAutocmds()
  vim.cmd[[
    aug fcitx5_ui
      au InsertCharPre <buffer> lua require'fcitx5-ui'.process_key(vim.v.char)
      au InsertLeave * lua require'fcitx5-ui'.deactivate()
    aug END
  ]]
end

local function setupKeyMaps()
  for key, value in pairs(effective_cfg.keys) do
    vim.keymap.set(
      {'i'}, value[1],
      "luaeval(\"require'fcitx5-ui'.process_key('" .. key .. "')\") ? \"\\<Ignore>\" : \"\\" .. value[1] .. "\"",
      {buffer = 0, expr = true})
  end
end

local function unsetAutocmds()
  vim.cmd[[
    au!  fcitx5_ui
    aug! fcitx5_ui
  ]]
end

local function unsetKeyMaps()
  for _, value in pairs(effective_cfg.keys) do
    vim.keymap.del( {'i'}, value[1], {buffer = 0})
  end
end

-- Never call this out side plugin.
M.process_key = function(input)
  local state
  if effective_cfg.keys[input] then
    _, input, state = unpack(effective_cfg.keys[input])
  else
    input = string.byte(input)
    state = consts.FcitxKeyState.no
  end

  local accept
  accept, err = InputContext:ProcessKeyEvent(input, 0, state, false, 0)
  if accept == nil then
    error(tostring(err))
  end

  if accept then
    ctx:iteration()
    vim.v.char = ''
  end

  return accept
end

M.activate = function()
  sendFcitxTriggerKey()
  setupAutocmds()
  setupKeyMaps()
  vim.cmd([[ startinsert ]])
end

M.deactivate = function()
  sendFcitxTriggerKey()
  unsetAutocmds()
  unsetKeyMaps()
  vim.cmd([[ stopinsert ]])
end

M.setup = function (config)
  effective_cfg = vim.tbl_extend("keep", config, default_cfg)
end

local im = ""

M.setCurrentIM = function(str)
  im = str
end

M.getCurrentIM = function ()
  return im
end

return M
