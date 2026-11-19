using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Threading;

internal static class RelayDeRede
{
    private static int Main(string[] argumentos)
    {
        try
        {
            if (argumentos[0] == "portas")
            {
                return ListarPortas();
            }

            IPAddress destino = argumentos.Length > 2 ? IPAddress.Parse(argumentos[2]) : null;
            return Conectar(int.Parse(argumentos[1]), destino);
        }
        catch (Exception erro)
        {
            Console.Error.WriteLine("WinPlaybook: " + erro.Message);
            return 1;
        }
    }

    private static int ListarPortas()
    {
        string anteriores = null;
        StreamWriter saida = new StreamWriter(Console.OpenStandardOutput());
        while (true)
        {
            IEnumerable<int> portas = IPGlobalProperties.GetIPGlobalProperties().GetActiveTcpListeners()
                .Where(escuta => IPAddress.IsLoopback(escuta.Address) || escuta.Address.Equals(IPAddress.Any) || escuta.Address.Equals(IPAddress.IPv6Any))
                .Select(escuta => escuta.Port)
                .Distinct()
                .OrderBy(porta => porta);
            string atuais = string.Join(" ", portas);
            if (atuais != anteriores)
            {
                saida.WriteLine(atuais);
                saida.Flush();
                anteriores = atuais;
            }

            Thread.Sleep(1000);
        }
    }

    private static int Conectar(int porta, IPAddress destino)
    {
        using (TcpClient cliente = destino == null ? AbrirConexao(porta) : AbrirConexaoNoDestino(destino, porta))
        {
            NetworkStream conexao = cliente.GetStream();
            Stream saida = Console.OpenStandardOutput();
            Thread doServidorParaOCliente = new Thread(() => Copiar(conexao, saida));
            doServidorParaOCliente.Start();
            Copiar(Console.OpenStandardInput(), conexao);
            try
            {
                cliente.Client.Shutdown(SocketShutdown.Send);
            }
            catch (SocketException)
            {
            }

            doServidorParaOCliente.Join();
            return 0;
        }
    }

    private static void Copiar(Stream origem, Stream destino)
    {
        try
        {
            origem.CopyTo(destino);
        }
        catch (IOException)
        {
        }
        catch (ObjectDisposedException)
        {
        }
    }

    private static TcpClient AbrirConexaoNoDestino(IPAddress destino, int porta)
    {
        TcpClient cliente = new TcpClient(destino.AddressFamily);
        try
        {
            cliente.NoDelay = true;
            cliente.Connect(destino, porta);
            return cliente;
        }
        catch
        {
            cliente.Close();
            throw;
        }
    }

    private static TcpClient AbrirConexao(int porta)
    {
        TcpClient cliente = new TcpClient(AddressFamily.InterNetwork);
        try
        {
            cliente.Connect(IPAddress.Loopback, porta);
            return cliente;
        }
        catch (SocketException)
        {
            cliente.Close();
        }

        TcpClient clienteIPv6 = new TcpClient(AddressFamily.InterNetworkV6);
        clienteIPv6.Connect(IPAddress.IPv6Loopback, porta);
        return clienteIPv6;
    }
}
