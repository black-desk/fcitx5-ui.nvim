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
    if key.normal_name then
        key.code = keys[key.normal_name:match "[^+]+$"] or 0x20
        key.mask = 0
        for i, modifier in ipairs(modifiers) do
            for match in key.normal_name:gmatch "([^+]+)+" do
                if match == modifier then
                    key.mask = key.mask + 2 ^ (i - 1)
                end
            end
        end
    end
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
