# Limitações conhecidas

!!! info "Versão 0"

    O WinPlaybook está na versão 0. O que está abaixo é conhecido e tem issue
    aberta ou planejada. Se uma limitação atrapalhar o seu trabalho,
    [conte para a gente](report-issue.md): isso ajuda a definir as prioridades.

## Tempo de início

Cada comando passa pelo WSL, e os comandos `.exe` abrem também um PowerShell.
Isso acrescenta alguns segundos ao início de cada execução, e um pouco mais
quando a distribuição está parada. A otimização é o próximo passo do projeto, depois
que todos os recursos estiverem prontos.

---

## Arquivos nas pastas do Windows

O acesso aos arquivos das unidades do Windows é mais lento que ao disco da
distribuição. Isso pesa em projetos com muitos arquivos.

---

## A ponte do localhost

Nas tarefas, o `localhost` do Windows só responde enquanto um comando do
WinPlaybook está rodando. Um processo que você deixa rodando em segundo plano na
distribuição perde a ponte quando o comando termina.

---

## Extensão do VS Code

As correções valem para uma versão testada da extensão Ansible. Uma
atualização da extensão desfaz as correções até o WinPlaybook testar a versão
nova.

---

## Agente SSH

Em algumas máquinas, o primeiro pedido ao agente SSH do Windows falha, e o
comando seguinte funciona. A causa ainda não foi encontrada.
