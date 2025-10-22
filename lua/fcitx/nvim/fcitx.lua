---fcitx5 for neovim.
---@diagnostic disable: undefined-global
-- luacheck: ignore 111 113
local Win = require "ime.nvim.win".Win
local Keymap = require "ime.nvim.keymap".Keymap
local Hook = require "ime.nvim.hooks.chainedhook".ChainedHook

local Key = require 'fcitx.key'.Key
local Fcitx = require "fcitx.fcitx".Fcitx

local M = {
    Fcitx = {
        win = Win(),
        cname = ".default",
    }
}

---@param fcitx table?
---@return table fcitx
---@see ime.new
function M.Fcitx:new(fcitx)
    fcitx = fcitx or {}
    fcitx = Fcitx(fcitx)
    fcitx.keymap = fcitx.keymap or Keymap()
    fcitx.hook = fcitx.hook or Hook()
    setmetatable(fcitx, {
        __index = self
    })
    return fcitx
end

setmetatable(M.Fcitx, {
    __index = Fcitx,
    __call = M.Fcitx.new
})

---create autocmds.
---@param augroup_id integer?
function M.Fcitx:create_autocmds(augroup_id)
    augroup_id = augroup_id or vim.api.nvim_create_augroup("fcitx", {})

    vim.api.nvim_create_autocmd("InsertCharPre", {
        group = augroup_id,
        callback = self:callback()
    })

    vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave" }, {
        group = augroup_id,
        callback = function()
            if not self:get_enabled() then
                return
            end
            self.win:update()
        end
    })

    vim.api.nvim_create_autocmd("BufEnter", {
        group = augroup_id,
        callback = function()
            self.hook:update(self, self:get_enabled())
        end
    })
end

---update UI
---@param lines string[]
---@param col integer
function M.Fcitx:update(lines, col)
    self.win:update(lines, col)
    vim.schedule(
        function()
            self.keymap:set_special(self.win:has_preedit() and self.callback or nil, self)
        end
    )
end

---@return string
function M.Fcitx:get_current_schema()
    return self.cname
end

---@return string
function M.Fcitx:get_schema_name()
    return self:get_current_schema()
end

---signal handler
---@section handlers

---@param name string
---@param cname string
---@param lang string
function M.Fcitx:CurrentIM(name, cname, lang)
    self.cname = cname
    vim.schedule(
        function()
            self.hook:update(self, self:get_enabled())
        end
    )
end

---@param text string
function M.Fcitx:CommitString(text)
    vim.schedule(
        function()
            vim.api.nvim_feedkeys(text, 't', true)
        end
    )
end

---@param key integer
---@param state integer
---@param release boolean
function M.Fcitx:ForwardKey(key, state, release)
    if release then
        return
    end
    local k = Key { code = key, mask = state }
    vim.schedule(
        function()
            vim.api.nvim_feedkeys(k.name, 'm', true)
        end
    )
end

---override `IME`.
---@section overrides

---@param input string?
function M.Fcitx:exe(input)
    input = input or vim.v.char
    if not self.win:has_preedit() then
        for _, disable_key in ipairs(self.keymap.keys.disable) do
            if input == vim.keycode(disable_key) then
                self:disable()
                return
            end
        end
    end

    local key = Key { name = input }
    local ok, err = self:process(key.code, key.mask)
    if ok then
        vim.v.char = ''
    elseif err then
        print(err)
    end
end

---save the flag to use IM in insert mode for each buffer.
---override `self.iminsert` because it is global to all buffers.
---@param is_enabled boolean
-- luacheck: ignore 212/self
function M.Fcitx:set_enabled(is_enabled)
    self.keymap:set_nowait(is_enabled)
    vim.b.iminsert = is_enabled or nil
end

---similar to `set_enabled()`.
---@return boolean
-- luacheck: ignore 212/self
function M.Fcitx:get_enabled()
    return vim.b.iminsert
end

return M
