# 📍 COMECE AQUI - Índice do Projeto

**Guia visual para navegação rápida**

---

## 🎯 Você está procurando...

### 🆕 "Como instalar e rodar o projeto?"
👉 **[README_INSTALACAO.md](README_INSTALACAO.md)**
- Guia passo a passo completo
- Instalação 100% funcional
- ~10 minutos para ter tudo rodando

### ❌ "Algo não está funcionando!"
👉 **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)**
- Solução de TODOS os problemas
- Comandos de diagnóstico
- Reset completo se necessário

### 📚 "Quero entender a estrutura completa"
👉 **[SUMARIO_COMPLETO.md](SUMARIO_COMPLETO.md)**
- Visão geral do projeto
- Todos os arquivos e pastas
- Estatísticas e métricas

### 📊 "Como as tabelas foram melhoradas?"
👉 **[MELHORIAS_TABELAS.md](MELHORIAS_TABELAS.md)**
- Melhorias implementadas
- Estrutura das 8 tabelas
- Nomes em português BR

### 🎓 "Informações acadêmicas do projeto"
👉 **[README.md](README.md)**
- README original
- Objetivos acadêmicos
- Perguntas de negócio

---

## ⚡ Início Rápido (3 Comandos)

```bash
# 1. Iniciar Docker
cd /home/matheus/DataGripProjects/Gerenciamento-Banco-de-dados_v2
docker compose up -d

# 2. Executar Setup
docker cp scripts/01_setup_completo.sql sqlserverCC:/tmp/01_setup_completo.sql
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "Cc202505!" -i /tmp/01_setup_completo.sql -C

# 3. Conectar no DataGrip
# Host: localhost | Port: 1433 | User: SA | Senha: Cc202505!
```

**Pronto!** ✅

---

## 📂 Arquivos Principais

| Tipo | Arquivo | Descrição |
|------|---------|-----------|
| 🔴 **ESSENCIAL** | README_INSTALACAO.md | Instalação completa |
| 🔴 **ESSENCIAL** | TROUBLESHOOTING.md | Solução de problemas |
| 🟡 **IMPORTANTE** | SUMARIO_COMPLETO.md | Índice completo |
| 🟡 **IMPORTANTE** | MELHORIAS_TABELAS.md | Documentação técnica |
| 🟢 **OPCIONAL** | INDEX.md | Este arquivo |
| 🟢 **OPCIONAL** | README.md | README original |

---

## 🗂️ Scripts SQL

| Prioridade | Script | Uso | Como Executar |
|-----------|--------|-----|---------------|
| 🔴 **#1** | 01_setup_completo.sql | Setup inicial | Linha de comando |
| 🔴 **#2** | 02_consultas.sql | Consultas prontas | DataGrip |
| 🟡 | create_tables_melhorado.sql | Criar tabelas master | Backup |
| 🟡 | insert_datasets.sql | Importar CSVs | Backup |

---

## 🗄️ O que você vai ter depois do setup

### Database: **master**
```
8 tabelas (modelo dimensional)
├── Indice
├── IndiceSP500
├── Empresas
├── SubSetor
├── Localizacao
├── Tempo
├── PrecoAcao
└── Dividendos
```

### Database: **datasets**
```
3 tabelas (dados brutos)
├── SP500_companies    (~1.500 registros)
├── SP500_fred         (~7.800 registros)
└── CSI500             (~2.600.000 registros)
```

---

## 🔑 Informações Rápidas

### Credenciais
```
Host: localhost
Port: 1433
User: SA
Password: Cc202505!
```

### Comandos Docker
```bash
# Status
docker compose ps

# Logs
docker logs sqlserverCC

# Parar
docker compose down

# Iniciar
docker compose up -d
```

---

## ✅ Checklist Rápido

- [ ] Docker instalado e rodando
- [ ] Executou `docker compose up -d`
- [ ] Executou `01_setup_completo.sql`
- [ ] Viu mensagem "SETUP COMPLETO FINALIZADO"
- [ ] Conectou no DataGrip
- [ ] Vê as 8 tabelas do master
- [ ] Vê as 3 tabelas do datasets
- [ ] Consegue executar queries

**Tudo marcado?** Parabéns! Setup completo! 🎉

---

## 🆘 Precisa de Ajuda?

1. ✅ Problema específico? → [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. ✅ Não sabe por onde começar? → [README_INSTALACAO.md](README_INSTALACAO.md)
3. ✅ Quer entender tudo? → [SUMARIO_COMPLETO.md](SUMARIO_COMPLETO.md)

---

## 📊 Diagrama de Navegação

```
VOCÊ ESTÁ AQUI
    ↓
┌─────────────┐
│  INDEX.md   │ ← Este arquivo
└──────┬──────┘
       │
       ├──→ 🆕 Primeiro uso? → README_INSTALACAO.md
       │
       ├──→ ❌ Problema? → TROUBLESHOOTING.md
       │
       ├──→ 📚 Visão geral? → SUMARIO_COMPLETO.md
       │
       ├──→ 📊 Detalhes técnicos? → MELHORIAS_TABELAS.md
       │
       └──→ 🎓 Info acadêmica? → README.md
```

---

## 🎯 Fluxo Recomendado

```
1. INDEX.md (você está aqui)
   ↓
2. README_INSTALACAO.md (instalar tudo)
   ↓
3. Executar 01_setup_completo.sql
   ↓
4. Conectar DataGrip
   ↓
5. Executar queries de 02_consultas.sql
   ↓
6. Explorar dados
   ↓
7. Começar análises!
```

---

## 📝 Resumo Ultra-Rápido

1. **Instalar**: `docker compose up -d` + executar `01_setup_completo.sql`
2. **Conectar**: DataGrip → localhost:1433 → SA:Cc202505!
3. **Usar**: Executar queries do `02_consultas.sql`
4. **Problemas?**: Ler `TROUBLESHOOTING.md`

**Simples assim!** 🚀

---

**🎉 Projeto 100% Documentado e Funcional! 🎉**

**Data**: 2025-11-07
