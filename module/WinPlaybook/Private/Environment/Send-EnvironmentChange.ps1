function Send-EnvironmentChange {
    <#
    .SYNOPSIS
    Tells the open programs, such as Explorer, that the environment variables of the user changed.

    .DESCRIPTION
    Programs read the environment when they start. Explorer passes its own copy to the
    terminals it opens, so without this notice they keep the old Path until the next logon.

    .EXAMPLE
    Send-EnvironmentChange

    .LINK
    https://learn.microsoft.com/windows/win32/api/winuser/nf-winuser-sendmessagetimeoutw

    .LINK
    https://learn.microsoft.com/windows/win32/winmsg/wm-settingchange
    #>
    [CmdletBinding()]
    param()

    $isNotifierLoaded = [bool] ('WinPlaybook.EnvironmentNotifier' -as [type])
    if (-not $isNotifierLoaded) {
        $declaration = @(
            '[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]'
            'public static extern IntPtr SendMessageTimeout('
            '    IntPtr window,'
            '    uint message,'
            '    UIntPtr unusedParameter,'
            '    string changedSetting,'
            '    uint flags,'
            '    uint timeoutMilliseconds,'
            '    out UIntPtr result'
            ');'
        ) -join [Environment]::NewLine
        Add-Type -Namespace 'WinPlaybook' -Name 'EnvironmentNotifier' -MemberDefinition $declaration
    }

    $result = [UIntPtr]::Zero
    [WinPlaybook.EnvironmentNotifier]::SendMessageTimeout(
        [IntPtr] 0xffff,   # HWND_BROADCAST: every top-level window
        0x1A,              # WM_SETTINGCHANGE
        [UIntPtr]::Zero,   # not used by this message
        'Environment',     # the setting that changed
        2,                 # SMTO_ABORTIFHUNG
        200,               # wait per window, in milliseconds
        [ref] $result
    ) | Out-Null
}
