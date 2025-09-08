---
author: GOD.
title: Calendar Sync.
date: August 2025
---

# Criação de Serviço

- Criar **service account** que será utilizada para manipular Calendar e Sheets:
  1. Logado na conta que irá utilizar o Calendar, abrir o [Console do Google Cloud](https://console.cloud.google.com)
  2. Criar projeto novo
  3. [APIs](https://console.cloud.google.com/apis/) -> Biblioteca -> **Google Calendar API** -> Ativar
  4. [APIs](https://console.cloud.google.com/apis/) -> Biblioteca -> **Google Sheet API** -> Ativar
  5. Em IAM & Admin abrir Service Accounts e criar conta de serviço, com permissão de proprietário
     - Abrir página da conta de serviço, clicando no link da coluna E-mail
  6. Na aba Keys, criar uma chave JSON
- Autorizar conta de serviço para acessar calendário:
  1. Google Calendar -> Configurações -> Clicar no calendário que será utilizado
  2. Em compartilhar com, dar permissão de edição para o e-mail da conta de serviço
- Criar uma planilha nova no Google Sheet, que será utilizada de log:
  1. Criar duas abas, com nomes `actions` e `errors`
  2. Compartilhar com o e-mail da conta de serviço, como editor
