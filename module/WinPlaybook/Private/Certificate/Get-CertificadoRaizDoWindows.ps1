function Get-CertificadoRaizDoWindows {
    <#
    .SYNOPSIS
    Devolve os certificados raiz em que o Windows confia, sem repetições.

    .DESCRIPTION
    Junta os repositórios Root do computador e do usuário, que incluem as autoridades
    instaladas por política de grupo, e devolve cada certificado uma vez só.

    .EXAMPLE
    Get-CertificadoRaizDoWindows

    Devolve os X509Certificate2 das autoridades raiz confiáveis do Windows.

    .LINK
    https://learn.microsoft.com/dotnet/api/system.security.cryptography.x509certificates.x509store
    #>
    [CmdletBinding()]
    [OutputType([Security.Cryptography.X509Certificates.X509Certificate2])]
    param()

    $certificados = [ordered]@{}
    foreach ($localDoRepositorio in 'LocalMachine', 'CurrentUser') {
        $repositorio = New-Object -TypeName Security.Cryptography.X509Certificates.X509Store -ArgumentList 'Root', $localDoRepositorio
        try {
            $repositorio.Open('ReadOnly, OpenExistingOnly')
            foreach ($certificado in $repositorio.Certificates) {
                $certificados[$certificado.Thumbprint] = $certificado
            }
        }
        catch [Security.Cryptography.CryptographicException] {
            continue
        }
        finally {
            $repositorio.Close()
        }
    }

    return @($certificados.Values)
}
