---Convert vim key name to fcitx key code and mask.
---fcitx key names are superset of rime key names.
---@diagnostic disable: undefined-global
-- luacheck: ignore 111 113
local Key = require 'ime.key'.Key

local keys = require "fcitx.data.keys"
local modifiers = require "fcitx.data.modifiers"

local M = {
    vim_to_rime = {
        pageup = "Page_Up",
        pagedown = "Page_Down",
        esc = "Escape",
        bs = "BackSpace",
        del = "Delete",
    },
    Key = {
        aliases = {
            ["<c-^>"] = "<c-6>",
            ["<c-_>"] = "<c-->",
            ["<c-/>"] = "<c-->",
        },
        modifiers = {},
    }
}

for k, v in pairs(Key.aliases) do
    M.Key.aliases[k] = v
end

for i, v in ipairs(modifiers) do
    if v == "Shift" then
        M.Key.modifiers.S = 2 ^ i
    elseif v == "Control" then
        M.Key.modifiers.C = 2 ^ i
    elseif v == "Alt" then
        M.Key.modifiers.A = 2 ^ i
    end
end
M.Key.modifiers.M = M.Key.modifiers.A

---@param key table?
---@return table
function M.Key:new(key)
    key = key or {}
    key = Key(key)
    setmetatable(key, {
        __tostring = self.tostring,
        __index = self
    })
    return key
end

---create a Key from a vim name
---@param name string
---@return integer
function M.Key.convert(name)
    return keys[M.vim_to_rime[name] or (name:sub(1, 1):upper() .. name:sub(2):lower())]
end

setmetatable(M.Key, {
    __index = Key,
    __call = M.Key.new
})

return M
