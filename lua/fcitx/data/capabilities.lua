---don't use json due to unsupported 2^x syntax.
---https://github.com/fcitx/fcitx5/blob/master/src/lib/fcitx-utils/capabilityflags.h
local M = {
    NoFlag = 0,
    ClientSideUI = 2 ^ 0,
    Preedit = 2 ^ 1,
    ClientSideControlState = 2 ^ 2,
    Password = 2 ^ 3,
    FormattedPreedit = 2 ^ 4,
    ClientUnfocusCommit = 2 ^ 5,
    SurroundingText = 2 ^ 6,
    Email = 2 ^ 7,
    Digit = 2 ^ 8,
    Uppercase = 2 ^ 9,
    Lowercase = 2 ^ 10,
    NoAutoUpperCase = 2 ^ 11,
    Url = 2 ^ 12,
    Dialable = 2 ^ 13,
    Number = 2 ^ 14,
    SpellCheck = 2 ^ 16,
    NoSpellCheck = 2 ^ 17,
    WordCompletion = 2 ^ 18,
    UppercaseWords = 2 ^ 19,
    UppwercaseSentences = 2 ^ 20,
    Alpha = 2 ^ 21,
    Name = 2 ^ 22,
    GetIMInfoOnFocus = 2 ^ 23,
    RelativeRect = 2 ^ 24,
    -- 25 ~ 31 are reserved for fcitx 4 compatibility.
    -- New addition in fcitx 5.
    Terminal = 2 ^ 32,
    Date = 2 ^ 33,
    Time = 2 ^ 34,
    Multiline = 2 ^ 35,
    Sensitive = 2 ^ 36,
    KeyEventOrderFix = 2 ^ 37,
    ReportKeyRepeat = 2 ^ 38,
    ClientSideInputPanel = 2 ^ 39,
    Disable = 2 ^ 40,
    CommitStringWithCursor = 2 ^ 41,
}
M.PasswordOrSensitive = M.Password + M.Sensitive
return M
