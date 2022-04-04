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

M.UpdateClientSideUI = function (_, preedit, cursor, aux_up, aux_down, candidates, candidate_index, layout_hint, has_prev, has_next)
  if table.getn(preedit) > 0 then
    preedit = preedit[1][1]
  else
    preedit = ""
  end

  if cursor >= 0 then
    local _tmp = cursor
    if string.sub(preedit,_tmp,_tmp) == " " then
      _tmp = _tmp -1
    end
    preedit = string.sub(preedit, 0, _tmp).."|"..string.sub(preedit, cursor+1, #preedit)
  end

  local candidates_ = {}
  for _, v in ipairs(candidates) do
    table.insert(candidates_, v[1]..v[2])
  end
  candidates_ = table.concat(candidates_," ")

  local lines = {
    " " .. preedit .. " ",
    " " .. candidates_ .. " ",
  }

  local height = 2
  local width = 0

  for _, s in ipairs(lines) do
    width = math.max(width, vim.api.nvim_strwidth(s))
  end

  vim.schedule(function ()
    vim.api.nvim_buf_set_lines(buf, 0, 2, false, lines)
    if win ~= -1 then
      vim.api.nvim_win_close(win,true)
      win = -1
    end
    if width > 2 then
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