\# MEMÓRIA DO PROJETO — VanPro



\## Última atualização: 04/04/2026



\*\*\*



\## O QUE FUNCIONA (NÃO TOCAR)

\- Estrutura de pastas .claude/, .vscode/ e orchestrator.py criada e operacional

\- Sistema multiagente aprovado pelo Mentor em 01/04/2026

\- OPENROUTER\_API\_KEY configurada e carregando corretamente via load\_dotenv

\- Healthcheck validado: todos os arquivos críticos presentes, API key OK (73 chars)

\- Todos os prompts dos agentes revisados e populados com contexto do VanPro



\*\*\*



\## DECISÕES ARQUITETURAIS APROVADAS

\- 01/04/2026 | Arquitetura com Cérebro + subagentes | aprovada pelo Mentor

\- 01/04/2026 | Modelo mentor-dirigido: o sistema propõe, debate e só executa com autorização explícita | aprovado pelo Mentor

\- 01/04/2026 | Provider: OpenRouter com OpenAI SDK | custo e flexibilidade de modelos | aprovado pelo Mentor

\- 01/04/2026 | Stack do VanPro: Flutter Web (PWA) + PHP + Firebase FCM | requisitos do produto | aprovado pelo Mentor

\- 04/04/2026 | A restrição de criar repositório GitHub somente depois da fase 2 foi revogada | aprovada pelo Mentor

\- 04/04/2026 | Criar repositório GitHub privado agora para o projeto VanPro, com conta anlunes2@gmail.com | aprovada pelo Mentor

\- 04/04/2026 | Não pedir novas confirmações para criação de repositório GitHub, desde que seja privado | aprovada pelo Mentor



\*\*\*



\## STACK ATUAL

\- Linguagem do orquestrador: Python 3.10.7

\- Provider de IA: OpenRouter

\- Cliente de IA: OpenAI SDK

\- Dependências: openai, python-dotenv

\- App (VanPro): Flutter Web (PWA) + PHP + Firebase Cloud Messaging



\*\*\*



\## CONTEXTO DO PROJETO

VanPro é um aplicativo PWA de gerenciamento de transporte escolar (vans escolares).

Fase 1 (infraestrutura de agentes) está em 95% concluída. Fase 2 (desenvolvimento do app) ainda não iniciada.



\*\*\*



\## PENDÊNCIAS ATIVAS

\- \[ ] Definir primeira feature MVP do VanPro com o Arquiteto

\- \[ ] Testar fluxo completo: brain → subagente → revisão → memória

\- \[ ] Iniciar Fase 2: desenvolvimento do app VanPro

\- \[X] GitHub na Fase 3 (decisão revogada: GitHub autorizado a ser criado agora)

\- \[ ] Auditoria de código real do VanPro (suspensa até ferramenta de chat com anexos ser construída)



\*\*\*



\## HISTÓRICO DE SESSÕES

\- 01/04/2026 | Sessão 0 | Estrutura inicial criada no Windows PowerShell | resultado: ok

\- 01/04/2026 | Sessão 1 | Correção do .env, fix do os.getenv(), healthcheck OK, todos os prompts revisados | resultado: ok

\- 04/04/2026 | Sessão 2 | Revisão de decisões sobre GitHub, revogação de restrição, autorização para criar repositório privado agora | resultado: ok



\*\*\*



\## LIÇÕES APRENDIDAS

\- PowerShell não aceita mkdir -p nem touch: usar New-Item

\- O operador \&\& não funciona no PowerShell desta máquina

\- BOM no .env impede leitura da API key pelo python-dotenv

\- os.getenv() recebe o NOME da variável, não o valor direto



\*\*\*



\## ALERTAS E RISCOS

\- Prompts dos agentes preenchidos, mas ainda sem testes de fluxo completo

\- Fase 2 depende da definição clara da primeira feature MVP no PROJECT\_CONTEXT.md

\- Criação de repositório GitHub agora pode expor stack se o repositório se tornar público; manter sempre como privado durante desenvolvimento

