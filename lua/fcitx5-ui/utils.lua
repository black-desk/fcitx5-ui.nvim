local M = {}

local msg = ""

-- https://stackoverflow.com/a/17878208
M.prequire = function (m)
  local ok, err = pcall(require, m)
  if not ok then return nil, err end
  return err
end

M.warning = function ()
  if #msg ~=0 then
    print("fcitx5-ui.nvim not load: " .. msg)
  end
  return ""
end

M.set_msg = function (m)
  msg = m
end

return M

