
INSERT INTO empresas (nome, endereco) VALUES ($1, $2) RETURNING id_empresa;

INSERT INTO telefone_empresa (id_empresa, telefone) VALUES ($1, $2);

INSERT INTO cidades (nome_cidade, estado) VALUES ($1, $2)
ON CONFLICT (nome_cidade, estado) DO NOTHING;

INSERT INTO servicos (nome_servico, tipo_servico) VALUES ($1, $2);

INSERT INTO guindastes (nome_servico, tamanho_base, altura, bonus_aum) VALUES ($1, $2, $3, $4);

INSERT INTO transportes (nome_servico, limite_carga) VALUES ($1, $2);
INSERT INTO acrescimos_transporte (nome_servico, limite_carga, percentual) VALUES ($1, $2, $3);

INSERT INTO oferece (id_empresa, nome_cidade, estado, nome_servico, preco_hora)
VALUES ($1, $2, $3, $4, $5);

INSERT INTO clientes (cpf, rg, nome_completo, endereco) VALUES ($1, $2, $3, $4) RETURNING cod_cliente;
INSERT INTO telefone_cliente (cod_cliente, telefone) VALUES ($1, $2);

INSERT INTO funcionarios (cpf_func, rg_func, endereco_func, nome_completo_func, telefone_contato, salario, tipo_func)
VALUES ($1, $2, $3, $4, $5, $6, $7);

INSERT INTO trabalha_em (id_empresa, cpf_func, data_inicio, data_fim)
VALUES ($1, $2, $3, $4);

INSERT INTO pedidos (data_solicitacao, aceite, id_empresa, cod_cliente,
                      cidade_dest, estado_dest, endereco_dest, cidade_part, estado_part, endereco_part)
VALUES (CURRENT_DATE, FALSE, $1, $2, $3, $4, $5, $6, $7, $8) RETURNING codigo;

INSERT INTO solicitam (codigo_pedido, nome_servico, tempo_duracao, carga) VALUES ($1, $2, $3, $4)
RETURNING id_solicitacao;

INSERT INTO atendimento (id_solicitacao, cpf_func) VALUES ($1, $2);



SELECT p.cidade_dest || '/' || p.estado_dest AS cidade,
       COUNT(*) AS qtd_servicos
FROM solicitam s
JOIN pedidos p ON p.codigo = s.codigo_pedido
GROUP BY p.cidade_dest, p.estado_dest
ORDER BY qtd_servicos DESC;

SELECT p.cidade_dest || '/' || p.estado_dest AS cidade,
       SUM(s.preco) AS valor_total
FROM solicitam s
JOIN pedidos p ON p.codigo = s.codigo_pedido
GROUP BY p.cidade_dest, p.estado_dest
ORDER BY valor_total DESC;

SELECT p.cidade_dest || '/' || p.estado_dest AS cidade,
       SUM(s.preco) AS valor_total
FROM solicitam s
JOIN pedidos p ON p.codigo = s.codigo_pedido
GROUP BY p.cidade_dest, p.estado_dest
ORDER BY valor_total DESC
LIMIT 5;

SELECT p.cidade_dest || '/' || p.estado_dest AS cidade,
       COUNT(*) AS qtd_servicos
FROM solicitam s
JOIN pedidos p ON p.codigo = s.codigo_pedido
GROUP BY p.cidade_dest, p.estado_dest
ORDER BY qtd_servicos DESC
LIMIT 5;

SELECT e.nome, COUNT(*) AS qtd_servicos
FROM solicitam s
JOIN pedidos p  ON p.codigo = s.codigo_pedido
JOIN empresas e ON e.id_empresa = p.id_empresa
GROUP BY e.id_empresa, e.nome
ORDER BY qtd_servicos DESC
LIMIT 5;

SELECT e.nome, SUM(s.preco) AS valor_ganho
FROM solicitam s
JOIN pedidos p  ON p.codigo = s.codigo_pedido
JOIN empresas e ON e.id_empresa = p.id_empresa
WHERE p.aceite = TRUE AND p.data_resolucao IS NOT NULL
GROUP BY e.id_empresa, e.nome
ORDER BY valor_ganho DESC
LIMIT 5;
