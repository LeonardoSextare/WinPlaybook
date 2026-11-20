# Limitações conhecidas

Estas são as diferenças que o WinPlaybook ainda não consegue esconder. Se
uma delas atrapalhar o seu trabalho, [conte para a gente](report-issue.md).
Isso ajuda a definir as prioridades.

## Tempo de início

Cada comando passa pelo PowerShell e pelo WSL antes de o Ansible começar. Isso
soma pouco mais de um segundo a cada comando, em comparação com o Ansible
rodando direto no Linux. O tempo é quase fixo: num _playbook_ longo, a
diferença quase não aparece, mas num `ansible --version` ela é a maior parte
do tempo.

O primeiro comando depois de ligar o Windows leva alguns segundos a mais,
porque o WSL precisa iniciar a distribuição.

---

## Arquivos nas pastas do Windows

O Ansible lê os arquivos das unidades do Windows pelo WSL, o que é mais lento
que ler do disco da distribuição. Isso pesa em projetos com milhares de
arquivos, como uma pasta de _roles_ grande ou um `synchronize` de uma pasta
inteira.

---

## A ponte do localhost

Nas tarefas, o `localhost` do Windows só responde enquanto um comando do
WinPlaybook está rodando. Um processo que você deixa rodando em segundo plano
na distribuição perde a ponte quando o comando termina.

A lista de portas do Windows é atualizada a cada segundo. Um serviço que você
abriu no Windows menos de um segundo antes do comando pode não responder na
primeira conexão.

---

## Extensão do VS Code

As correções valem para uma versão testada da extensão Ansible. Uma
atualização da extensão desfaz as correções até o WinPlaybook testar a versão
nova. Veja [Usar o VS Code](vscode.md).
