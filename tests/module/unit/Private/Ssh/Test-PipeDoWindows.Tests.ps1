BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../../../../../module/WinPlaybook/WinPlaybook.psd1') -Force
}

AfterAll {
    Remove-Module WinPlaybook
}

Describe 'Test-PipeDoWindows' {
    Context 'quando o pipe existe' {
        BeforeAll {
            $nomeDoPipe = "winplaybook-teste-$([guid]::NewGuid().ToString('N'))"
            $servidor = New-Object System.IO.Pipes.NamedPipeServerStream($nomeDoPipe, [System.IO.Pipes.PipeDirection]::InOut, 1, [System.IO.Pipes.PipeTransmissionMode]::Byte, [System.IO.Pipes.PipeOptions]::Asynchronous)
            $esperaPorConexao = $servidor.BeginWaitForConnection($null, $null)
        }

        AfterAll {
            $servidor.Dispose()
        }

        It 'devolve verdadeiro' {
            $existe = InModuleScope WinPlaybook -Parameters @{ Nome = $nomeDoPipe } { Test-PipeDoWindows -Nome $Nome }

            $existe | Should-BeTrue
        }

        It 'não conecta no pipe' {
            $null = InModuleScope WinPlaybook -Parameters @{ Nome = $nomeDoPipe } { Test-PipeDoWindows -Nome $Nome }

            $esperaPorConexao.IsCompleted | Should-BeFalse
        }
    }

    Context 'quando o pipe não existe' {
        It 'devolve falso' {
            $existe = InModuleScope WinPlaybook { Test-PipeDoWindows -Nome "winplaybook-inexistente-$([guid]::NewGuid().ToString('N'))" }

            $existe | Should-BeFalse
        }
    }
}
