# 📊 Guia Rápido - DataGrip

## Passo 1: Criar Conexão no DataGrip

### 1.1 Abrir DataGrip e criar nova Data Source

1. Abra o **DataGrip**
2. Clique no **"+" (New)** no canto superior esquerdo
3. Selecione **Data Source → Microsoft SQL Server**

### 1.2 Configurar conexão

Preencha os campos:

| Campo | Valor |
|-------|-------|
| **Name** | SQL Server - Projeto Banco |
| **Host** | localhost |
| **Port** | 1433 |
| **Authentication** | User & Password |
| **User** | SA |
| **Password** | Cc202505! |
| **Database** | master |

### 1.3 Testar conexão

1. Clique em **"Test Connection"**
2. Se aparecer mensagem para baixar drivers:
   - Clique em **"Download"** e aguarde
3. Deve aparecer: ✅ **"Successful"**
4. Clique em **"OK"** para salvar

---

## Passo 2: Configurar Schemas

### 2.1 Acessar propriedades da conexão

1. Clique com **botão direito** na conexão criada
2. Selecione **"Properties"** ou **"Database Settings"**

### 2.2 Selecionar schemas

1. Vá na aba **"Schemas"** (ou "Options" → "Schemas")
2. **Marque** os checkboxes:
   - ✅ **datasets**
   - ✅ **master**
3. **Desmarque** outros se estiverem selecionados (model, msdb, tempdb)
4. Clique em **"Apply"**
5. Clique em **"OK"**

---

## Passo 3: Atualizar Visualização

1. Clique com **botão direito** na conexão
2. Selecione **"Refresh"** (ou pressione **F5**)
3. Expanda a árvore para ver:

```
📁 SQL Server - Projeto Banco
├── 📁 datasets
│   └── 📁 dbo
│       ├── 📁 tables
│       │   ├── 📋 CSI500
│       │   ├── 📋 SP500_companies
│       │   └── 📋 SP500_fred
│       └── 📁 columns
│
└── 📁 master
    └── 📁 dbo
        ├── 📁 tables
        │   ├── 📋 Dividendos
        │   ├── 📋 Empresas
        │   ├── 📋 Indice
        │   ├── 📋 IndiceSP500
        │   ├── 📋 Localizacao
        │   ├── 📋 PrecoAcao
        │   ├── 📋 SubSetor
        │   └── 📋 Tempo
        └── 📁 columns
```

---

## Passo 4: Executar Testes

### 4.1 Abrir arquivo de teste

1. No DataGrip, clique em **File → Open...**
2. Navegue até:
   ```
   /home/matheus/DataGripProjects/Gerenciamento-Banco-de-dados_v2/scripts/teste_conexao_datagrip.sql
   ```
3. Clique em **"Open"**

### 4.2 Executar consultas

Você tem 3 formas de executar:

#### Opção A: Executar consulta específica
1. **Selecione** a query com o mouse (desde SELECT até o ponto e vírgula)
2. Pressione **Ctrl + Enter** (ou clique no ícone ▶)
3. Veja os resultados na aba inferior

#### Opção B: Executar tudo
1. Pressione **Ctrl + A** para selecionar tudo
2. Pressione **Ctrl + Enter**
3. Ou clique no ícone ▶ **"Execute"**

#### Opção C: Executar por blocos
1. Coloque o cursor dentro de uma query (sem selecionar)
2. Pressione **Ctrl + Enter**
3. DataGrip executa automaticamente a query onde está o cursor

---

## Passo 5: Verificar Resultados dos Testes

Após executar o arquivo **teste_conexao_datagrip.sql**, você deve ver:

### ✅ TESTE 1: Databases
```
DatabaseName | ID | DataCriacao
datasets     | 5  | 2025-11-08
master       | 1  | ...
```

### ✅ TESTE 2: Resumo de Tabelas
```
Database  | Tabela          | Tipo
DATASETS  | CSI500          | Dados Brutos
DATASETS  | SP500_companies | Dados Brutos
DATASETS  | SP500_fred      | Dados Brutos
MASTER    | Dividendos      | Dimensional
MASTER    | Empresas        | Dimensional
...
```

### ✅ TESTE 3: Contagem de Registros
```
Tabela           | TotalRegistros | Descricao
SP500_companies  | ~1.000         | Empresas do S&P 500
SP500_fred       | ~5.000         | Dados históricos
CSI500           | ~1.700.000     | Dados do índice CSI 500
```

---

## Atalhos Úteis do DataGrip

| Ação | Atalho | Descrição |
|------|--------|-----------|
| **Executar Query** | Ctrl + Enter | Executa a query selecionada |
| **Refresh** | F5 | Atualiza a árvore de conexões |
| **Novo Console SQL** | Ctrl + Shift + F10 | Abre novo console SQL |
| **Formatar SQL** | Ctrl + Alt + L | Formata o código SQL |
| **Comentar Linha** | Ctrl + / | Comenta/descomenta linha |
| **Auto-completar** | Ctrl + Space | Mostra sugestões |
| **Executar Seleção** | Ctrl + Enter | Executa apenas o trecho selecionado |
| **Ver Estrutura** | Alt + 7 | Mostra estrutura do arquivo |

---

## Visualizando Dados das Tabelas

### Forma 1: Via Interface
1. Expanda a árvore até a tabela desejada
2. **Clique duplo** na tabela
3. Veja os dados na aba que se abre

### Forma 2: Via Query
```sql
-- Ver primeiros 100 registros
SELECT TOP 100 * FROM datasets.dbo.SP500_companies;

-- Ver primeiros 10
SELECT TOP 10 * FROM datasets.dbo.CSI500;

-- Contar registros
SELECT COUNT(*) FROM datasets.dbo.SP500_fred;
```

---

## Consultas Rápidas para Testar

### Ver todas as empresas
```sql
SELECT TOP 20 registro
FROM datasets.dbo.SP500_companies;
```

### Ver dados históricos
```sql
SELECT TOP 20 registro
FROM datasets.dbo.SP500_fred;
```

### Ver estrutura de uma tabela
```sql
USE master;
GO

SELECT
    c.name as Coluna,
    t.name as TipoDado,
    c.max_length as Tamanho,
    c.is_nullable as AceitaNulo
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('Empresas')
ORDER BY c.column_id;
```

### Ver relacionamentos (Foreign Keys)
```sql
USE master;
GO

SELECT
    OBJECT_NAME(f.parent_object_id) as De,
    OBJECT_NAME(f.referenced_object_id) as Para,
    f.name as NomeFK
FROM sys.foreign_keys f
ORDER BY De;
```

---

## Solução de Problemas Comuns

### Problema 1: "Tabelas não aparecem"

**Solução:**
1. File → Invalidate Caches...
2. Marcar todas opções
3. "Invalidate and Restart"
4. Após reiniciar: F5 na conexão

### Problema 2: "Invalid object name"

**Causa:** Você está no database errado

**Solução:** Use caminho completo
```sql
-- ❌ Errado
SELECT * FROM SP500_companies;

-- ✅ Correto
SELECT * FROM datasets.dbo.SP500_companies;
```

Ou mude o database:
```sql
USE datasets;
GO
SELECT * FROM SP500_companies;
```

### Problema 3: "Erro de conexão"

**Verificar:**
1. Container está rodando?
   ```bash
   docker compose ps
   ```
2. Se não estiver, inicie:
   ```bash
   docker compose up -d
   ```

### Problema 4: "Login failed"

**Causa:** Credenciais incorretas

**Verificar:**
- User: **SA** (maiúsculo)
- Password: **Cc202505!** (C maiúsculo, c minúsculo, números e !)

---

## Estrutura de Diretórios do Projeto

```
Gerenciamento-Banco-de-dados_v2/
├── compose.yaml                    # Configuração Docker
├── datasets/                       # Arquivos CSV
│   ├── S&P-500-companies.csv
│   ├── S&P500-fred.csv
│   ├── CSI500-part-1.csv
│   └── CSI500-part-2.csv
│
├── scripts/
│   ├── 01_setup_completo.sql      # ⭐ Setup inicial
│   ├── 02_consultas.sql            # Consultas prontas
│   ├── teste_conexao_datagrip.sql  # ⭐ Este arquivo de teste
│   └── ...
│
├── COMECE_AQUI.md                  # Guia de início
├── ORDEM_EXECUCAO.md               # Ordem dos passos
├── GUIA_DATAGRIP.md                # ⭐ Este arquivo
├── README_INSTALACAO.md            # Guia completo
└── setup_automatico.sh             # Script automático
```

---

## Próximos Passos Após Configurar DataGrip

1. ✅ **Configuração concluída** - DataGrip funcionando
2. ⏳ **Explorar dados** - Executar queries de análise
3. ⏳ **Criar ETL** - Popular tabelas do master com dados dos CSVs
4. ⏳ **Criar views** - Facilitar consultas complexas
5. ⏳ **Análise de dados** - Começar análises reais

---

## Status Atual do Projeto

| Item | Status | Detalhes |
|------|--------|----------|
| **Docker** | ✅ Rodando | Container sqlserverCC ativo |
| **Database datasets** | ✅ Criado | 3 tabelas com ~1.7M registros |
| **Database master** | ✅ Criado | 8 tabelas (estrutura dimensional) |
| **Dados importados** | ✅ Completo | CSVs carregados no datasets |
| **DataGrip** | ⏳ Configurar | Siga este guia |
| **ETL** | ⏳ Pendente | Transferir dados para master |

---

**🎯 Tudo Pronto para Começar a Trabalhar!**

Execute o arquivo **teste_conexao_datagrip.sql** para verificar se está tudo funcionando!
