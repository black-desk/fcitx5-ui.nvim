rockspec_format = '3.0'
description = {
  summary = '',
  detailed = '',
  labels = {},
  homepage = 'https://github.com/black-desk/fcitx5-ui.nvim',
  license = 'GPL-3.0',
}
package = description.homepage:match('/([^/]+)/?$')
version = 'scm-1'
source = {
  url = description.homepage:gsub('https', 'git')
}
build = {
  type = 'builtin',
  copy_directories = { 'doc' } ,
}

dependencies = { 'lua >= 5.1', 'dbus_proxy', 'ime >= 0.0.8', 'platformdirs', 'inifile' }
