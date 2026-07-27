-- =====================================================================
-- POPULACAO PEQUENA
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
('Consultoria Logistica', 'Servico Geral'); 

INSERT INTO guindastes (nome_servico, tamanho_base, altura, bonus_aum) VALUES
('Icamento Torre 30t', 30, 40, 5.0);

INSERT INTO transportes (nome_servico, limite_carga) VALUES
('Transporte Carga Leve', 5000);

INSERT INTO acrescimos_transporte (nome_servico, limite_carga, percentual) VALUES
('Transporte Carga Leve', 1000, 1.0),  
('Transporte Carga Leve', 5000, 2.5); 

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

INSERT INTO trabalha_em (id_empresa, cpf_func, data_inicio, data_fim) VALUES
(2, '333.333.333-33', '2026-01-01', NULL);


INSERT INTO pedidos (data_solicitacao, data_resolucao, aceite, id_empresa, cod_cliente,
                      cidade_dest, estado_dest, endereco_dest, cidade_part, estado_part, endereco_part) VALUES
('2026-01-05', '2026-01-06', TRUE, 1, 1, 'Sao Paulo', 'SP', 'Rua Augusta, 500 - Sao Paulo/SP', 'Campinas', 'SP', 'Avenida Jose de Souza Campos, 100 - Campinas/SP');

INSERT INTO solicitam (codigo_pedido, nome_servico, tempo_duracao, carga) VALUES
(1, 'Transporte Carga Leve', 10, 800);


INSERT INTO pedidos (data_solicitacao, data_resolucao, aceite, id_empresa, cod_cliente,
                      cidade_dest, estado_dest, endereco_dest, cidade_part, estado_part, endereco_part) VALUES
('2026-01-10', '2026-01-11', TRUE, 1, 2, 'Campinas', 'SP', 'Avenida Jose de Souza Campos, 200 - Campinas/SP', 'Sao Paulo', 'SP', 'Avenida Paulista, 900 - Sao Paulo/SP');


INSERT INTO solicitam (codigo_pedido, nome_servico, tempo_duracao, carga) VALUES
(2, 'Transporte Carga Leve', 5, 4000);


INSERT INTO pedidos (data_solicitacao, data_resolucao, aceite, id_empresa, cod_cliente,
                      cidade_dest, estado_dest, endereco_dest, cidade_part, estado_part, endereco_part) VALUES
('2026-02-01', '2026-02-02', TRUE, 2, 1, 'Rio de Janeiro', 'RJ', 'Avenida Atlantica, 300 - Rio de Janeiro/RJ', 'Rio de Janeiro', 'RJ', 'Avenida Rio Branco, 156 - Rio de Janeiro/RJ');


INSERT INTO solicitam (codigo_pedido, nome_servico, tempo_duracao, carga) VALUES
(3, 'Icamento Torre 30t', 8, NULL),
(3, 'Consultoria Logistica', 2, NULL);

INSERT INTO atendimento (id_solicitacao, cpf_func)
SELECT id_solicitacao, '333.333.333-33' FROM solicitam WHERE codigo_pedido = 3 AND nome_servico = 'Icamento Torre 30t';


INSERT INTO pedidos (data_solicitacao, data_resolucao, aceite, id_empresa, cod_cliente,
                      cidade_dest, estado_dest, endereco_dest, cidade_part, estado_part, endereco_part) VALUES
('2026-02-15', NULL, FALSE, 2, 2, 'Rio de Janeiro', 'RJ', 'Rua Moreira Cesar, 40 - Niteroi/RJ', 'Rio de Janeiro', 'RJ', 'Avenida Rio Branco, 156 - Rio de Janeiro/RJ');


INSERT INTO solicitam (codigo_pedido, nome_servico, tempo_duracao, carga) VALUES
(4, 'Consultoria Logistica', 3, NULL);
