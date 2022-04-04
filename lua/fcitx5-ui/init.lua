local M = {}

local consts = require("fcitx5-ui.consts")
local utils = require("fcitx5-ui.utils")
local sighdlr = require("fcitx5-ui.sighdlr")

local default_cfg = {
  keymap = {
    up = '<Up>',
    down = '<Down>',
    left = '<Left>',
    right = '<Right>',
    backspace = '<BS>',
    enter = '<CR>',
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
  { "display", consts.PluginName .. "-" .. utils.random_string(10) },
})

ret = assert(ret, tostring(err))

local path, _ = unpack(ret) -- uuid ignored

local InputContext = p.Proxy:new({
  bus = p.Bus.SESSION,
  name = consts.FcitxDBusName,
  interface = consts.FcitxInputContext1DBusInterface,
  path = path,
})

-- InputContext.connect_signal(
  -- sighdlr.CurrentIM,
  -- "CurrentIM"
-- )

InputContext:connect_signal(
  sighdlr.CommitString,
  "CommitString"
)

InputContext:connect_signal(
  sighdlr.UpdateClientSideUI,
  "UpdateClientSideUI"
)

ret, err = InputContext:SetCapability(consts.PluginCapabilities)

assert(ret, tostring(err))

local specialKeys = {
  -- TODO: Read [Hotkey/TriggerKeys] from ~/.config/fcitx5/config
  trigger   = {consts.FcitxKey.space, consts.FcitxKeyState.ctrl},
  up        = {consts.FcitxKey.up, consts.FcitxKeyState.no},
  down      = {consts.FcitxKey.down, consts.FcitxKeyState.no},
  left      = {consts.FcitxKey.left, consts.FcitxKeyState.no},
  right     = {consts.FcitxKey.right, consts.FcitxKeyState.no},
  backspace = {consts.FcitxKey.backspace, consts.FcitxKeyState.no},
  enter     = {consts.FcitxKey.enter, consts.FcitxKeyState.no},
}


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
  vim.keymap.set(
    {'i'}, effective_cfg.keymap.up,
    "luaeval(\"require'fcitx5-ui'.process_key('up')\") ? \"\\<Ignore>\" : \"\\<Up>\"",
    {buffer = 0, expr = true})
  vim.keymap.set(
    {'i'}, effective_cfg.keymap.down,
    "luaeval(\"require'fcitx5-ui'.process_key('down')\") ? \"\\<Ignore>\" : \"\\<Down>\"",
    {buffer = 0, expr = true})
  vim.keymap.set(
    {'i'}, effective_cfg.keymap.left,
    "luaeval(\"require'fcitx5-ui'.process_key('left')\") ? \"\\<Ignore>\" : \"\\<Left>\"",
    {buffer = 0, expr = true})
  vim.keymap.set(
    {'i'}, effective_cfg.keymap.right,
    "luaeval(\"require'fcitx5-ui'.process_key('right')\") ? \"\\<Ignore>\" : \"\\<Right>\"",
    {buffer = 0, expr = true})
  vim.keymap.set(
    {'i'}, effective_cfg.keymap.backspace,
    "luaeval(\"require'fcitx5-ui'.process_key('backspace')\") ? \"\\<Ignore>\" : \"\\<BS>\"",
    {buffer = 0, expr = true})
  vim.keymap.set(
    {'i'}, effective_cfg.keymap.enter,
    "luaeval(\"require'fcitx5-ui'.process_key('enter')\") ? \"\\<Ignore>\" : \"\\<CR>\"",
    {buffer = 0, expr = true})
  -- TODO: tab / s-tab
end

local function unsetAutocmds()
  vim.cmd[[
    au!  fcitx5_ui
    aug! fcitx5_ui
  ]]
end

local function unsetKeyMaps()
  vim.keymap.del( {'i'}, effective_cfg.keymap.up, {buffer = 0})
  vim.keymap.del( {'i'}, effective_cfg.keymap.down, {buffer = 0})
  vim.keymap.del( {'i'}, effective_cfg.keymap.left, {buffer = 0})
  vim.keymap.del( {'i'}, effective_cfg.keymap.right, {buffer = 0})
  vim.keymap.del( {'i'}, effective_cfg.keymap.backspace, {buffer = 0})
end

-- Never call this out side plugin.
M.process_key = function(input)
  local state
  if specialKeys[input] then
    input, state = unpack(specialKeys[input])
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
    ctx:iteration(true)
    vim.v.char = ''
    return true
  else
    return false
  end
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
  -- TODO: Implement
  effective_cfg = vim.tbl_extend(config, default_cfg)
end

return M
