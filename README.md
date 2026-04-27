\# VanPro 🚐



> Gerenciamento inteligente de transporte escolar



\[!\[Status](https://img.shields.io/badge/status-em%20desenvolvimento-yellow)]()

\[!\[Plataforma](https://img.shields.io/badge/plataforma-PWA-blue)]()

\[!\[Stack](https://img.shields.io/badge/stack-Flutter%20Web%20%2B%20PHP%20%2B%20Firebase-orange)]()

\[!\[Repositório](https://img.shields.io/badge/repositório-privado-red)]()



\---



\## 📋 Sobre o Projeto



O \*\*VanPro\*\* é um Progressive Web App (PWA) desenvolvido para resolver a falta de

visibilidade e comunicação no transporte escolar.



Motoristas, pais e escolas passam a ter uma plataforma unificada para acompanhar

rotas, alunos e eventos em tempo real — sem precisar instalar nada.



\---



\## 🎯 Público-Alvo



| Perfil | Necessidade |

|---|---|

| Motoristas de van escolar | Gerenciar rotas, alunos e presenças |

| Pais / Responsáveis | Acompanhar localização e receber notificações |

| Escolas | Visibilidade sobre o transporte dos alunos |



\---



\## 🛠️ Stack Tecnológica



| Camada | Tecnologia |

|---|---|

| Frontend | Flutter Web (PWA) |

| Backend / Hospedagem | PHP |

| Notificações Push | Firebase Cloud Messaging (FCM) |

| Orquestrador de IA | Python 3.10.7 + OpenRouter |

| Tipo de App | Progressive Web App (PWA) |



\---



\## 🏗️ Estrutura do Projeto



```

van\_pro/

├── .claude/                  # Sistema multiagente (orquestrador)

│   ├── agents/               # Prompts dos agentes (brain, coder, etc.)

│   ├── MEMORY.md             # Memória persistente do projeto

│   ├── DECISIONS\_LOG.md      # Registro de decisões aprovadas

│   ├── PROJECT\_CONTEXT.md    # Estado operacional atual

│   └── FORBIDDEN\_ACTIONS.md  # Regras de proteção do sistema

├── .vscode/                  # Configurações do editor

├── orchestrator.py           # Orquestrador central do sistema de agentes

├── .env.example              # Exemplo de variáveis de ambiente (sem valores reais)

├── .gitignore

└── README.md

```



\---



\## 🚀 Fases do Projeto



\- \[x] \*\*Fase 1\*\* — Infraestrutura de agentes (95% concluída)

\- \[ ] \*\*Fase 2\*\* — Desenvolvimento do app VanPro (Flutter Web + PHP + Firebase)

\- \[ ] \*\*Fase 3\*\* — Versionamento e GitHub Actions

\- \[ ] \*\*Fase 4\*\* — Automação de workflows



\---



\## ⚙️ Configuração do Ambiente



\### Pré-requisitos



\- Python 3.10.7+

\- Flutter SDK (canal stable)

\- PHP 8.x

\- Conta Firebase com projeto configurado



\### Instalação do Orquestrador



```bash

\# Clone o repositório

git clone https://github.com/anlunes/van_pro.git

cd van_pro



\# Crie o ambiente virtual Python

python -m venv venv

source venv/bin/activate  # Linux/macOS

venv\\Scripts\\Activate.ps1 # Windows PowerShell



\# Instale as dependências

pip install openai python-dotenv



\# Configure as variáveis de ambiente

cp .env.example .env

\# Edite o .env com suas credenciais reais

```



\### Variáveis de Ambiente Necessárias



Crie um arquivo `.env` baseado no `.env.example`:



```env

OPENROUTER\_API\_KEY=sua_chave_aqui

```



> ⚠️ \*\*NUNCA\*\* commite o arquivo `.env` com valores reais.



\---



\## 🤖 Sistema Multiagente



O VanPro utiliza um sistema de agentes de IA para auxiliar no desenvolvimento:



| Agente | Responsabilidade |

|---|---|

| `brain` | Orquestrador central — pensa, propõe, delega |

| `architect` | Decisões de arquitetura e design de sistema |

| `coder` | Geração de código aprovado |

| `reviewer` | Revisão crítica de entregas |

| `tester` | Validação do que foi implementado |

| `docs` | Documentação técnica |

| `security` | Segurança, autenticação e dados sensíveis |

| `researcher` | Pesquisa técnica antes de propor soluções |

| `memory\_keeper` | Atualização da memória entre sessões |



\---



\## 🔒 Segurança



\- Repositório \*\*privado\*\* durante todo o desenvolvimento

\- Credenciais \*\*nunca\*\* versionadas (`.env` no `.gitignore`)

\- Toda ação de infraestrutura passa por revisão antes do commit

\- Arquivo `FORBIDDEN\_ACTIONS.md` define regras de proteção do sistema



\---



\## 📄 Licença



Projeto privado — todos os direitos reservados.



\---



\*Desenvolvido com o sistema VanPro Multiagent — Sessão iniciada em 01/04/2026\*

```



\---



\## 📋 Próximos Passos para Você Executar



Após criar o repositório no GitHub com o nome `van_pro` (conta `anlunes@gmail.com`, privado), execute localmente:



```powershell

\# Na pasta raiz do projeto

git init

git add .gitignore README.md

git commit -m "chore: inicializa repositório com .gitignore e README"

git branch -M main

git remote add origin https://github.com/anlunes/van_pro.git

git push -u origin main

