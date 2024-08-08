local consts = require("fcitx5-ui.consts")

local M = {}
local M_private = {}

M_private.setuped = false

---Configuration of fcitx5-ui.
---@class fcitx5_ui_configuration
local configuration = {
        trigger = nil,
        keymap = {
                ['<Up>'] = { consts.FcitxKey.up, consts.FcitxKeyState.no },
                ['<Down>'] = { consts.FcitxKey.down, consts.FcitxKeyState.no },
                ['<Left>'] = { consts.FcitxKey.left, consts.FcitxKeyState.no },
                ['<Right>'] = { consts.FcitxKey.right, consts.FcitxKeyState.no },
                ['<CR>'] = { consts.FcitxKey.enter, consts.FcitxKeyState.no },
                ['<BS>'] = { consts.FcitxKey.backspace, consts.FcitxKeyState.no },
                ['<Tab>'] = { consts.FcitxKey.tab, consts.FcitxKeyState.no },
                ['<S-Tab>'] = { consts.FcitxKey.tab, consts.FcitxKeyState.shift },
                ['<C-@>'] = { consts.FcitxKey.grave_accent, consts.FcitxKeyState.ctrl },
                ['<C-Space>'] = { consts.FcitxKey.grave_accent, consts.FcitxKeyState.ctrl },
        },
        prev = "<|",
        next = "|>",
        update = 50,
}
do
        -- Maintain the name of current input method.

        ---Fields is nil if fcitx5-ui is not currently activated.
        ---@class fcitx5_ui_input_method_status
        local current_input_method_status = {
                ---@type string?
                name = nil,
                ---@type string?
                unique_name = nil,
                ---@type string?
                language_code = nil,
        }

        ---Get the current input method status.
        ---@return fcitx5_ui_input_method_status
        M.get_current_input_method_status = function()
                return current_input_method_status
        end

        ---Set the current input method status.
        ---@param name string?
        ---@param unique_name string?
        ---@param language_code string?
        M_private.set_current_input_method_status = function(name,
                                                             unique_name,
                                                             language_code)
                current_input_method_status = {
                        name = name,
                        user_name = unique_name,
                        language_code = language_code,
                }
        end
end

--- Keep for compatibility of vim-airline.
--- You should write this in your own configuration.
--- @deprecated
M.displayCurrentIM = function()
        local mode = vim.fn.mode():sub(1, 1)
        if mode ~= 'i' and mode ~= 'R' then
                return ""
        end
        return M.get_current_input_method_status().unique_name
end

do
        -- Maintain the neovim buffer for candidates selection.

        ---@type integer?
        local buffer = nil
        M_private.get_buffer = function()
                if buffer ~= nil then
                        return buffer
                end
                buffer = vim.api.nvim_create_buf(false, true)
                return buffer
        end

        -- FIXME: Provide a way to release this neovim buffer.
end

do
        -- Maintain the neovim float window for candidates selection.

        ---@type integer?
        local window = nil

        M_private.update_window = function(lines, config)
                vim.api.nvim_buf_set_lines(
                        M_private.get_buffer(), 0, config.height, false, lines)

                if window ~= nil then
                        vim.api.nvim_win_set_config(window, config)
                        return
                end

                window = vim.api.nvim_open_win(
                        M_private.get_buffer(), false, config)
        end

        M_private.close_window = function()
                if window == nil then
                        return
                end

                vim.api.nvim_win_close(window, true)
                window = nil
        end
end

do
        -- Register signal handlers for org.fcitx.Fcitx.InputContext1.

        local signal_handlers = {}

        ---@param fcitx5_dbus_input_context table org.fcitx.Fcitx.InputContext1
        M_private.connect_signal_handlers = function(fcitx5_dbus_input_context)
                for signal, handler in pairs(signal_handlers) do
                        fcitx5_dbus_input_context:connect_signal(
                                handler,
                                signal
                        )
                end
        end

        ---Handler of org.fcitx.Fcitx.InputContext1.CurrentIM signal.
        ---@param self table
        ---@param name string
        ---@param unique_name string
        ---@param language_code string
        ---@return nil
        ---@diagnostic disable-next-line: unused-local
        signal_handlers.CurrentIM = function(self,
                                             name, unique_name, language_code)
                M_private.set_current_input_method_status(
                        name, unique_name, language_code)
        end

        ---Handler of org.fcitx.Fcitx.InputContext1.CommitString signal.
        ---@param self table
        ---@param str string
        ---@return nil
        ---@diagnostic disable-next-line: unused-local
        signal_handlers.CommitString = function(self, str)
                -- NOTE:
                -- Do not use `vim.api.nvim_feedkeys` here.
                -- It will trigger InsertCharPre again.
                local r, c = unpack(vim.api.nvim_win_get_cursor(0))
                vim.api.nvim_buf_set_text(
                        0, r - 1, c, r - 1, c, { str }
                )
                vim.api.nvim_win_set_cursor(0, { r, c + #str })
        end

        ---Handler of org.fcitx.Fcitx.InputContext1.ForwardKey signal.
        ---@param self table
        ---@param key_sym integer
        ---@param state integer
        ---@param release boolean
        ---@return nil
        ---@diagnostic disable-next-line: unused-local
        signal_handlers.ForwardKey = function(self,
                                              key_sym, state, release)
                vim.print("forword key: " .. key_sym)
                if release then
                        return
                end

                local key = string.char(key_sym)

                if state == consts().FcitxKeyState.shift then
                        key = "\\<S-" .. key .. ">"
                elseif state == consts().FcitxKeyState.alt then
                        key = "\\<M-" .. key .. ">"
                elseif state == consts().FcitxKeyState.ctrl then
                        key = "\\<C-" .. key .. ">"
                end

                vim.api.nvim_feedkeys(key, 'm', true)
        end


        ---Handler of org.fcitx.Fcitx.InputContext1.UpdateClientSideUI signal.
        ---FIXME: find out what these parameters are.
        ---
        ---@param self table
        ---@param preedit any TODO: add documentation.
        ---@param cursor any TODO: add documentation.
        ---@param aux_up any TODO: add documentation.
        ---@param aux_down any TODO: add documentation.
        ---@param candidates any TODO: add documentation.
        ---@param candidate_index any TODO: add documentation.
        ---@param layout_hint any TODO: add documentation.
        ---@param has_prev boolean
        ---@param has_next boolean
        ---@diagnostic disable-next-line: unused-local
        signal_handlers.UpdateClientSideUI = function(self,
                                                      preedit, cursor,
                                                      aux_up, aux_down,
                                                      candidates,
                                                      candidate_index,
                                                      layout_hint,
                                                      has_prev, has_next)
                ---@diagnostic disable-next-line:empty-block
                if layout_hint ~= consts.FcitxCandidateLayoutHint.Horizontal then
                        -- TODO: Implement vertical layout.
                end

                --- FIXME:
                --- This is just a trick to work at common situation.
                --- We need to find out how aux repersents strings to display.
                local function getstr(aux)
                        if #aux <= 0 then
                                return ""
                        end

                        local result = ""

                        for _, value in pairs(aux) do
                                result = result .. value[1]
                        end

                        return result
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

                        if string.sub(preedit, _tmp, _tmp) == " " then
                                _tmp = _tmp - 1
                        end

                        preedit =
                            string.sub(preedit, 0, _tmp) .. "|" ..
                            string.sub(preedit, cursor + 1, #preedit)
                end

                local prev = configuration.prev
                if not has_prev then prev = "" end
                local next = configuration.next
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

                local candidates_str = table.concat(candidates_)
                if #candidates_str > 0
                    and string.sub(candidates_str, #candidates_str) ~= ']' then
                        candidates_str = candidates_str .. ' '
                end

                local lines = {
                        aux_up .. string.rep(" ", aux_up_free) .. preedit,
                        aux_down .. string.rep(" ", aux_down_free) ..
                        prev .. candidates_str .. next,
                }

                local height = #lines

                if #lines[2] == aux_down_free then
                        table.remove(lines, 2)
                        height = 1
                end

                local width = 0
                for _, s in ipairs(lines) do
                        width = math.max(width, vim.api.nvim_strwidth(s))
                end

                if width <= 0 then
                        M_private.close_window()
                        return
                end

                local config = {
                        relative = 'cursor',
                        width = width,
                        height = height,
                        row = 1,
                        col = -aux_up_width - aux_up_free,
                        style = 'minimal'
                }

                M_private.update_window(lines, config)
        end
end

do
        -- Maintain the org.fcitx.Fcitx.InputContext1 DBus object proxy.

        local fcitx5_input_context1_object = nil

        M_private.get_input_context = function()
                if fcitx5_input_context1_object ~= nil then
                        return fcitx5_input_context1_object
                end

                local dbus_proxy = require("dbus_proxy")

                ---@type table: A org.fcitx.Fcitx.InputMethod1 DBus object proxy.
                local fcitx5_input_method1_object = dbus_proxy.Proxy:new({
                        bus = dbus_proxy.Bus.SESSION,
                        name = consts.FcitxDBusName,
                        interface = consts.FcitxInputMethod1DBusInterface,
                        path = consts.FcitxInputMethod1DBusPath,
                })

                assert(
                        fcitx5_input_method1_object ~= nil,
                        "Failed create DBus object proxy of " ..
                        "org.fcitx.Fcitx.InputMethod1."
                )

                local dbus_result, err =
                    fcitx5_input_method1_object:CreateInputContext({
                            { "program", consts.FcitxInputContextProgram },
                            { "display", consts.FcitxInputContextProgram },
                    })

                assert(err == nil, tostring(err))

                local fcitx5_input_context_dbus_object_path, _ =
                    table.unpack(dbus_result)

                ---@type table: A org.fcitx.Fcitx.InputContext1 DBus object proxy.
                fcitx5_input_context1_object = dbus_proxy.Proxy:new({
                        bus = dbus_proxy.Bus.SESSION,
                        name = consts.FcitxDBusName,
                        interface = consts.FcitxInputContext1DBusInterface,
                        path = fcitx5_input_context_dbus_object_path,
                })

                _, err =
                    fcitx5_input_context1_object:SetCapability(
                            consts.PluginCapabilities
                    )

                assert(err == nil, tostring(err))

                return fcitx5_input_context1_object
        end

        -- FIXME: Provide a way to release this DBus object proxy.
end

---Setup fcitx5-ui.
---@param config fcitx5_ui_configuration
M.setup = function(config)
        configuration = vim.tbl_deep_extend("keep", config, configuration)
        assert(configuration.trigger ~= nil, "You must specify `trigger`.")

        local input_context = M_private.get_input_context()
        M_private.connect_signal_handlers(input_context)

        M_private.setuped = true
end

M_private.process_key = function(input)
        local state
        if configuration.keymap[input] then
                input, state = unpack(configuration.keymap[input])
        else
                input = string.byte(input)
                state = consts.FcitxKeyState.no
        end

        local accept, err = M_private.get_input_context():ProcessKeyEvent(
                input, 0, state, false, 0)

        assert(accept ~= nil, tostring(err))

        if accept then
                vim.v.char = ''
        end

        return accept
end

do
        ---@type integer?
        local aug = nil

        M_private.create_augroup = function()
                if aug ~= nil then
                        return aug
                end

                aug = vim.api.nvim_create_augroup("fcitx5_ui", {})
                vim.api.nvim_create_autocmd(
                        { "InsertCharPre" },
                        {
                                group = "fcitx5_ui",
                                pattern = "<buffer>",
                                callback = function()
                                        M_private.process_key(vim.v.char)
                                end
                        })
                vim.api.nvim_create_autocmd(
                        { "InsertLeave" },
                        {
                                group = "fcitx5_ui",
                                pattern = "*",
                                callback = function()
                                        M_private.reset()
                                end
                        })
                vim.api.nvim_create_autocmd(
                        { "WinLeave", "BufLeave" },
                        {
                                group    = "fcitx5_ui",
                                pattern  = "*",
                                callback = function()
                                        M_private.reset()
                                        M.deactivate(true)
                                end
                        })

                return aug
        end

        M_private.remove_augroup = function()
                if aug == nil then
                        return
                end

                vim.api.nvim_del_augroup_by_id(aug)
                aug = nil
        end
end

do
        ---@type integer?
        local timer = nil

        M_private.start_timer = function()
                assert(timer == nil, "Bug detected: timer is not nil")

                timer = vim.fn.timer_start(configuration.update, function()
                        require('lgi').GLib.MainLoop():get_context():iteration()
                end, { ["repeat"] = -1 })
        end

        M_private.stop_timer = function()
                if timer == nil then
                        return
                end

                vim.fn.timer_stop(timer)
                timer = nil
        end
end

M_private.create_keymaps = function()
        for key, _ in pairs(configuration.keymap) do
                vim.keymap.set({ 'i' }, key, function()
                        if M_private.process_key(key) then
                                return nil
                        end
                        return key
                end, { expr = true, buffer = true })
        end
end

M_private.delete_keymaps = function()
        for key, _ in pairs(configuration.keymap) do
                vim.keymap.del({ 'i' }, key, { buffer = true })
        end
end

do
        local activated = false;

        M.toggle = function()
                assert(M_private.setuped, "You must call `setup` first.")

                if activated then
                        M.deactivate()
                        return
                end

                M.activate()
        end

        ---@param force boolean?
        M.activate = function(force)
                assert(M_private.setuped, "You must call `setup` first.")

                if (not force) and activated then
                        error("fcitx5-ui is already activated.")
                end

                M_private.process_key(configuration.trigger)
                M_private.create_augroup()
                M_private.start_timer()
                M_private.create_keymaps()
                activated = true
        end

        ---@param force boolean?
        M.deactivate = function(force)
                assert(M_private.setuped, "You must call `setup` first.")

                if (not force) and not activated then
                        error("fcitx5-ui is not activated.")
                end

                M_private.process_key(configuration.trigger)
                M_private.remove_augroup()
                M_private.stop_timer()
                M_private.delete_keymaps()
                activated = false
                M_private.set_current_input_method_status()
                M_private.reset()
        end

        M_private.reset = function()
                M_private.get_input_context():Reset()
                M_private.close_window()
        end
end

return M
