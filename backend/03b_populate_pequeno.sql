-- =====================================================================
-- POPULACAO PEQUENA E SIMPLES 
-- =====================================================================

INSERT INTO empresas (nome, endereco) VALUES
('TransLog Brasil', 'Avenida Paulista, 1106 - Sao Paulo/SP - CEP 04538-133'),
('GuindasteMax',     'Avenida Rio Branco, 156 - Rio de Janeiro/RJ - CEP 20040-007');

INSERT INTO cidades (nome_cidade, estado) VALUES
('Sao Paulo','SP'),
('Campinas','SP'),
('Rio de Janeiro','RJ');

INSERT INTO servicos (nome_servico, tipo_servico) VALUES
('Transporte Carga Leve', 'Transporte'),
('Icamento Torre 30t',    'Icamento'),
('Consultoria Logistica', 'Servico Geral');   -- sem especializacao (hierarquia parcial)

-- Icamento Torre 30t = GUINDASTE, bonus fixo de 5% sobre o preco/hora
INSERT INTO guindastes (nome_servico, tamanho_base, altura, bonus_aum) VALUES
('Icamento Torre 30t', 30, 40, 5.0);

-- Transporte Carga Leve = TRANSPORTE, com 2 faixas de acrescimo por carga
INSERT INTO transportes (nome_servico, limite_carga) VALUES
('Transporte Carga Leve', 5000);

INSERT INTO acrescimos_transporte (nome_servico, limite_carga, percentual) VALUES
('Transporte Carga Leve', 1000, 1.0),   -- carga ate 1000kg: +1%
('Transporte Carga Leve', 5000, 2.5);   -- carga de 1001 a 5000kg: +2.5%

-- precos/hora por empresa+cidade+servico (relacionamento ternario 'oferece')
INSERT INTO oferece (id_empresa, nome_cidade, estado, nome_servico, preco_hora) VALUES
(1, 'Sao Paulo', 'SP', 'Transporte Carga Leve', 100.00),
(1, 'Campinas',  'SP', 'Transporte Carga Leve',  90.00),
(2, 'Rio de Janeiro', 'RJ', 'Icamento Torre 30t',    300.00),
(2, 'Rio de Janeiro', 'RJ', 'Consultoria Logistica', 150.00);

INSERT INTO clientes (cpf, rg, nome_completo, endereco) VALUES
('111.111.111-11', 'MG1111', 'Cliente A - Construtora Horizonte', 'Rua Augusta, 500 - Sao Paulo/SP'),
('222.222.222-22', 'MG2222', 'Cliente B - Portos do Sul Ltda',    'Rua Moreira Cesar, 40 - Niteroi/RJ');

INSERT INTO funcionarios (cpf_func, rg_func, nome_completo_func, telefone_contato, salario, tipo_func) VALUES
('333.333.333-33', 'RGF001', 'Joao Silva',  '11-98888-0001', 4500.00, 'Motorista'),
('444.444.444-44', 'RGF002', 'Maria Souza', '21-98888-0002', 5200.00, 'Operador');

-- Joao Silva trabalha na GuindasteMax desde 01/01/2026 (vinculo ativo)
INSERT INTO trabalha_em (id_empresa, cpf_func, data_inicio, data_fim) VALUES
(2, '333.333.333-33', '2026-01-01', NULL);

-- =====================================================================
-- 4 PEDIDOS -- valores pensados para conferencia manual (ver comentario
-- com o calculo esperado ao lado de cada um)
-- =====================================================================

-- Pedido 1: TransLog Brasil, Cliente A, destino Sao Paulo/SP, JA EXECUTADO
INSERT INTO pedidos (data_solicitacao, data_resolucao, aceite, id_empresa, cod_cliente,
                      cidade_dest, estado_dest, endereco_dest, cidade_part, estado_part, endereco_part) VALUES
('2026-01-05', '2026-01-06', TRUE, 1, 1, 'Sao Paulo', 'SP', 'Rua Augusta, 500 - Sao Paulo/SP', 'Campinas', 'SP', 'Avenida Jose de Souza Campos, 100 - Campinas/SP');

-- Transporte Carga Leve, 10h, carga 800kg (faixa <=1000kg = +1%)
-- preco esperado = 10 * 100.00 * 1.01 = 1010.00
INSERT INTO solicitam (codigo_pedido, nome_servico, tempo_duracao, carga) VALUES
(1, 'Transporte Carga Leve', 10, 800);


-- Pedido 2: TransLog Brasil, Cliente B, destino Campinas/SP, JA EXECUTADO
INSERT INTO pedidos (data_solicitacao, data_resolucao, aceite, id_empresa, cod_cliente,
                      cidade_dest, estado_dest, endereco_dest, cidade_part, estado_part, endereco_part) VALUES
('2026-01-10', '2026-01-11', TRUE, 1, 2, 'Campinas', 'SP', 'Avenida Jose de Souza Campos, 200 - Campinas/SP', 'Sao Paulo', 'SP', 'Avenida Paulista, 900 - Sao Paulo/SP');

-- Transporte Carga Leve, 5h, carga 4000kg (faixa <=5000kg = +2.5%)
-- preco esperado = 5 * 90.00 * 1.025 = 461.25
INSERT INTO solicitam (codigo_pedido, nome_servico, tempo_duracao, carga) VALUES
(2, 'Transporte Carga Leve', 5, 4000);


-- Pedido 3: GuindasteMax, Cliente A, destino Rio de Janeiro/RJ, JA EXECUTADO, com equipe
INSERT INTO pedidos (data_solicitacao, data_resolucao, aceite, id_empresa, cod_cliente,
                      cidade_dest, estado_dest, endereco_dest, cidade_part, estado_part, endereco_part) VALUES
('2026-02-01', '2026-02-02', TRUE, 2, 1, 'Rio de Janeiro', 'RJ', 'Avenida Atlantica, 300 - Rio de Janeiro/RJ', 'Rio de Janeiro', 'RJ', 'Avenida Rio Branco, 156 - Rio de Janeiro/RJ');

-- Icamento Torre 30t, 8h (bonus fixo de guindaste = +5%)
-- preco esperado = 8 * 300.00 * 1.05 = 2520.00
-- Consultoria Logistica, 2h (sem especializacao, sem acrescimo)
-- preco esperado = 2 * 150.00 = 300.00
INSERT INTO solicitam (codigo_pedido, nome_servico, tempo_duracao, carga) VALUES
(3, 'Icamento Torre 30t', 8, NULL),
(3, 'Consultoria Logistica', 2, NULL);

-- Joao Silva atendeu o icamento desse pedido
INSERT INTO atendimento (id_solicitacao, cpf_func)
SELECT id_solicitacao, '333.333.333-33' FROM solicitam WHERE codigo_pedido = 3 AND nome_servico = 'Icamento Torre 30t';


-- Pedido 4: GuindasteMax, Cliente B, destino Rio de Janeiro/RJ, AINDA PENDENTE (nao executado)
INSERT INTO pedidos (data_solicitacao, data_resolucao, aceite, id_empresa, cod_cliente,
                      cidade_dest, estado_dest, endereco_dest, cidade_part, estado_part, endereco_part) VALUES
('2026-02-15', NULL, FALSE, 2, 2, 'Rio de Janeiro', 'RJ', 'Rua Moreira Cesar, 40 - Niteroi/RJ', 'Rio de Janeiro', 'RJ', 'Avenida Rio Branco, 156 - Rio de Janeiro/RJ');

-- Consultoria Logistica, 3h -- preco esperado = 3 * 150.00 = 450.00
-- (NAO entra na consulta vi, porque o pedido ainda nao foi resolvido)
INSERT INTO solicitam (codigo_pedido, nome_servico, tempo_duracao, carga) VALUES
(4, 'Consultoria Logistica', 3, NULL);


-- =====================================================================
-- GABARITO -- o que cada consulta de 04_consultas.sql DEVE retornar
-- com este dataset (confira rodando e comparando com isto):
-- =====================================================================
--
-- solicitam.preco (calculado pelo trigger, item c):
--   pedido 1 - Transporte Carga Leve  -> 1010.00   (10h * 100.00 * 1.01)
--   pedido 2 - Transporte Carga Leve  ->  461.25   (5h  *  90.00 * 1.025)
--   pedido 3 - Icamento Torre 30t     -> 2520.00   (8h  * 300.00 * 1.05)
--   pedido 3 - Consultoria Logistica  ->  300.00   (2h  * 150.00)
--   pedido 4 - Consultoria Logistica  ->  450.00   (3h  * 150.00)
--
-- pedidos.preco_total (calculado pelo trigger, item b):
--   pedido 1 -> 1010.00
--   pedido 2 ->  461.25
--   pedido 3 -> 2820.00   (2520.00 + 300.00)
--   pedido 4 ->  450.00
--
-- i.  Qtd de servicos por cidade:
--   Rio de Janeiro/RJ -> 3   (2 do pedido 3 + 1 do pedido 4)
--   Sao Paulo/SP      -> 1
--   Campinas/SP       -> 1
--
-- ii. Valor por cidade:
--   Rio de Janeiro/RJ -> 3270.00   (2520.00 + 300.00 + 450.00)
--   Sao Paulo/SP      -> 1010.00
--   Campinas/SP       ->  461.25
--
-- iii. Top cidades por valor (mesma ordem do item ii, ja que so ha 3 cidades)
--
-- iv. Top cidades por qtd (mesma ordem do item i)
--
-- v. Top empresas por numero de servicos solicitados:
--   GuindasteMax    -> 3   (2 do pedido 3 + 1 do pedido 4)
--   TransLog Brasil -> 2   (1 do pedido 1 + 1 do pedido 2)
--
-- vi. Top empresas por valor ganho em servicos EXECUTADOS
--     (pedido 4 fica de fora -- ainda nao foi resolvido):
--   GuindasteMax    -> 2820.00   (so o pedido 3, que foi resolvido)
--   TransLog Brasil -> 1471.25   (1010.00 + 461.25)
