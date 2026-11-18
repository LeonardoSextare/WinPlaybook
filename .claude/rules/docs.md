---
paths:
  - "docs/**"
---

# Documentação

Site em Zensical, publicado no GitHub Pages, em português (`docs/pt-br/`) e
inglês (`docs/en/`).

## Público

- Documentação para quem usa o WinPlaybook, do básico ao avançado. Pode ter
  conteúdo técnico, mas sempre sobre usar o WinPlaybook: nada sobre
  desenvolver o projeto (testes, CI, estrutura do código).
- Público técnico, da área de TI.
- Só entra na documentação o que tem uso real. Opções e variáveis criadas
  para testes (como as variáveis `WINPLAYBOOK_TEST_`) ficam de fora até
  existir um caso real de usuário.

## Organização

A documentação segue o modelo Diátaxis, na versão desta seção. A fonte é o
[diataxis.fr](https://diataxis.fr/); para dúvidas que esta seção não
resolve, consulte a fonte, mas o que está escrito aqui prevalece.

### Os quatro tipos

Toda página é de um tipo só. Para classificar, responda duas perguntas: a
página orienta uma ação ou um entendimento? O leitor está estudando ou
trabalhando?

|                  | Estudando  | Trabalhando |
| ---------------- | ---------- | ----------- |
| **Ação**         | Tutorial   | Guia how-to |
| **Entendimento** | Explicação | Referência  |

- **Tutorial**: uma aula, do zero até um resultado. Um caminho só, sem
  alternativas nem escolhas; mostra resultado cedo; explica o mínimo e deixa
  o porquê para uma explicação. Precisa funcionar sempre.
- **Guia how-to**: uma receita para um objetivo concreto, para quem já sabe
  usar. O título diz o objetivo; não ensina; pode ter alternativas
  ("se você usa o PowerShell 7…"); corta o que não serve ao objetivo.
  Instalação e solução de problemas são guias how-to.
- **Referência**: descrição seca e neutra, para consulta. A estrutura espelha
  o produto (um comando por seção, os parâmetros sempre no mesmo formato);
  exemplos só para ilustrar. Não ensina nem opina.
- **Explicação**: uma conversa sobre um assunto (por que o WinPlaybook usa o
  WSL, como os shims funcionam). Contexto, decisões, alternativas e
  limitações; é o único tipo com espaço para opinião.

Os erros mais comuns ficam na fronteira entre tipos vizinhos: o tutorial que
vira lista de receitas, a receita que para para ensinar, a referência que
começa a explicar o porquê. Quando um texto pede o outro tipo, deixe uma
frase curta com link para a página certa, e não misture.

### A estrutura cresce com o conteúdo

- Não crie seções ou páginas vazias antes de ter conteúdo para elas. O site
  começa pequeno e cresce uma página por vez.
- Cada iteração: escolha uma página (nova ou existente, no máximo uma),
  avalie que necessidade do leitor ela atende e quão bem, decida uma
  melhoria e entregue (seção Fluxo). Um PR por iteração.
- O `nav` dos dois tomls cresce junto. Uma aba nova surge quando já existe
  conteúdo para agrupar nela; nunca há aba vazia.

## Guias how-to na prática

- Só o que o leitor faz: comando, onde executar e o resultado esperado. O
  porquê e o funcionamento por dentro vão para uma explicação, com no máximo
  um link.
- Ramificações e erros (execution policy, política de grupo, proxy,
  firewall) vão para a página de solução de problemas, não para o passo a
  passo. As mensagens de erro do produto orientam o leitor no momento.
- Aviso só quando pede uma ação do leitor naquele ponto, e fica antes do
  passo a que se refere.
- Nenhum comando que o leitor possa executar por engano achando que é o
  passo.
- Introdução de uma ou duas frases: o que a página oferece e qual opção
  escolher.
- Requisitos em tabela curta, com o item e a versão. Sem requisitos de
  terceiros (os do WSL ficam na documentação da Microsoft) e sem como
  verificar.
- Alternativas principais da mesma página (como as formas de instalação) em
  seções separadas por `---`.

## Fluxo

1. Escreva em português, que é a fonte (seção Português).
2. Adapte para o inglês a partir do português (seção Inglês).
3. Revise e entregue os dois idiomas juntos (seção Revisão e entrega).

Os dois idiomas existem sempre juntos e têm a mesma informação: nenhum tem
conteúdo, aviso ou exemplo que o outro não tenha.

Na dúvida entre incluir e cortar, corte. O leitor pede o que falta, mas não
percebe o excesso, que só atrapalha.

## Português

A fonte da documentação, escrita para o público técnico brasileiro. O
usuário revisa o texto em português, e o estilo é o desta seção.

### Tom

- Direto e técnico, sem o tom formal de manual. Simples na forma, não no
  conteúdo: o leitor é de TI e não precisa que expliquem o que é `PATH`,
  variável de ambiente ou execution policy. Escreva para quem passa o olho
  primeiro e lê depois.
- Fale com o leitor por "você", de forma direta e no imperativo: "Execute o
  comando", e não "Deve-se executar" ou "O usuário deve executar".
- Fragmentos de frase são bem-vindos quando soam naturais: "Veja como fazer:"
  em vez de "Siga as etapas abaixo:".

### Palavras

- Prefira a palavra curta do dia a dia: "poder" em vez de "ser capaz de",
  "seguinte" em vez de "subsequente", "veja" em vez de "consulte"; omita
  "quaisquer".
- Termos técnicos de mercado ficam em inglês, como se fala na área: script,
  shim, playbook, terminal, bash, ssh, lint, build, deploy. Não use
  "compilação", "implantação" e similares.
- O gênero do termo em inglês segue o uso mais comum no Brasil: o script,
  o shim, o playbook, o build.
- Nome de produto leva artigo: "instale o WSL", "abra o VS Code".
- Use menos possessivos que o inglês: "Organize os ícones da área de
  trabalho", não "Organize os seus ícones da sua área de trabalho".
- Evite termos excludentes: primário/subordinado em vez de master/slave,
  especialista em vez de guru.
- Termo com sentido técnico não é usado em outro sentido: "caminho" é
  caminho de arquivo; para alternativas, use "forma" ou "opção".

### Naturalidade

O texto é escrito em português desde o início, e não traduzido do inglês na
cabeça. Ele soa como um texto técnico brasileiro bem escrito: sem gíria e sem
tom amigável demais, mas com as palavras e a ordem que um nativo usa. Uma
frase que só faz sentido se você imagina o original em inglês está errada.

- Diga o substantivo em vez de deixar um pronome solto: "Variáveis do
  Windows", não "As do Windows"; "separada da rede do Windows", não "separada
  da do Windows".
- Prefira o verbo que se usa no português técnico ao decalque do inglês:
  "os caminhos são convertidos", não "os caminhos viram"; "o Ansible se
  conecta ao Windows", não "o Ansible conecta no Windows"; "quando ele não
  está instalado", não "quando ele falta".
- Explique o que acontece com sujeito e verbo claros, em vez de comprimir a
  ideia: "quando nenhum serviço da distribuição atende uma conexão ao
  localhost, ela é encaminhada para o Windows", não "uma conexão que ninguém
  atende lá chega ao Windows".
- Títulos descrevem o assunto: "Do Windows para o Linux", não "Na ida: o que
  você passa"; "Escolher o nível de detalhe", não "Escolher o detalhe".
- Trate o leitor por "você" sem intimidade: "Se uma limitação atrapalhar o
  seu trabalho", não "Quando uma limitação te atrapalhar".

### Verbos

- Presente simples, evitando o futuro: "o ícone aparece", não "o ícone será
  exibido".
- Sem gerundismo: "vamos instalar", nunca "vamos estar instalando".
- Sem subjuntivo travado: "Verifique se…" ou "Não deixe de…", não
  "Certifique-se de que…".
- O mesmo tempo verbal nas duas partes da frase: "Quando você executa, o
  Ansible mostra…".

### Pontuação

- Sem vírgula antes do "e" e do "ou" no fim de uma enumeração: "Windows,
  Linux e macOS".
- Minúscula depois de dois-pontos.
- Item de lista com frase completa termina com ponto; item que é só um
  fragmento, sem ponto.

### Formatação

| Caso                               | Formato                       | Exemplo                                      |
| ---------------------------------- | ----------------------------- | -------------------------------------------- |
| Termo comum em inglês              | _itálico_, em toda ocorrência | o _script_, o _shim_, o _playbook_           |
| Nome de produto ou tecnologia      | normal (é nome próprio)       | o Ansible, o WSL, o PowerShell               |
| O que se digita ou aparece na tela | `código`                      | `ansible-playbook`, `-i`, `site.yml`, `PATH` |

- Títulos e nomes do menu (`nav`) ficam sem itálico.
- Caminhos no texto são completos, com marcador para o que varia
  (`C:\Users\<usuário>\...`), não variáveis definidas em passos anteriores.

## Inglês

Uma tradução fiel do português, adaptada só no nível da língua para soar
natural ao público global. O usuário não domina o inglês, então o estilo
segue um guia de referência à risca: o
[Google developer documentation style guide](https://developers.google.com/style).

- A documentação é a mesma do português: as mesmas seções, na mesma ordem,
  com os mesmos títulos (traduzidos), parágrafos, listas, passos, exemplos,
  comandos e avisos. Não adicione, remova, junte nem reordene conteúdo.
- A adaptação acontece só dentro da frase, no nível da língua: escolha as
  palavras e a ordem das palavras que um falante de inglês usaria, em vez de
  traduzir palavra por palavra. Exemplo: "deixa os comandos no PATH do
  Windows" vira "adds its commands to your Windows PATH", não "leaves the
  commands in the Windows PATH".
- Frases curtas, voz ativa, sem expressões idiomáticas, gírias ou referências
  culturais. Muitos leitores têm o inglês como segunda língua.
- Um termo por conceito, sem alternar sinônimos.
- Termos como script, shim e playbook são palavras do idioma: sem itálico.

## Revisão e entrega

Uma mudança de documentação está pronta quando:

- [ ] Existe nos dois idiomas, no mesmo PR: página criada, alterada ou
      removida muda em `docs/pt-br/` e em `docs/en/`.
- [ ] Os arquivos têm o mesmo nome e a mesma pasta nos dois idiomas, porque o
      seletor de idioma troca só o prefixo da URL (`/pt-br/` e `/en/`). O que
      muda é o texto: o H1 das páginas e o `nav` de cada toml.
- [ ] O texto dos dois idiomas passou pela skill `humanizer`, para tirar as
      marcas de texto gerado por IA.
- [ ] Os dois idiomas foram conferidos no preview (seção Referência técnica).

## Referência técnica

### Estrutura do site

- Um config por idioma: `docs/zensical.pt-br.toml` e `docs/zensical.en.toml`.
  O Zensical gera um idioma por site, e o deploy junta os dois em `/pt-br/` e
  `/en/`. `docs/index.html` é a raiz do site publicado e redireciona pelo
  idioma do navegador.
- Os dois tomls têm tema, features e extensões de Markdown idênticos: o que
  mudar em um muda no outro. Eles diferem só no idioma, nas URLs, nas pastas
  e nos textos (menu, copyright, descrição, botões de tema).
- Os textos da home ficam no front matter `hero:` do `index.md` de cada
  idioma. `docs/overrides/home.html` não tem texto fixo.
- `docs/overrides/` é compartilhado pelos dois sites: `stylesheets/extra.css`
  para ajustes do site todo, `stylesheets/home.css` e `javascripts/home.js`
  só para a home. Classes próprias têm o prefixo `wp-`.
- CSS e JS entram pelo `extra_css` e `extra_javascript` dos tomls, nunca por
  página: a navegação instantânea (`navigation.instant`) não recarrega o
  `<head>`.
- Comentários de código (toml, HTML, CSS, JS) em inglês.

### Preview

- Um idioma, com hot reload: `uvx --python 3.14 zensical serve -f docs/zensical.pt-br.toml`
  (para os dois ao mesmo tempo, o segundo com `-a localhost:8001`).
- O `--python 3.14` fica em todos os comandos do Zensical: o `pyyaml`, que
  ele usa, ainda não tem pacote para o Python 3.15 no Windows.
- Site completo, com o seletor de idioma e o redirect da raiz: task
  "Documentação: site completo" (`scripts/dev/docs.ps1`), em
  `localhost:8080/WinPlaybook/`, sem hot reload.
