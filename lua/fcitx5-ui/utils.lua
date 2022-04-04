local M = {}

math.randomseed(os.time())

M.random_string = function (length)
  local set = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
  local default = 10
  local size = #set
  local ret = {}

  for _ = 1, length or default do
      local r = math.random(1, size)
      local char = string.sub(set, r, r)
      ret[#ret + 1] = char
  end

  return table.concat(ret)
end

return M
