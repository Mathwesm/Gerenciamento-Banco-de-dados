# 🚀 COMECE AQUI - Início Rápido

## ⚡ 3 Comandos para Rodar Tudo

```bash
cd /home/matheus/DataGripProjects/Gerenciamento-Banco-de-dados_v2
chmod +x SETUP_COMPLETO.sh
./SETUP_COMPLETO.sh
```

**Escolha a opção 1** no menu que aparecer.

---

## 📊 O Que Este Projeto Faz

Analisa **~1.7 milhões de registros** de ações dos mercados:
- 🇺🇸 **S&P 500** (EUA) - 503 empresas
- 🇨🇳 **CSI500** (China) - 500+ empresas

**Responde 7 perguntas de negócio:**

1. ✅ Quais ações tiveram maior valorização no último ano?
2. ✅ Qual a volatilidade média por setor/indústria?
3. ✅ Quais empresas têm maior volume de negociação?
4. ✅ Quais ações cresceram consistentemente em 5 anos?
5. ✅ Quais setores têm melhor desempenho no S&P 500?
6. ✅ Quais ações caíram mais durante a crise COVID?
7. ⚠️ Análise de dividendos (dados não disponíveis)

---

## 📂 Arquivos Importantes

| Arquivo | Descrição |
|---------|-----------|
| `SETUP_COMPLETO.sh` | **EXECUTE ESTE!** Script principal |
| `GUIA_RAPIDO.md` | Guia visual com exemplos |
| `README.md` | Documentação completa |
| `perguntas-analise.md` | Detalhes das 7 perguntas |
| `scripts/2-analise/README.md` | Documentação das views SQL |

---

## 🎯 Após Executar o Setup

Você terá **7 views SQL** criadas no banco `datasets`:

```
vw_P1_MaiorValorizacaoUltimoAno
vw_P2_VolatilidadePorIndustria
vw_P3_MaiorVolumeNegociacao
vw_P4_CrescimentoConsistente5Anos
vw_P5_DesempenhoSetoresSP500
vw_P6_QuedaCriseCovid
vw_P7_DadosBaseParaDividendos
```

---

## 💻 Como Consultar

### No DataGrip (Recomendado)

1. Abra o DataGrip
2. Atualize (F5)
3. Navegue: `datasets` > `Views`
4. Clique direito na view > `Edit Data`

### Linha de Comando

```bash
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Cc202505!" -C \
  -Q "SELECT TOP 10 * FROM datasets.dbo.vw_P1_MaiorValorizacaoUltimoAno ORDER BY ValorizacaoPercentual DESC"
```

---

## 📚 Documentação

- 📖 **Guia Rápido:** [`GUIA_RAPIDO.md`](GUIA_RAPIDO.md)
- 📘 **Documentação Completa:** [`README.md`](README.md)
- 📙 **Detalhes das Perguntas:** [`perguntas-analise.md`](perguntas-analise.md)
- 📕 **Documentação das Views:** [`scripts/2-analise/README.md`](scripts/2-analise/README.md)

---

## ⏱ Tempo Estimado

- **Setup completo:** 5-10 minutos
- **Consulta de resultados:** Instantâneo

---

## ✅ Pré-requisitos

- Docker instalado e rodando
- 8GB RAM disponível
- 10GB espaço em disco

---

**Pronto para começar?**

```bash
./SETUP_COMPLETO.sh
```

**Boa análise! 📊**
