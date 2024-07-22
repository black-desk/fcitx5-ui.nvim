local M = {}

local consts = require("fcitx5-ui.consts")
local win = -1
local buf = vim.api.nvim_create_buf(false, true)

M.CurrentIM = function(_, name, cname, lan)
        require("fcitx5-ui").setCurrentIM(cname)
end

M.CommitString = function(_, str)
        vim.schedule(function()
                vim.api.nvim_feedkeys(str, 't', true)
        end)
end

M.ForwardKey = function(_, key, state, release)
        if release then
                return
        end
        key = string.char(key)
        if state == consts.FcitxKeyState.shift then
                key = "\\<S-" .. key .. ">"
        elseif state == consts.FcitxKeyState.alt then
                key = "\\<M-" .. key .. ">"
        elseif state == consts.FcitxKeyState.ctrl then
                key = "\\<C-" .. key .. ">"
        end
        vim.schedule(function()
                vim.api.nvim_feedkeys(key, 'm', true)
        end)
end

M.UpdateClientSideUI = function(_, preedit, cursor, aux_up, aux_down, candidates, candidate_index, layout_hint, has_prev,
                                has_next)
        local function getstr(aux)
                if table.getn(aux) > 0 then
                        return aux[1][1]
                end
                return ""
        end

        aux_up               = getstr(aux_up)
        aux_down             = getstr(aux_down)
        preedit              = getstr(preedit)

        local aux_up_width   = vim.api.nvim_strwidth(aux_up)
        local aux_down_width = vim.api.nvim_strwidth(aux_down)

        local aux_width      = math.max(aux_up_width, aux_down_width)
        local aux_up_free    = aux_width - aux_up_width
        local aux_down_free  = aux_width - aux_down_width

        if #preedit and cursor >= 0 then
                local _tmp = cursor
                if string.sub(preedit, _tmp, _tmp) == " " then _tmp = _tmp - 1 end
                preedit = string.sub(preedit, 0, _tmp) .. "|" .. string.sub(preedit, cursor + 1, #preedit)
        end

        local cfg = require "fcitx5-ui".config()

        local prev = cfg.prev
        if not has_prev then prev = "" end
        local next = cfg.next
        if not has_next then next = "" end

        local diff = 0

        local prev_width = vim.api.nvim_strwidth(prev)

        if aux_down_free < prev_width then
                diff = prev_width - aux_down_free
        end

        aux_up_free = aux_up_free + diff
        aux_down_free = aux_down_free + diff - prev_width

        local candidates_ = {}
        for i, v in ipairs(candidates) do
                local candidate = string.sub(v[1], 1, #v[1] - 1) .. v[2]
                if i == candidate_index + 1 then
                        candidate = '[' .. candidate .. ']'
                elseif i ~= candidate_index + 2 then
                        candidate = ' ' .. candidate
                end
                table.insert(candidates_, candidate)
        end

        candidates_ = table.concat(candidates_)
        if #candidates_ > 0 and string.sub(candidates_, #candidates_) ~= ']' then
                candidates_ = candidates_ .. ' '
        end

        local lines = {
                aux_up .. string.rep(" ", aux_up_free) .. preedit,
                aux_down .. string.rep(" ", aux_down_free) .. prev .. candidates_ .. next,
        }

        local height = table.getn(lines)

        if #lines[2] == aux_down_free then
                table.remove(lines, 2)
                height = 1
        end

        local width = 0
        for _, s in ipairs(lines) do
                width = math.max(width, vim.api.nvim_strwidth(s))
        end

        if width > 0 then
                local config = {
                        relative = 'cursor',
                        width = width,
                        height = height,
                        row = 1,
                        col = -aux_up_width - aux_up_free,
                        style = 'minimal'
                }
                vim.schedule(function()
                        vim.api.nvim_buf_set_lines(buf, 0, height, false, lines)
                        if win == -1 then
                                win = vim.api.nvim_open_win(buf, false, config)
                        else
                                vim.api.nvim_win_set_config(win, config)
                        end
                end)
        else
                vim.schedule(function()
                        if win ~= -1 then
                                vim.api.nvim_win_close(win, true)
                                win = -1
                        end
                end)
        end
end

return M
