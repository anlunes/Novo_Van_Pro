# PROJECT_CONTEXT.md — Estado Operacional do Projeto

## Objetivo Principal
Construir o VanPro — um aplicativo PWA de gerenciamento de transporte escolar (vans escolares), desenvolvido em Flutter Web, hospedado em servidor PHP e integrado ao Firebase para notificações push.

## Stack Atual
- Provider: OpenRouter
- Cliente: OpenAI SDK
- Linguagem do orquestrador: Python 3.10.7
- Dependências: openai, python-dotenv
- Estrutura de agentes: .claude/ (agentes, workflows, memória)
- Orquestrador: orchestrator.py

## Stack do App (VanPro)
- Frontend: Flutter Web (PWA)
- Backend/Hospedagem: Servidor PHP
- Notificações: Firebase Cloud Messaging (FCM)
- Tipo: Progressive Web App (PWA)

## Fase Atual
**Fase 1 — Infraestrutura de Agentes** (em andamento — 95%)

## Módulos de Agentes Existentes
- brain (orquestrador / cérebro)
- architect (arquitetura e decisões técnicas)
- coder (geração de código)
- reviewer (revisão de código)
- tester (testes)
- docs (documentação)
- security (segurança)
- memory_keeper (gestão de memória)
- researcher (pesquisa técnica)

## O Que Está Funcionando
- Leitura de memória e contexto
- Chamada aos agentes via OpenRouter
- Respostas estruturadas
- Atualização incremental da memória (MEMORY.md)
- Healthcheck operacional

## Próximos Passos (Fase 1 → Fase 2)
1. Completar todos os prompts dos agentes (.claude/agents/*.md)
2. Testar fluxo completo: brain → subagente → revisão → memória
3. Definir primeira feature MVP do VanPro
4. Iniciar Fase 2: desenvolvimento do app VanPro

## Próximas Fases
- Fase 2: Desenvolvimento do VanPro (Flutter Web + PHP + Firebase)
- Fase 3: GitHub + versionamento
- Fase 4: Automação de workflows

## Metas de Validação da Fase 1
- [ ] Todos os agentes respondem
- [ ] Fluxo completo funciona
- [ ] Memória persiste entre sessões
- [ ] Nenhum agente quebra regras definidas no FORBIDDEN_ACTIONS.md

## Contexto do Produto (VanPro)
- Público-alvo: motoristas de van escolar, pais/responsáveis, escolas
- Problema principal: falta de visibilidade e comunicação no transporte escolar
- Diferencial: PWA acessível sem instalação, notificações em tempo real via Firebase
- Primeira feature MVP a definir com o architect