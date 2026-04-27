\# Workflow: Correção de Bug — VanPro



\## Objetivo

Guiar o sistema multiagente na identificação, correção e validação de um bug no VanPro.



\## Etapas



\### 1. Reporte (Mentor → Cérebro)

\- Mentor descreve o bug: comportamento esperado vs. observado

\- Cérebro lê MEMORY.md para verificar se há histórico relacionado



\### 2. Investigação (Cérebro → Researcher ou Coder)

\- Identify causa raiz antes de qualquer alteração

\- Mapear arquivos afetados e impacto potencial



\### 3. Proposta de Correção (Cérebro → Mentor)

\- Cérebro apresenta: causa identificada, correção proposta, riscos

\- Aguarda aprovação antes de prosseguir



\### 4. Implementação (Cérebro → Coder)

\- Coder corrige APENAS o que foi aprovado

\- Nenhuma melhoria ou refatoração fora do escopo do bug

\- Marca blocos alterados com // \[CODER] FIX — \[bug] — \[data]



\### 5. Revisão (Cérebro → Reviewer)

\- Reviewer confirma que o bug foi corrigido

\- Verifica se nenhuma regressão foi introduzida



\### 6. Testes (Cérebro → Tester)

\- Tester valida o cenário que reproduzia o bug

\- Valida regressão nos fluxos principais



\### 7. Memória (Cérebro → Memory Keeper)

\- Registra o bug, causa, correção e lição aprendida no MEMORY.md



\### 8. Aprovação Final (Cérebro → Mentor)

\- Cérebro apresenta resumo da correção

\- Mentor aprova e encerra o ciclo

