# 🧹 Scripts de Manutenção

## limpar_dados.sql

### ⚠️ Sobre o Warning do DataGrip

Você pode ver este aviso no DataGrip:
```
[2025-11-09 10:40:36] Unsafe query: 'Delete' statement without 'where' clears all data in the table
```

**Isso é NORMAL e ESPERADO!** ✅

### Por que o warning aparece?

- Este script foi **projetado intencionalmente** para limpar TODAS as tabelas
- O DataGrip mostra esse warning como medida de segurança
- Os comandos `DELETE` sem `WHERE` são propositais neste caso

### Como desabilitar o warning (opcional)?

Se o warning te incomoda, você tem 3 opções:

#### Opção 1: Ignorar o warning
- É seguro! O script está correto
- O warning é apenas informativo

#### Opção 2: Configurar o DataGrip (por projeto)
1. Abra DataGrip
2. Vá em **File → Settings → Editor → Inspections**
3. Procure por **SQL → Without WHERE**
4. Desmarque a opção
5. Clique em **OK**

#### Opção 3: Usar configuração do projeto
O arquivo `.idea/inspectionProfiles/Project_Default.xml` já está configurado para desabilitar esse warning no projeto.

### O que o script faz?

1. ✅ Limpa todas as tabelas do database `datasets`
2. ✅ Limpa todas as tabelas do database `FinanceDB`
3. ✅ Reseta os contadores IDENTITY
4. ✅ Mantém a estrutura das tabelas (não as remove)
5. ✅ Respeita foreign keys

### Quando usar?

- Quando quiser reimportar os dados do zero
- Para testar o processo de importação
- Para resetar o ambiente de desenvolvimento

### Como executar?

**Via script de automação (recomendado):**
```bash
./scripts-linux/4_limpar.sh
```

**Via comando direto:**
```bash
docker cp scripts/3-manutencao/limpar_dados.sql sqlserverCC:/tmp/limpar.sql
docker exec sqlserverCC /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P "Cc202505!" \
  -i /tmp/limpar.sql -C
```

### ⚠️ ATENÇÃO

- Este script **apaga TODOS os dados**
- Use apenas se tiver certeza
- As tabelas permanecem intactas, apenas os dados são removidos
- Você precisará executar o setup novamente para ter dados

---

**Versão:** 2.0
**Última atualização:** 2025-11-09
