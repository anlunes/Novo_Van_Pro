\# Workflow: Refatoração — VanPro



\## Objetivo

Guiar o sistema multiagente em refatorações seguras, sem quebrar o que já funciona.



\## Regra de Ouro

Nenhuma refatoração acontece sem aprovação explícita do Mentor.

Código que está em MEMORY.md como "funciona" é protegido por padrão.



\## Etapas



\### 1. Justificativa (Mentor → Cérebro)

\- Mentor descreve o motivo da refatoração

\- Cérebro verifica se o código-alvo está protegido no MEMORY.md

\- Se estiver protegido, alerta o Mentor antes de prosseguir



\### 2. Análise de Impacto (Cérebro → Architect)

\- Architect mapeia o que será alterado e o que será preservado

\- Define complexidade, dependências e riscos

\- Entrega proposta estruturada ao Cérebro



\### 3. Aprovação (Cérebro → Mentor)

\- Cérebro apresenta proposta completa com riscos

\- Mentor aprova ou rejeita antes de qualquer alteração



\### 4. Implementação (Cérebro → Coder)

\- Coder refatora exatamente o escopo aprovado

\- Preserva comportamento externo — apenas melhora estrutura interna

\- Marca blocos com // \[CODER] REFACTOR — \[motivo] — \[data]



\### 5. Revisão (Cérebro → Reviewer)

\- Reviewer verifica se o comportamento foi preservado

\- Confirma que nada fora do escopo foi alterado



\### 6. Testes (Cérebro → Tester)

\- Tester executa testes de regressão completos

\- Foco em garantir que nada que funcionava parou de funcionar



\### 7. Documentação (Cérebro → Docs)

\- Docs atualiza documentação técnica afetada pela refatoração



\### 8. Memória (Cérebro → Memory Keeper)

\- Atualiza MEMORY.md: remove referência antiga, adiciona nova

\- Registra motivo e resultado da refatoração



\### 9. Aprovação Final (Cérebro → Mentor)

\- Cérebro apresenta resumo da refatoração

\- Mentor aprova e encerra o ciclo

