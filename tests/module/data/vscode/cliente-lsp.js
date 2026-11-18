const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const [servidor, projeto] = process.argv.slice(2);
const playbook = path.join(projeto, 'site.yml');
const texto = fs.readFileSync(playbook, 'utf8');
const uriDoProjeto = 'file:///' + projeto.replace(/\\/g, '/');
const uriDoPlaybook = 'file:///' + playbook.replace(/\\/g, '/');
const filho = spawn(process.execPath, [servidor, '--stdio'], { env: process.env, stdio: ['pipe', 'pipe', 'ignore'] });
const pendentes = new Map();
const esperas = [];
let buffer = Buffer.alloc(0);
let proximoId = 1;

function escrever(registro) {
  process.stdout.write(JSON.stringify(registro) + '\n');
}

function enviar(mensagem) {
  const corpo = Buffer.from(JSON.stringify(Object.assign({ jsonrpc: '2.0' }, mensagem)));
  filho.stdin.write(`Content-Length: ${corpo.length}\r\n\r\n`);
  filho.stdin.write(corpo);
}

function pedir(metodo, parametros) {
  const id = proximoId++;
  enviar({ id, method: metodo, params: parametros });
  return new Promise((resolver) => pendentes.set(id, resolver));
}

function esperar(condicao, milissegundos) {
  return new Promise((resolver) => {
    const espera = { condicao, resolver };
    esperas.push(espera);
    setTimeout(() => resolver(null), milissegundos);
  });
}

function avisar(mensagem) {
  for (const espera of esperas) {
    if (espera.condicao(mensagem)) {
      espera.resolver(mensagem);
    }
  }
}

filho.stdout.on('data', (dados) => {
  buffer = Buffer.concat([buffer, dados]);
  while (true) {
    const fim = buffer.indexOf('\r\n\r\n');
    if (fim < 0) {
      return;
    }
    const tamanho = parseInt(/Content-Length: (\d+)/i.exec(buffer.slice(0, fim).toString())[1], 10);
    if (buffer.length < fim + 4 + tamanho) {
      return;
    }
    const mensagem = JSON.parse(buffer.slice(fim + 4, fim + 4 + tamanho).toString());
    buffer = buffer.slice(fim + 4 + tamanho);
    if (mensagem.id !== undefined && pendentes.has(mensagem.id)) {
      pendentes.get(mensagem.id)(mensagem.result);
      pendentes.delete(mensagem.id);
    } else if (mensagem.id !== undefined && mensagem.method) {
      enviar({ id: mensagem.id, result: null });
    } else {
      avisar(mensagem);
    }
  }
});

function posicao(trecho) {
  const linhas = texto.split('\n');
  for (let linha = 0; linha < linhas.length; linha++) {
    const coluna = linhas[linha].indexOf(trecho);
    if (coluna >= 0) {
      return { line: linha, character: coluna + trecho.length - 1 };
    }
  }
  throw new Error('trecho não encontrado: ' + trecho);
}

function textoDoHover(hover) {
  return hover && hover.contents ? (hover.contents.value || JSON.stringify(hover.contents)) : '';
}

(async () => {
  await pedir('initialize', { processId: process.pid, rootUri: uriDoProjeto, workspaceFolders: [{ uri: uriDoProjeto, name: 'projeto' }], capabilities: { textDocument: { hover: { contentFormat: ['markdown', 'plaintext'] } } } });
  enviar({ method: 'initialized', params: {} });
  enviar({ method: 'textDocument/didOpen', params: { textDocument: { uri: uriDoPlaybook, languageId: 'ansible', version: 1, text: texto } } });
  let hoverDoBuiltin = '';
  for (let tentativa = 0; tentativa < 30 && !hoverDoBuiltin; tentativa++) {
    await new Promise((resolver) => setTimeout(resolver, 3000));
    hoverDoBuiltin = textoDoHover(await pedir('textDocument/hover', { textDocument: { uri: uriDoPlaybook }, position: posicao('ansible.builtin.debug') }));
  }
  escrever({ tipo: 'hover', modulo: 'ansible.builtin.debug', texto: hoverDoBuiltin });
  escrever({ tipo: 'hover', modulo: 'community.general.ini_file', texto: textoDoHover(await pedir('textDocument/hover', { textDocument: { uri: uriDoPlaybook }, position: posicao('community.general.ini_file') })) });
  const diagnosticos = esperar((m) => m.method === 'textDocument/publishDiagnostics' && m.params.diagnostics.length > 0, hoverDoBuiltin ? 180000 : 0);
  enviar({ method: 'textDocument/didSave', params: { textDocument: { uri: uriDoPlaybook } } });
  const publicados = await diagnosticos;
  escrever({ tipo: 'diagnosticos', mensagens: publicados ? publicados.params.diagnostics.map((d) => `${d.source}: ${d.code || ''} ${d.message}`) : [] });
  filho.kill();
  process.exit(0);
})();
