\# FORBIDDEN\_ACTIONS.md — Regras de Proteção do Sistema VanPro



\## Nível Crítico (bloqueia qualquer ação)

1\. Deletar ou sobrescrever MEMORY.md, DECISIONS\_LOG.md ou PROJECT\_CONTEXT.md

2\. Executar comandos destrutivos (rm -rf, del /s, drop table, etc.)

3\. Alterar arquivos fora do escopo da tarefa delegada

4\. Fazer commit sem revisão do Mentor



\## Nível Alto (exige dupla confirmação do Mentor)

1\. Refatorar código marcado como "funciona" no MEMORY.md

2\. Mudar stack principal: Flutter Web, PHP ou Firebase

3\. Alterar estrutura de pastas .claude/

4\. Criar repositório GitHub antes da Fase 1
5 Commitar o arquivo .env para o repositório

6 Commitar senhas, chaves de API ou qualquer credencial sensível

7 Sobrescrever arquivos críticos (.env, DATABASE\_CONNECTION, MEMORY.md, DECISIONS\_LOG.md) sem backup



\## Nível Médio (exige justificativa antes de executar)

1\. Usar modelos pagos sem custo estimado

2\. Adicionar dependências externas sem análise de segurança

3\. Executar comandos de rede sem revisão do agente security
4 Alterar o fluxo principal de notificações (FCM) sem teste prévio

5 Renomear ou deletar pastas de código Flutter (.lib, .web) sem autorização

6 Modificar a estrutura de tabelas principais (usuarios, alunos, rotas, eventos, fcm\_tokens) sem justificativa técnica



\## Arquivos Protegidos (nunca alterar sem aprovação explícita)

\- .claude/MEMORY.md

\- .claude/DECISIONS\_LOG.md

\- .claude/PROJECT\_CONTEXT.md

\- .claude/FORBIDDEN\_ACTIONS.md

\- orchestrator.py



\## Padrões Protegidos

\- Estrutura de mensagens do orchestrator.py

\- Convenções de nomenclatura dos agentes

\- Fluxo de autenticação via .env + load\_dotenv



\## Regra Universal

Nenhum agente age por conta própria.

Toda ação é delegada pelo Cérebro e aprovada pelo Mentor.

Se houver dúvida, PARE e reporte ao Cérebro antes de prosseguir.

## Observações

\- Antes de realizar qualquer ação proibida, o sistema deve propor, explicar os riscos e solicitar autorização explicitamente.

