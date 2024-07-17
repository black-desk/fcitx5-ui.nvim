local modrev = 'scm'
local specrev = '1'

local repo_url = 'https://github.com/black-desk/fcitx5-ui.nvim'

rockspec_format = '3.0'
package = 'fcitx5-ui.nvim'
version = modrev ..'-'.. specrev

description = {
  summary = 'fcitx5 user interface inside neovim',
  detailed = '',
  labels = { },
  homepage = 'https://github.com/black-desk/fcitx5-ui.nvim',
  license = 'GPL-3.0'
}

dependencies = { 'lua >= 5.1', 'dbus_proxy' }

test_dependencies = { }

if modrev == 'scm' or modrev == 'dev' then
  source = {
    url = repo_url:gsub('https', 'git')
  }
end

build = {
  type = 'builtin',
  copy_directories = { 'doc' } ,
}

