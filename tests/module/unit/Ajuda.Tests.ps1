BeforeDiscovery {
    $pastaDoModulo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../module/WinPlaybook'))
    $funcoes = foreach ($arquivo in Get-ChildItem -LiteralPath $pastaDoModulo -Recurse -File | Where-Object { $_.Extension -in '.ps1', '.psm1' }) {
        $arvore = [Management.Automation.Language.Parser]::ParseFile($arquivo.FullName, [ref] $null, [ref] $null)
        $definicoes = $arvore.FindAll({ param($no) $no -is [Management.Automation.Language.FunctionDefinitionAst] }, $false)
        foreach ($definicao in $definicoes) {
            $ajuda = $definicao.GetHelpContent()
            $parametros = @()
            $temBlocoDeParametros = $null -ne $definicao.Body.ParamBlock
            if ($temBlocoDeParametros) {
                $parametros = @($definicao.Body.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath.ToUpperInvariant() })
            }
            $parametrosDaAjuda = @()
            $temAjuda = $null -ne $ajuda
            if ($temAjuda) {
                $parametrosDaAjuda = @($ajuda.Parameters.Keys | ForEach-Object { $_.ToUpperInvariant() })
            }
            Write-Output @{
                Funcao            = $definicao.Name
                TemAjuda          = $temAjuda
                Ajuda             = $ajuda
                Parametros        = $parametros
                ParametrosDaAjuda = $parametrosDaAjuda
            }
        }
    }
}

Describe 'Ajuda das funções do módulo' {
    Context 'em <Funcao>' -ForEach $funcoes {
        It 'tem ajuda com .SYNOPSIS e pelo menos um .EXAMPLE' {
            $TemAjuda | Should-BeTrue
            $Ajuda.Synopsis | Should-NotBeNull
            $Ajuda.Examples.Count | Should-BeGreaterThan 0
        }

        It 'documenta cada parâmetro com .PARAMETER' {
            Should-BeCollection -Actual @($ParametrosDaAjuda | Sort-Object) -Expected @($Parametros | Sort-Object)
        }
    }
}
