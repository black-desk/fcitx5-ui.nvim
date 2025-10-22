---lazy load `fcitx.nvim.fcitx`
local Fcitx = require('fcitx.nvim.fcitx').Fcitx

local M = {}

---init if required
---@param augroup_id integer?
function M.init(augroup_id)
    if M.ime == nil then
        M.ime = Fcitx(M.fcitx)
        M.ime:create_autocmds(augroup_id)
    end
end

---wrap `self.ime:toggle()`
---@see ime.toggle
function M.toggle()
    M.init()
    return M.ime:toggle()
end

---wrap `self.ime:enable()`
---@see ime.enable
function M.enable()
    M.init()
    return M.ime:enable()
end

---wrap `self.ime:disable()`
---@see ime.disable
function M.disable()
    M.init()
    return M.ime:disable()
end

---wrap `self.ime:callback()`
---@param key string?
---@see ime.callback
function M.callback(key)
    return function()
        M.init()
        return M.ime:callback(key)
    end
end

return M
