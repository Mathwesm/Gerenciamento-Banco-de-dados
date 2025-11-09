# 🔕 Como Desabilitar Warnings do DataGrip

## Warning: "Unsafe query: Delete statement without where"

### O Problema

Ao abrir o arquivo `scripts/3-manutencao/limpar_dados.sql` no DataGrip, você vê:

```
[2025-11-09 10:40:36] Unsafe query: 'Delete' statement without 'where' clears all data in the table
```

### Por Que Acontece?

- O DataGrip tem uma verificação de segurança
- Ele avisa quando há comandos `DELETE` ou `UPDATE` sem cláusula `WHERE`
- Isso previne acidentes de apagar dados importantes

### É Perigoso?

**NÃO!** Neste caso específico:
- O script `limpar_dados.sql` foi **projetado** para limpar todas as tabelas
- Os comandos sem `WHERE` são **intencionais**
- É seguro executar quando você quer limpar os dados

## 🛠️ Soluções

### Solução 1: Ignorar o Warning (Recomendado)

- Não faça nada
- O warning é apenas informativo
- O script funciona perfeitamente

### Solução 2: Desabilitar para Este Projeto

**Passo a passo:**

1. Abra o **DataGrip**

2. Vá em **File → Settings** (ou **Ctrl+Alt+S**)

3. Navegue até:
   ```
   Editor → Inspections → SQL → Without WHERE
   ```

4. Desmarque a opção **"DELETE or UPDATE statement without WHERE"**

5. Clique em **Apply** e depois **OK**

6. Reabra o arquivo - o warning não aparecerá mais

### Solução 3: Configuração Automática

O projeto já inclui a configuração em:
```
.idea/inspectionProfiles/Project_Default.xml
```

Para ativar:

1. Feche o DataGrip
2. Delete a pasta `.idea` do projeto
3. Reabra o DataGrip
4. Ele vai recriar usando as configurações do projeto

### Solução 4: Suprimir por Arquivo

No início do arquivo SQL, adicione:

```sql
-- noinspection SqlWithoutWhereForFile
```

Isso suprime todos os warnings daquele arquivo específico.

## 🎯 Quando o Warning É Importante?

O warning DO DataGrip é útil em:
- Scripts de produção
- Updates em tabelas com dados importantes
- Quando você NÃO quer apagar todos os dados

No caso do `limpar_dados.sql`, o objetivo é exatamente limpar tudo, então o warning pode ser ignorado com segurança.

## 📋 Resumo

| Solução | Dificuldade | Recomendação |
|---------|-------------|--------------|
| Ignorar warning | Fácil | ⭐⭐⭐⭐⭐ Melhor |
| Desabilitar inspeção | Média | ⭐⭐⭐ Boa |
| Configuração automática | Fácil | ⭐⭐⭐⭐ Muito boa |
| Suprimir por arquivo | Fácil | ⭐⭐⭐ Boa |

---

**Dica:** Para outros scripts que você criar, **mantenha o warning ativado**! Ele previne acidentes.

