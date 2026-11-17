BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'ConvertTo-PathDoWindowsNaDistribuicao' {
    It 'converte cada pasta para a montagem com execução, na ordem do Path' {
        $pastas = InModuleScope WinPlaybook { ConvertTo-PathDoWindowsNaDistribuicao -Path 'C:\WINDOWS\system32;D:\Ferramentas\bin\;C:\Program Files\Git\cmd' -PastaDosShims 'C:\shims' }

        $pastas | Should-BeCollection @('/opt/winplaybook/exec/c/WINDOWS/system32', '/opt/winplaybook/exec/d/Ferramentas/bin', '/opt/winplaybook/exec/c/Program Files/Git/cmd')
    }

    It 'deixa de fora a pasta dos shims, com outra caixa e com a barra no fim' {
        $pastas = InModuleScope WinPlaybook { ConvertTo-PathDoWindowsNaDistribuicao -Path 'C:\Ferramentas;c:\users\eu\winplaybook\BIN\' -PastaDosShims 'C:\Users\eu\WinPlaybook\bin' }

        $pastas | Should-BeCollection @('/opt/winplaybook/exec/c/Ferramentas')
    }

    It 'deixa de fora as pastas vazias, as repetidas e as que não têm a letra da unidade' {
        $pastas = InModuleScope WinPlaybook { ConvertTo-PathDoWindowsNaDistribuicao -Path 'C:\Ferramentas;;\servidor\ferramentas;%SEM_EXPANDIR%;c:\ferramentas' -PastaDosShims '' }

        $pastas | Should-BeCollection @('/opt/winplaybook/exec/c/Ferramentas')
    }
}
