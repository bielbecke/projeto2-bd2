# Manifesto — frontend do sistema de mudanças

Frontend em React + Vite para o backend Flask/PostgreSQL do projeto (`backend/`).
Cobre todos os endpoints existentes: cidades, empresas, clientes, funcionários
(+ vínculos), serviços (+ hierarquia Guindaste/Transporte), preços por cidade
(`oferece`), pedidos (com itens e equipe) e o dashboard com os 6 relatórios
pedidos no enunciado (dois histogramas + quatro rankings top-5).

## Como rodar

1. Suba o backend Flask (porta `8000` por padrão, ver `backend/main.py`).
2. Instale as dependências do frontend:

   ```bash
   npm install
   ```

3. (Opcional) ajuste a URL da API em `.env` — já vem configurado para
   `http://localhost:8000`:

   ```
   VITE_API_URL=http://localhost:8000
   ```

4. Rode em modo desenvolvimento:

   ```bash
   npm run dev
   ```

   Acesse `http://localhost:5173`.

5. Para gerar a build de produção:

   ```bash
   npm run build
   npm run preview
   ```

## Estrutura

```
src/
  api.js               chamadas HTTP para cada rota do backend
  App.jsx               shell da aplicação + navegação por página
  components/           Sidebar, cards, gráfico de barras, toasts
  pages/
    Dashboard.jsx        resumo + histogramas + top-5 (cidades/empresas)
    Pedidos.jsx           lista + criação de pedidos com itens e equipe
    Empresas.jsx
    Clientes.jsx
    Servicos.jsx          catálogo (Guindaste/Transporte) + preços por cidade
    Funcionarios.jsx       cadastro + vínculos com empresas
    Cidades.jsx
  styles.css             tokens de design e todos os componentes visuais
```

## Notas sobre as regras de negócio

A interface **nunca calcula nem envia** `preco`, `preco_total` ou o
discriminador de hierarquia de serviço — esses valores são sempre
responsabilidade do banco (triggers descritos em `backend/02_triggers.sql`).
Quando um trigger recusa uma operação (ex.: empresa não oferece o serviço na
cidade de destino, ou serviço cadastrado como Guindaste e Transporte ao mesmo
tempo), a mensagem de erro do Postgres é repassada pelo backend e exibida
como um toast na tela.
