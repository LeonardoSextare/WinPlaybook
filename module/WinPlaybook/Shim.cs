using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;

internal static class Shim
{
    private static int Main(string[] argumentos)
    {
        try
        {
            string caminhoDaConfiguracao = Path.ChangeExtension(Assembly.GetEntryAssembly().Location, ".shim");
            string programa = null;
            string argumentosDoPrograma = string.Empty;
            foreach (string linha in File.ReadAllLines(caminhoDaConfiguracao, Encoding.UTF8))
            {
                int posicaoDoIgual = linha.IndexOf('=');
                if (posicaoDoIgual < 0)
                {
                    continue;
                }

                string chave = linha.Substring(0, posicaoDoIgual).Trim();
                string valor = linha.Substring(posicaoDoIgual + 1).Trim();
                if (chave == "path")
                {
                    programa = valor;
                }
                else if (chave == "args")
                {
                    argumentosDoPrograma = valor;
                }
            }

            string argumentosCodificados = string.Join(" ", argumentos.Select(argumento => "x" + Convert.ToBase64String(Encoding.UTF8.GetBytes(argumento))));
            ProcessStartInfo inicio = new ProcessStartInfo(programa, (argumentosDoPrograma + " " + argumentosCodificados).Trim());
            inicio.UseShellExecute = false;

            Console.CancelKeyPress += (remetente, evento) => evento.Cancel = true;
            using (Process processo = Process.Start(inicio))
            {
                processo.WaitForExit();
                return processo.ExitCode;
            }
        }
        catch (Exception erro)
        {
            Console.Error.WriteLine("WinPlaybook: " + erro.Message);
            return 1;
        }
    }
}
