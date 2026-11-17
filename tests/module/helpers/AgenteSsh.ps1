function Start-AgenteSshFalso {
    <#
    .SYNOPSIS
    Inicia um agente SSH falso num named pipe do Windows com nome próprio e devolve os dados dele.

    .DESCRIPTION
    O agente atende uma conexão por vez, em segundo plano. Ao pedido de chaves
    (SSH_AGENTC_REQUEST_IDENTITIES) ele responde com uma chave ed25519 com o comentário
    winplaybook-agente-falso, e aos outros pedidos responde com falha (SSH_AGENT_FAILURE).
    Devolve um objeto com o nome do pipe (Nome), o comentário da chave (Comentario), o pedido
    de chaves (PedidoDeChaves) e a resposta a ele (RespostaDeChaves), em bytes. Pare o agente
    com Stop-AgenteSshFalso.

    .EXAMPLE
    $agente = Start-AgenteSshFalso

    .LINK
    https://datatracker.ietf.org/doc/html/draft-ietf-sshm-ssh-agent
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $nome = "winplaybook-teste-$([guid]::NewGuid().ToString('N'))"
    $comentario = 'winplaybook-agente-falso'

    $converteTexto = {
        param([byte[]] $Bytes)
        $tamanho = [BitConverter]::GetBytes([uint32] $Bytes.Length)
        [Array]::Reverse($tamanho)
        return , [byte[]] ($tamanho + $Bytes)
    }
    $chavePublica = (& $converteTexto ([Text.Encoding]::ASCII.GetBytes('ssh-ed25519'))) + (& $converteTexto ([byte[]] (1..32)))
    $corpo = [byte[]] (@(12, 0, 0, 0, 1) + (& $converteTexto $chavePublica) + (& $converteTexto ([Text.Encoding]::ASCII.GetBytes($comentario))))
    $respostaDeChaves = & $converteTexto $corpo

    $estado = [hashtable]::Synchronized(@{ Parar = $false })
    $powershell = [powershell]::Create()
    $null = $powershell.AddScript({
            param($Nome, $Estado, $RespostaDeChaves)

            function Read-Byte {
                param($Stream, [int] $Quantidade)
                $buffer = New-Object byte[] $Quantidade
                $lidos = 0
                while ($lidos -lt $Quantidade) {
                    $leitura = $Stream.Read($buffer, $lidos, $Quantidade - $lidos)
                    if ($leitura -eq 0) {
                        return $null
                    }
                    $lidos += $leitura
                }
                return , $buffer
            }

            while (-not $Estado.Parar) {
                $servidor = New-Object System.IO.Pipes.NamedPipeServerStream($Nome, [System.IO.Pipes.PipeDirection]::InOut, 254)
                try {
                    $servidor.WaitForConnection()
                    while ($true) {
                        $cabecalho = Read-Byte -Stream $servidor -Quantidade 4
                        if ($null -eq $cabecalho) {
                            break
                        }
                        [Array]::Reverse($cabecalho)
                        $pedido = Read-Byte -Stream $servidor -Quantidade ([BitConverter]::ToUInt32($cabecalho, 0))
                        if ($null -eq $pedido) {
                            break
                        }
                        $resposta = [byte[]] (0, 0, 0, 1, 5)
                        if ($pedido[0] -eq 11) {
                            $resposta = $RespostaDeChaves
                        }
                        $servidor.Write($resposta, 0, $resposta.Length)
                        $servidor.Flush()
                    }
                }
                catch {
                    $null = $_
                }
                finally {
                    $servidor.Dispose()
                }
            }
        }).AddArgument($nome).AddArgument($estado).AddArgument($respostaDeChaves)
    $execucao = $powershell.BeginInvoke()

    $limite = (Get-Date).AddSeconds(10)
    while (-not ([IO.Directory]::GetFiles('\\.\pipe\') -contains "\\.\pipe\$nome") -and (Get-Date) -lt $limite) {
        Start-Sleep -Milliseconds 50
    }

    return [pscustomobject]@{
        Nome             = $nome
        Comentario       = $comentario
        PedidoDeChaves   = [byte[]] (0, 0, 0, 1, 11)
        RespostaDeChaves = $respostaDeChaves
        PowerShell       = $powershell
        Execucao         = $execucao
        Estado           = $estado
    }
}

function Stop-AgenteSshFalso {
    <#
    .SYNOPSIS
    Para o agente SSH falso que Start-AgenteSshFalso iniciou e apaga o pipe dele.

    .PARAMETER Agente
    O objeto que Start-AgenteSshFalso devolveu.

    .EXAMPLE
    Stop-AgenteSshFalso -Agente $agente
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)] [pscustomobject] $Agente
    )

    $Agente.Estado.Parar = $true
    $cliente = New-Object System.IO.Pipes.NamedPipeClientStream('.', $Agente.Nome, [System.IO.Pipes.PipeDirection]::InOut)
    try {
        $cliente.Connect(2000)
    }
    catch {
        $null = $_
    }
    finally {
        $cliente.Dispose()
    }
    $null = $Agente.Execucao.AsyncWaitHandle.WaitOne(5000)
    $Agente.PowerShell.Dispose()
}
