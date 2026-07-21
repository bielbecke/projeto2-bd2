-- =====================================================================
-- (a) CADASTROS (templates parametrizados com $1, $2... para uso via
--     aplicacao / driver; substitua pelos valores desejados)
-- =====================================================================

-- Cadastrar empresa
INSERT INTO empresas (nome, endereco) VALUES ($1, $2) RETURNING id_empresa;

-- Cadastrar telefone de empresa
INSERT INTO telefone_empresa (id_empresa, telefone) VALUES ($1, $2);

-- Cadastrar cidade
INSERT INTO cidades (nome_cidade, estado) VALUES ($1, $2)
ON CONFLICT (nome_cidade, estado) DO NOTHING;

-- Cadastrar servico (generico, sem especializacao)
INSERT INTO servicos (nome_servico, tipo_servico) VALUES ($1, $2);

-- Especializar servico em Guindaste
INSERT INTO guindastes (nome_servico, tamanho_base, altura, bonus_aum) VALUES ($1, $2, $3, $4);

-- Especializar servico em Transporte (+ faixas de acrescimo)
INSERT INTO transportes (nome_servico, limite_carga) VALUES ($1, $2);
INSERT INTO acrescimos_transporte (nome_servico, limite_carga, percentual) VALUES ($1, $2, $3);

-- Empresa passa a oferecer um servico em uma cidade
INSERT INTO oferece (id_empresa, nome_cidade, estado, nome_servico, preco_hora)
VALUES ($1, $2, $3, $4, $5);

-- Cadastrar cliente
INSERT INTO clientes (cpf, rg, nome_completo, endereco) VALUES ($1, $2, $3, $4) RETURNING cod_cliente;
INSERT INTO telefone_cliente (cod_cliente, telefone) VALUES ($1, $2);

-- Cadastrar funcionario
INSERT INTO funcionarios (cpf_func, rg_func, endereco_func, nome_completo_func, telefone_contato, salario, tipo_func)
VALUES ($1, $2, $3, $4, $5, $6, $7);

-- Vincular funcionario a uma empresa (N:N com periodo -- um funcionario
-- pode trabalhar para varias empresas em horarios/periodos diferentes)
INSERT INTO trabalha_em (id_empresa, cpf_func, data_inicio, data_fim)
VALUES ($1, $2, $3, $4);

-- Cadastrar pedido (preco_total nasce em 0 e e recalculado ao inserir em 'solicitam')
INSERT INTO pedidos (data_solicitacao, aceite, id_empresa, cod_cliente,
                      cidade_dest, estado_dest, endereco_dest, cidade_part, estado_part, endereco_part)
VALUES (CURRENT_DATE, FALSE, $1, $2, $3, $4, $5, $6, $7, $8) RETURNING codigo;

-- Adicionar um servico solicitado a um pedido (preco calculado automaticamente)
INSERT INTO solicitam (codigo_pedido, nome_servico, tempo_duracao, carga) VALUES ($1, $2, $3, $4)
RETURNING id_solicitacao;

-- Registrar quais funcionarios trabalharam nesse servico especifico
-- (chamar 1x por funcionario, depois que o pedido for aceite e o servico executado)
INSERT INTO atendimento (id_solicitacao, cpf_func) VALUES ($1, $2);


-- =====================================================================
-- (b) CONSULTAS ANALITICAS
-- =====================================================================

-- i. Numero de servicos solicitados por cidade (histograma) -- cidade de destino do pedido
SELECT p.cidade_dest || '/' || p.estado_dest AS cidade,
       COUNT(*) AS qtd_servicos
FROM solicitam s
JOIN pedidos p ON p.codigo = s.codigo_pedido
GROUP BY p.cidade_dest, p.estado_dest
ORDER BY qtd_servicos DESC;

-- ii. Valor pago em servicos solicitados por cidade (histograma)
SELECT p.cidade_dest || '/' || p.estado_dest AS cidade,
       SUM(s.preco) AS valor_total
FROM solicitam s
JOIN pedidos p ON p.codigo = s.codigo_pedido
GROUP BY p.cidade_dest, p.estado_dest
ORDER BY valor_total DESC;

-- iii. Top 5 cidades por valor investido em servicos
SELECT p.cidade_dest || '/' || p.estado_dest AS cidade,
       SUM(s.preco) AS valor_total
FROM solicitam s
JOIN pedidos p ON p.codigo = s.codigo_pedido
GROUP BY p.cidade_dest, p.estado_dest
ORDER BY valor_total DESC
LIMIT 5;

-- iv. Top 5 cidades por numero de servicos
SELECT p.cidade_dest || '/' || p.estado_dest AS cidade,
       COUNT(*) AS qtd_servicos
FROM solicitam s
JOIN pedidos p ON p.codigo = s.codigo_pedido
GROUP BY p.cidade_dest, p.estado_dest
ORDER BY qtd_servicos DESC
LIMIT 5;

-- v. Top 5 empresas por numero de servicos solicitados
SELECT e.nome, COUNT(*) AS qtd_servicos
FROM solicitam s
JOIN pedidos p  ON p.codigo = s.codigo_pedido
JOIN empresas e ON e.id_empresa = p.id_empresa
GROUP BY e.id_empresa, e.nome
ORDER BY qtd_servicos DESC
LIMIT 5;

-- vi. Top 5 empresas por valores ganhos em servicos executados
--     (pedido aceito e ja resolvido = servico executado)
SELECT e.nome, SUM(s.preco) AS valor_ganho
FROM solicitam s
JOIN pedidos p  ON p.codigo = s.codigo_pedido
JOIN empresas e ON e.id_empresa = p.id_empresa
WHERE p.aceite = TRUE AND p.data_resolucao IS NOT NULL
GROUP BY e.id_empresa, e.nome
ORDER BY valor_ganho DESC
LIMIT 5;
