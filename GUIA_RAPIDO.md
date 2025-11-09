# 🚀 Guia Rápido - Análise de Mercado Financeiro

## ⚡ Setup em 3 Comandos

```bash
cd /home/matheus/DataGripProjects/Gerenciamento-Banco-de-dados_v2
chmod +x SETUP_COMPLETO.sh
./SETUP_COMPLETO.sh
```

**Escolha a opção 1** no menu que aparecer.

---

## 📋 O Que Vai Acontecer

```
┌──────────────────────────────────────────────────────────┐
│                    SETUP AUTOMÁTICO                      │
│                                                          │
│  ✓ Verifica Docker                                       │
│  ✓ Inicia container SQL Server                          │
│  ✓ Cria banco de dados 'datasets'                       │
│  ✓ Cria banco de dados 'master'                         │
│  ✓ Importa 503 empresas S&P 500                         │
│  ✓ Importa 2,609 observações do índice                  │
│  ✓ Importa 865,898 registros de ações chinesas          │
│  ✓ Normaliza e processa dados (ETL)                     │
│  ✓ Cria tabelas otimizadas com índices                  │
│  ✓ Cria 7 views analíticas                              │
│  ✓ Executa queries e mostra resultados                  │
│                                                          │
│  ⏱ Tempo estimado: 5-10 minutos                         │
└──────────────────────────────────────────────────────────┘
```

---

## 🎯 As 7 Views Criadas

Após o setup, você terá acesso a estas views:

| # | View | Pergunta |
|---|------|----------|
| 1 | `vw_P1_MaiorValorizacaoUltimoAno` | Maior valorização no último ano |
| 2 | `vw_P2_VolatilidadePorIndustria` | Volatilidade por indústria |
| 3 | `vw_P3_MaiorVolumeNegociacao` | Maior volume de negociação |
| 4 | `vw_P4_CrescimentoConsistente5Anos` | Crescimento consistente (5 anos) |
| 5 | `vw_P5_DesempenhoSetoresSP500` | Desempenho de setores S&P 500 |
| 6 | `vw_P6_QuedaCriseCovid` | Maior queda durante COVID |
| 7 | `vw_P7_DadosBaseParaDividendos` | Base para análise de dividendos |

---

## 💻 Como Consultar os Resultados

### Opção 1: DataGrip (Recomendado)

1. **Abra o DataGrip**
2. **Atualize a conexão** (F5)
3. **Navegue até:** `datasets` > `Views`
4. **Clique com botão direito** em qualquer view > `Edit Data`

### Opção 2: Linha de Comando

```bash
# Top 10 ações com maior valorização
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Cc202505!" -C \
  -Q "SELECT TOP 10 * FROM datasets.dbo.vw_P1_MaiorValorizacaoUltimoAno ORDER BY ValorizacaoPercentual DESC"
```

### Opção 3: Executar Script de Consultas

```bash
cd /home/matheus/DataGripProjects/Gerenciamento-Banco-de-dados_v2
./SETUP_COMPLETO.sh
# Escolha opção 3: "Apenas Consultar Respostas"
```

---

## 📊 Exemplos de Queries

### Pergunta 1: Top 10 ações com maior valorização

```sql
SELECT TOP 10
    Symbol,
    Empresa,
    ValorizacaoPercentual,
    PrecoInicial,
    PrecoFinal,
    CategoriaDesempenho
FROM vw_P1_MaiorValorizacaoUltimoAno
ORDER BY ValorizacaoPercentual DESC;
```

### Pergunta 2: Indústrias mais voláteis

```sql
SELECT TOP 15
    Industria,
    QtdEmpresas,
    VolatilidadeAnualizada_Pct,
    RetornoMedioDiario_Pct,
    ClassificacaoVolatilidade
FROM vw_P2_VolatilidadePorIndustria
ORDER BY VolatilidadeAnualizada_Pct DESC;
```

### Pergunta 3: Empresas mais negociadas

```sql
SELECT TOP 30
    Symbol,
    Empresa,
    VolumeTotal,
    VolumeMediaDiaria,
    ValorFinanceiroTotal,
    ClassificacaoLiquidez
FROM vw_P3_MaiorVolumeNegociacao
ORDER BY VolumeTotal DESC;
```

### Pergunta 4: Ações mais consistentes

```sql
SELECT TOP 30
    Symbol,
    Empresa,
    AnosPositivos,
    TaxaSucessoPct,
    RetornoMedioAnual_Pct,
    SharpeRatioSimplificado,
    ClassificacaoConsistencia
FROM vw_P4_CrescimentoConsistente5Anos
WHERE AnosComDados >= 4
ORDER BY TaxaSucessoPct DESC;
```

### Pergunta 5: Setores no S&P 500

```sql
SELECT
    Setor,
    QtdEmpresas,
    ParticipacaoPct,
    IdadeMediaAnos,
    AdicionadasUltimos5Anos,
    ClassificacaoTamanho
FROM vw_P5_DesempenhoSetoresSP500
ORDER BY QtdEmpresas DESC;
```

### Pergunta 6: Impacto COVID-19

```sql
SELECT TOP 30
    Symbol,
    Empresa,
    Industria,
    PrecoPreCovid,
    PrecoMinimoCovid,
    QuedaPercentual,
    RecuperacaoTotal_Pct,
    ClassificacaoImpacto
FROM vw_P6_QuedaCriseCovid
ORDER BY QuedaPercentual ASC;
```

### Pergunta 7: Base para análise de dividendos

```sql
SELECT
    Symbol,
    NomeEmpresa,
    Setor,
    SubIndustria,
    IdadeEmpresa,
    TendenciaDividendos
FROM vw_P7_DadosBaseParaDividendos
WHERE Setor IN ('Utilities', 'Real Estate', 'Consumer Staples')
ORDER BY Setor, NomeEmpresa;
```

---

## 🔧 Comandos Úteis

### Ver status do container

```bash
docker ps | grep sqlserverCC
```

### Parar o container

```bash
docker stop sqlserverCC
```

### Iniciar o container

```bash
docker start sqlserverCC
# ou
docker-compose up -d
```

### Ver logs do container

```bash
docker logs sqlserverCC
```

### Entrar no container

```bash
docker exec -it sqlserverCC bash
```

### Conectar ao SQL Server

```bash
docker exec -it sqlserverCC /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Cc202505!" -C
```

---

## 🎨 Menu do Script Principal

Quando você executa `./SETUP_COMPLETO.sh`, você vê este menu:

```
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║   ANÁLISE QUANTITATIVA DE MERCADO FINANCEIRO               ║
║   Setup Completo - S&P 500 + CSI500                        ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

Escolha o que deseja fazer:

  1) Setup Completo (Do Zero ao Fim)
     └─ Cria bancos, importa dados, cria tabelas e views

  2) Apenas Criar Views das 7 Perguntas
     └─ Requer que setup básico já esteja feito

  3) Apenas Consultar Respostas
     └─ Exibe os resultados das 7 perguntas

  4) Resetar Tudo e Recomeçar
     └─ Apaga bancos e recria do zero

  5) Sair

Opção [1-5]:
```

---

## 📂 Estrutura de Arquivos Importante

```
Gerenciamento-Banco-de-dados_v2/
│
├── 🔥 SETUP_COMPLETO.sh          # ← EXECUTE ESTE!
├── 📄 GUIA_RAPIDO.md             # ← Você está aqui
├── 📄 README.md                   # Documentação completa
├── 📄 perguntas-analise.md        # As 7 perguntas
│
├── 📂 scripts/2-analise/          # Scripts SQL principais
│   ├── 01_criar_tabelas_normalizadas.sql
│   ├── 04_criar_views_7_perguntas.sql    # ← Cria as 7 views
│   ├── 05_consultar_respostas.sql        # ← Queries de exemplo
│   └── README.md                          # Documentação das views
│
├── 📂 datasets/                   # CSVs originais
│   ├── S&P-500-companies.csv
│   ├── S&P500-fred.csv
│   ├── CSI500-part-1.csv
│   └── CSI500-part-2.csv
│
└── 📂 logs/                       # Logs de execução
```

---

## ⚠️ Troubleshooting

### Erro: "Container não está rodando"

```bash
docker-compose up -d
# ou
docker compose up -d
```

### Erro: "Permission denied"

```bash
chmod +x SETUP_COMPLETO.sh
chmod +x scripts-linux/*.sh
```

### Erro: "Database already exists"

```bash
# Execute opção 4 do menu para resetar
./SETUP_COMPLETO.sh
# Escolha: 4) Resetar Tudo e Recomeçar
```

### Views não aparecem no DataGrip

1. Clique com botão direito na conexão
2. Selecione **"Refresh"** (F5)
3. Expanda: `datasets` > `Views`

### Query retorna vazio

Verifique se as tabelas têm dados:

```sql
SELECT COUNT(*) FROM datasets.dbo.AcoesChinesas;
SELECT COUNT(*) FROM datasets.dbo.Empresas;
SELECT COUNT(*) FROM datasets.dbo.IndiceSP500;
```

---

## 🎓 Próximos Passos

1. ✅ Execute o setup completo
2. ✅ Abra o DataGrip e explore as views
3. ✅ Execute as queries de exemplo
4. ✅ Crie seus próprios relatórios
5. ✅ Exporte para Excel/Power BI/Tableau

---

## 📞 Suporte

- **Documentação Completa:** `README.md`
- **Documentação das Views:** `scripts/2-analise/README.md`
- **Lista de Perguntas:** `perguntas-analise.md`
- **Logs:** `logs/`

---

**Pronto para começar?**

```bash
./SETUP_COMPLETO.sh
```

**Boa análise! 📊📈**
