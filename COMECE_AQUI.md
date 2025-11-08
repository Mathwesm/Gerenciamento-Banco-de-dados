# 🚀 COMECE AQUI - Guia Rápido

## 📋 Ordem de Execução

Siga os passos numerados na ordem:

---

### **PASSO 1** - Setup Inicial

Cria databases, tabelas e importa dados brutos dos CSVs:

```bash
./1_setup_automatico.sh
```

**O que este script faz:**
- ✅ Inicia container Docker
- ✅ Cria database `datasets` e `master`
- ✅ Cria 11 tabelas (3 no datasets + 8 no master)
- ✅ Importa ~1.7M registros dos CSVs

**Tempo:** 2-5 minutos

---

### **PASSO 2** - Processar Dados (ETL)

Processa dados brutos e popula tabelas do master:

```bash
./2_processar_etl.sh
```

**O que este script faz:**
- ✅ Faz parse dos dados CSV (separa colunas)
- ✅ Popula tabela Empresas (~1.000 empresas S&P 500)
- ✅ Popula SubSetor e Localizacao
- ✅ Popula histórico do índice S&P 500 (~5.000 registros)
- ✅ Popula dimensão Tempo
- ✅ Verifica duplicatas automaticamente

**Tempo:** 1-3 minutos

---

### **PASSO 3** - Visualizar Dados (Opcional)

Visualiza todas as tabelas e análises:

```bash
./3_visualizar.sh
```

**O que este script mostra:**
- 📊 Resumo de todas as tabelas
- 📊 Top 10 de cada tabela
- 📊 Análises rápidas (empresas por setor, etc.)
- 📊 Verificação de integridade

---

### **PASSO 4** - Limpar/Resetar (Opcional)

Menu interativo para limpeza:

```bash
./4_limpar.sh
```

**Opções:**
- **Opção 1:** Limpar apenas dados (mantém estrutura)
- **Opção 2:** Resetar tudo do zero (remove tudo)

---

## 📊 Configurar DataGrip

Após executar os PASSOS 1 e 2:

### 1. Criar Conexão
- Host: `localhost`
- Port: `1433`
- User: `SA`
- Password: `Cc202505!`
- Database: `master`

### 2. Configurar Schemas
- Botão direito na conexão → Properties → Schemas
- Marcar: ✅ datasets, ✅ master
- Apply → OK

### 3. Testar
- Abrir: `scripts/2-consultas/teste_conexao_datagrip.sql`
- Executar: Ctrl + Enter

---

## ✅ Resultado Esperado

Após PASSO 1 e 2, você terá:

### Database `datasets` (Dados Brutos)
- SP500_companies (~1.000 registros)
- SP500_fred (~5.000 registros)
- CSI500 (~1.700.000 registros)

### Database `master` (Modelo Dimensional - Processado)
- Empresas (~1.000 empresas)
- SubSetor (~1.000 registros)
- Localizacao (~1.000 registros)
- Indice (1 registro - S&P 500)
- IndiceSP500 (~5.000 registros históricos)
- Tempo (~5.000 datas)
- PrecoAcao (vazio - aguardando dados)
- Dividendos (vazio - aguardando dados)

**Total: 11 tabelas | ~1.7M registros brutos + ~12K processados**

---

## 🔄 Fluxo Completo

```
1. ./1_setup_automatico.sh     # Setup inicial
          ↓
2. ./2_processar_etl.sh        # Processar dados
          ↓
3. ./3_visualizar.sh           # Ver resultados (opcional)
          ↓
4. Configurar DataGrip         # Explorar dados
          ↓
5. Executar análises           # Trabalhar com os dados
```

---

## 🆘 Problemas?

### Container não inicia
```bash
docker compose down -v
docker compose up -d
```

### Tabelas não aparecem no DataGrip
```
File → Invalidate Caches → Invalidate and Restart
```

### Quer recomeçar do zero?
```bash
./4_limpar.sh  # Escolha opção 2
./1_setup_automatico.sh
./2_processar_etl.sh
```

---

## 📁 Estrutura de Pastas

```
scripts/
├── 1-setup/          # Scripts de configuração inicial
├── 2-consultas/      # Scripts de visualização
└── 3-manutencao/     # Scripts de limpeza/reset
```

---

## 📖 Documentação Completa

Consulte o arquivo **README.md** para:
- Detalhes técnicos
- Comandos avançados
- Troubleshooting completo
- Estrutura do projeto

---

**Pronto para começar?**

```bash
./1_setup_automatico.sh
```

Depois:

```bash
./2_processar_etl.sh
```

Simples assim! 🎉
