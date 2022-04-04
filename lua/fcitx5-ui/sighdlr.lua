local M = {}

local win = -1
local buf = vim.api.nvim_create_buf(false, true)

M.CurrentIM = function()
  -- TODO: lualine
end

M.CommitString = function (_, str)
  local r, c = unpack(vim.api.nvim_win_get_cursor(0))
  vim.schedule(function()
    vim.api.nvim_buf_set_text(0, r-1, c, r-1, c, {str})
    vim.api.nvim_win_set_cursor(0, {r, c + #str})
  end)
end

M.UpdateClientSideUI = function (_, preedits, cursor, aux_up, aux_down, candidates, candidate_index, layout_hint, has_prev, has_next)
  local preedits_ = {}
  for _, v in ipairs(preedits) do
    table.insert(preedits_, v[1])
  end
  preedits_ = table.concat(preedits_," ")

  local candidates_ = {}
  for _, v in ipairs(candidates) do
    table.insert(candidates_, v[1]..v[2])
  end
  candidates_ = table.concat(candidates_," ")

  local lines = {
    preedits_,
    candidates_
  }

  local height = 2
  local width = 0

  for _, s in ipairs(lines) do
    width = math.max(width, #s)
  end

  vim.schedule(function ()
    vim.api.nvim_buf_set_lines(buf, 0, 2, false, lines)
    if win ~= -1 then
      vim.api.nvim_win_close(win,true)
      win = -1
    end
    if width > 0 then
      win = vim.api.nvim_open_win(buf, false, {
        relative = 'cursor',
        width = width,
        height = height,
        row = 1,
        col = 0,
        style = 'minimal'
      })
    end
  end)
end

return M
