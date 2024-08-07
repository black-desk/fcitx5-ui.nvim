local FcitxUserInterfaceCapabilityClientSideInputPanel = 2 ^ 39
local FcitxUserInterfaceCapabilityKeyEventOrderFix = 2 ^ 37

return {
        FcitxInputContextProgram        = "fcitx5-ui.nvim",
        FcitxInputContextDisplay        = "fcitx5-ui.nvim",
        PluginCapabilities              =
            FcitxUserInterfaceCapabilityClientSideInputPanel +
            FcitxUserInterfaceCapabilityKeyEventOrderFix,
        FcitxDBusName                   = "org.freedesktop.portal.Fcitx",
        FcitxInputMethod1DBusPath       = "/org/freedesktop/portal/inputmethod",
        FcitxInputMethod1DBusInterface  = "org.fcitx.Fcitx.InputMethod1",
        FcitxInputContext1DBusInterface = "org.fcitx.Fcitx.InputContext1",
        FcitxKey                        = {
                backspace    = 0xff08,
                space        = 0x0020,
                left         = 0xff51,
                up           = 0xff52,
                right        = 0xff53,
                down         = 0xff54,
                enter        = 0xff0d,
                tab          = 0xfe20,
                grave_accent = 0x0060, -- backtick
        },
        FcitxKeyState                   = {
                no    = 0,
                shift = 1,
                ctrl  = 4,
                alt   = 8,
                super = 64,
        },
        FcitxCandidateLayoutHint        = {
                NotSet = 0,
                Vertical = 1,
                Horizontal = 2,
        }
}
