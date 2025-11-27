---IME based on fcitx5
local p = require 'dbus_proxy'
local lgi = require 'lgi'
local uv = require 'luv'
local inifile = require 'inifile'
local fn = require 'vim.fn'
local PlatformDirs = require 'platformdirs'.PlatformDirs
local IME = require "ime.ime".IME
local UI = require 'ime.ui'.UI

local Key = require 'fcitx.key'.Key
local capabilities = require 'fcitx.data.capabilities'

local M = {
    config = PlatformDirs { appname = "fcitx5", version = "config" }:user_config_dir(),
    proxy = {
        bus = p.Bus.SESSION,
        name = "org.freedesktop.portal.Fcitx",
        interface = "org.fcitx.Fcitx.InputMethod1",
        path = "/org/freedesktop/portal/inputmethod",
    },
    context = {
        { "program", "fcitx5uinvim" },
        { "display", "fcitx5uinvim" },
    },
}
M.Fcitx = {
    capability = capabilities.ClientSideInputPanel + capabilities.KeyEventOrderFix,
    proxy = {
        bus = p.Bus.SESSION,
        name = "org.freedesktop.portal.Fcitx",
        interface = "org.fcitx.Fcitx.InputContext1",
    },
    interval = 50,
}
local f = io.open(M.config)
if f then
    local text = f:read "*a"
    f:close()
    local config = inifile.parse(text, "memory")
    if config["Hotkey/TriggerKeys"] and config["Hotkey/TriggerKeys"]["0"] then
        M.Fcitx.trigger = Key { normal_name = config["Hotkey/TriggerKeys"]["0"] }
    end
end

---convert fcitx5 data structure to context
---@param preedit string[][]
---@param cursor integer
---@param aux_up string[][]
---@param aux_down string[][]
---@param candidate_index integer
---@param layout_hint string
---@param has_prev boolean
---@param has_next boolean
---@return table
function M.get_context(preedit, cursor, aux_up, aux_down, candidates,
                       candidate_index, layout_hint, has_prev, has_next)
    local preedit_ = #preedit > 0 and preedit[1][1] or ""
    local context = {
        composition = {
            length = #preedit_,
            cursor_pos = cursor,
            sel_start = 0,
            sel_end = 1,
            preedit = preedit_,
        },
        menu = {
            page_size = #candidates,
            page_no = has_prev and 1 or 0,
            is_last_page = not has_next,
            highlighted_candidate_index = candidate_index,
            num_candidates = #candidates,
            candidates = {}
        }
    }
    for i, candidate in ipairs(candidates) do
        context.menu.candidates[i] = { text = candidate[2] }
    end
    return context
end

---@param fcitx table?
---@return table fcitx
---@see ime.new
function M.Fcitx:new(fcitx)
    fcitx = fcitx or {}
    if fcitx.proxy == nil then
        local proxy = p.Proxy:new(M.proxy)
        local ret, err = proxy:CreateInputContext(M.context)
        assert(ret, tostring(err))
        proxy = M.Fcitx.proxy
        proxy.path = ret[1]
        fcitx.proxy = p.Proxy:new(proxy)
    end
    fcitx.ui = fcitx.ui or UI()
    fcitx.timer = fcitx.timer or uv.new_timer()
    fcitx = IME(fcitx)
    setmetatable(fcitx, {
        __index = self
    })
    fcitx.proxy:connect_signal(fcitx:CurrentIM_cb(), "CurrentIM")
    fcitx.proxy:connect_signal(fcitx:CommitString_cb(), "CommitString")
    fcitx.proxy:connect_signal(fcitx:UpdateClientSideUI_cb(), "UpdateClientSideUI")
    fcitx.proxy:connect_signal(fcitx:ForwardKey_cb(), "ForwardKey")
    fcitx.proxy:SetCapability(fcitx.capability)
    fcitx.timer:start(fcitx.interval, fcitx.interval, function()
        lgi.GLib.MainLoop():get_context():iteration()
    end)
    if fcitx.trigger then
        fcitx:process(fcitx.trigger.code, fcitx.trigger.mask)
    end
    return fcitx
end

setmetatable(M.Fcitx, {
    __index = IME,
    __call = M.Fcitx.new
})

---wrap `self.proxy:ProcessKeyEvent()`
---@param code integer
---@param mask integer
---@return boolean ok
---@return string err
function M.Fcitx:process(code, mask)
    return self.proxy:ProcessKeyEvent(code, 0, mask, false, 0)
end

---update UI
---@param lines string[]
---@param col integer
function M.Fcitx:update(lines, col)
    print(table.concat(lines))
end

---**entry for fcitx**
function M.Fcitx:main()
    self:enable()
    while true do
        local c = fn.getchar()
        self:call({ code = c, mask = 0 })
    end
end

---callback
---@section callbacks

---@see CurrentIM
function M.Fcitx:CurrentIM_cb(...)
    return function(_, ...)
        self:CurrentIM(...)
    end
end

---@see CommitString
function M.Fcitx:CommitString_cb(...)
    return function(_, ...)
        self:CommitString(...)
    end
end

---@see ForwardKey
function M.Fcitx:ForwardKey_cb(...)
    return function(_, ...)
        self:ForwardKey(...)
    end
end

---@see UpdateClientSideUI
function M.Fcitx:UpdateClientSideUI_cb(...)
    return function(_, ...)
        self:UpdateClientSideUI(...)
    end
end

---signal handler
---@section handlers

---@param name string
---@param cname string
---@param lang string
function M.Fcitx:CurrentIM(name, cname, lang)
    print(cname)
end

---@param text string
function M.Fcitx:CommitString(text)
    print(text)
end

---@param key integer
---@param state integer
---@param release boolean
function M.Fcitx:ForwardKey(key, state, release)
    if release then
        return
    end
    local k = Key { code = key, mask = state }
    print(k.name)
end

---@param preedit string[][]
---@param cursor integer
---@param aux_up string[][]
---@param aux_down string[][]
---@param candidate_index integer
---@param layout_hint string
---@param has_prev boolean
---@param has_next boolean
function M.Fcitx:UpdateClientSideUI(preedit, cursor, aux_up, aux_down,
                                    candidates, candidate_index, layout_hint,
                                    has_prev, has_next)
    local lines = {}
    local col = 0
    if #preedit > 0 then
        local context = M.get_context(preedit,
            cursor, aux_up, aux_down,
            candidates, candidate_index, layout_hint,
            has_prev, has_next)
        lines, col = self.ui:draw(context)
    end
    self:update(lines, col)
end

---override `IME`.
---@section overrides

---override `IME`.
---@param ... table
function M.Fcitx:exe(...)
    for _, key in ipairs { ... } do
        self:process(key.code, key.mask)
    end
end

return M
