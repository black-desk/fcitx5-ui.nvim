---Convert vim key name to fcitx key code and mask
---@diagnostic disable: undefined-global
-- luacheck: ignore 111 113
local Key = require 'ime.key'.Key

local keys = require "fcitx.data.keys"
local modifiers = require "fcitx.data.modifiers"

local M = {
    Key = {}
}

---@param key table?
---@return table
function M.Key:new(key)
    key = key or {}
    key = Key(key, keys, modifiers)
    setmetatable(key, {
        __index = self
    })
    return key
end

setmetatable(M.Key, {
    __index = Key,
    __call = M.Key.new
})

return M
