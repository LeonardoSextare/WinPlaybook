using System;
using System.IO;
using System.IO.Pipes;
using System.Text;
using System.Threading;

internal static class RelayDoAgenteSsh
{
    private static int Main(string[] argumentos)
    {
        try
        {
            using (NamedPipeClientStream pipe = new NamedPipeClientStream(".", argumentos[0], PipeDirection.InOut, PipeOptions.Asynchronous))
            {
                pipe.Connect(2000);
                Stream saida = Console.OpenStandardOutput();
                Thread doAgenteParaOCliente = new Thread(() => pipe.CopyTo(saida));
                doAgenteParaOCliente.IsBackground = true;
                doAgenteParaOCliente.Start();
                Console.OpenStandardInput().CopyTo(pipe);
                return 0;
            }
        }
        catch (Exception erro)
        {
            Console.SetError(new StreamWriter(Console.OpenStandardError(), new UTF8Encoding(false)) { AutoFlush = true });
            Console.Error.WriteLine("WinPlaybook: " + erro.Message);
            return 1;
        }
    }
}
