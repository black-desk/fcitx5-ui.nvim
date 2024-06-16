local consts = require("fcitx5-ui.consts")
local utils = require("fcitx5-ui.utils")
local sighdlr = require("fcitx5-ui.sighdlr")

package.path = "" ..
    vim.fn.stdpath("data") .. "/fcitx5-ui/share/lua/5.1/?.lua;" ..
    vim.fn.stdpath("data") .. "/fcitx5-ui/share/lua/5.1/?/init.lua;" ..
    package.path

package.cpath = "" ..
    vim.fn.stdpath("data") .. "/fcitx5-ui/lib/lua/5.1/?.so;" ..
    package.cpath

local M = {
        activate = utils.warning,
        deactivate = utils.warning,
        getCurrentIM = utils.warning,
        process_key = utils.warning,
        reset = utils.warning,
        setCurrentIM = utils.warning,
        toggle = utils.warning,
}

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
        update = 50,
}

local ecfg = default_cfg -- effective config

M.setup = function(config)
        ecfg = vim.tbl_deep_extend("keep", config, default_cfg)
end

M.config = function()
        return ecfg
end

local lgi = utils.prequire('lgi')
if not lgi and not ecfg.ignore_module_missing_warning then
        utils.set_msg('lua module "lgi" not found.')
        return M
end

local ctx = lgi.GLib.MainLoop():get_context()

local p = utils.prequire("dbus_proxy")
if not p and not ecfg.ignore_module_missing_warning then
        utils.set_msg('lua module "dbus_proxy" not found.')
        return M
end

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
        local cmd = string.format([[
    aug fcitx5_ui
      au InsertCharPre <buffer> lua require'fcitx5-ui'.process_key(vim.v.char)
      au InsertLeave * lua require'fcitx5-ui'.reset()
      au WinLeave * lua require'fcitx5-ui'.reset()
    aug END
    function! UpdateFcitx5UI(timer)
      lua require'fcitx5-ui'.iteration()
    endfunction

    let g:fcitx5_ui_timer = timer_start(%d, 'UpdateFcitx5UI',{'repeat':-1})
  ]], ecfg.update)
        vim.cmd(cmd)
end

local function setupKeyMaps()
        for key, value in pairs(ecfg.keys) do
                vim.api.nvim_buf_set_keymap(
                        0, 'i', value[1],
                        "luaeval(\"require'fcitx5-ui'.process_key('" ..
                        key .. "')\") ? \"\\<Ignore>\" : \"\\" .. value[1] .. "\"",
                        { expr = true, replace_keycodes = false })
        end
end

local function unsetAutocmds()
        vim.cmd [[
    silent! au!  fcitx5_ui
    silent! aug! fcitx5_ui
    call timer_stop(fcitx5_ui_timer)
  ]]
end

local function unsetKeyMaps()
        for _, value in pairs(ecfg.keys) do
                vim.keymap.del({ 'i' }, value[1], { buffer = true })
        end
end

-- Never call this out side plugin.
M.process_key = function(input)
        local state
        if ecfg.keys[input] then
                _, input, state = unpack(ecfg.keys[input])
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
                vim.v.char = ''
        end

        return accept
end

local activated = false;

M.toggle = function()
        if activated then
                M.deactivate()
        else
                M.activate()
        end
        M.reset()
end

M.activate = function()
        if activated then
                return
        end
        sendFcitxTriggerKey()
        setupAutocmds()
        setupKeyMaps()
        activated = true
end

M.deactivate = function()
        if not activated then
                return
        end
        sendFcitxTriggerKey()
        unsetAutocmds()
        unsetKeyMaps()
        activated = false
        M.setCurrentIM("")
end

M.reset = function()
        InputContext:Reset()
        sighdlr.UpdateClientSideUI({}, {}, -1, {}, {}, {}, 0, 0, false, false)
end

local im = ""

M.setCurrentIM = function(str)
        im = str
end

M.getCurrentIM = function()
        return im
end

M.iteration = function()
        ctx:iteration()
end

return M
