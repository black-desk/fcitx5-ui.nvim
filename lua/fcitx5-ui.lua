---keep compatibility with old fcitx5-ui.nvim
local Fcitx = require('fcitx.nvim.fcitx').Fcitx
local M = require 'fcitx.nvim'
M.activate = M.enable
M.deactivate = M.disable

---setup
---@param config table
function M.setup(config)
    M.fcitx = config
    M.ime = Fcitx(M.fcitx)
end

---@return string
function M.getCurrentIM()
    if M.ime then
        return M.ime:get_schema_name()
    end
    return ''
end

return M
