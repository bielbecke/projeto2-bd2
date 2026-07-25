
CREATE TABLE empresas (
    id_empresa   SERIAL PRIMARY KEY,
    nome         VARCHAR(120) NOT NULL UNIQUE,
    endereco     VARCHAR(200) NOT NULL
);

CREATE TABLE telefone_empresa (
    id_empresa   INTEGER NOT NULL REFERENCES empresas(id_empresa) ON DELETE CASCADE,
    telefone     VARCHAR(20) NOT NULL,
    PRIMARY KEY (id_empresa, telefone)
);

CREATE TABLE cidades (
    nome_cidade  VARCHAR(80) NOT NULL,
    estado       CHAR(2) NOT NULL,
    PRIMARY KEY (nome_cidade, estado)
);

CREATE TABLE servicos (
    nome_servico     VARCHAR(80) PRIMARY KEY,
    tipo_servico     VARCHAR(60),
    especializacao   VARCHAR(12) CHECK (especializacao IN ('GUINDASTE','TRANSPORTE') OR especializacao IS NULL)
);

CREATE TABLE guindastes (
    nome_servico   VARCHAR(80) PRIMARY KEY REFERENCES servicos(nome_servico) ON DELETE CASCADE,
    tamanho_base   NUMERIC(10,2),
    altura         NUMERIC(10,2),
);

CREATE TABLE transportes (
    nome_servico   VARCHAR(80) PRIMARY KEY REFERENCES servicos(nome_servico) ON DELETE CASCADE,
    limite_carga   NUMERIC(12,2)
);

CREATE TABLE acrescimos_transporte (
    id_acrescimo   SERIAL PRIMARY KEY,
    nome_servico   VARCHAR(80) NOT NULL REFERENCES transportes(nome_servico) ON DELETE CASCADE,
    percentual     NUMERIC(5,2) NOT NULL CHECK (percentual >= 0),
    UNIQUE(nome_servico, limite_carga)
);

CREATE TABLE oferece (
    id_oferta     SERIAL PRIMARY KEY,
    id_empresa    INTEGER NOT NULL REFERENCES empresas(id_empresa),
    nome_cidade   VARCHAR(80) NOT NULL,
    estado        CHAR(2) NOT NULL,
    nome_servico  VARCHAR(80) NOT NULL REFERENCES servicos(nome_servico),
    preco_hora    NUMERIC(10,2) NOT NULL CHECK (preco_hora > 0),
    FOREIGN KEY (nome_cidade, estado) REFERENCES cidades(nome_cidade, estado),
    UNIQUE (id_empresa, nome_cidade, estado, nome_servico)
);

CREATE TABLE clientes (
    cod_cliente     SERIAL PRIMARY KEY,
    cpf             VARCHAR(14) NOT NULL UNIQUE,
    rg              VARCHAR(20),
    nome_completo   VARCHAR(150) NOT NULL,
    endereco        VARCHAR(200)
);

CREATE TABLE telefone_cliente (
    id_telefone   SERIAL PRIMARY KEY,
    cod_cliente   INTEGER NOT NULL REFERENCES clientes(cod_cliente) ON DELETE CASCADE,
    telefone      VARCHAR(20) NOT NULL
);

CREATE TABLE funcionarios (
    cpf_func            VARCHAR(14) PRIMARY KEY,
    rg_func             VARCHAR(20),
    endereco_func       VARCHAR(200),
    nome_completo_func  VARCHAR(150) NOT NULL,
    telefone_contato    VARCHAR(20),
    salario             NUMERIC(10,2) CHECK (salario > 0),
    tipo_func           VARCHAR(40)
);

CREATE TABLE trabalha_em (
    id_empresa    INTEGER NOT NULL REFERENCES empresas(id_empresa) ON DELETE CASCADE,
    cpf_func      VARCHAR(14) NOT NULL REFERENCES funcionarios(cpf_func) ON DELETE CASCADE,
    data_inicio   DATE NOT NULL DEFAULT CURRENT_DATE,
    PRIMARY KEY (id_empresa, cpf_func, data_inicio),
    CHECK (data_fim IS NULL OR data_fim >= data_inicio)
);

CREATE TABLE pedidos (
    codigo             SERIAL PRIMARY KEY,
    data_solicitacao   DATE NOT NULL DEFAULT CURRENT_DATE,
    data_resolucao     DATE,
    aceite             BOOLEAN NOT NULL DEFAULT FALSE,
    id_empresa         INTEGER NOT NULL REFERENCES empresas(id_empresa),
    cod_cliente        INTEGER NOT NULL REFERENCES clientes(cod_cliente),
    cidade_dest        VARCHAR(80) NOT NULL,
    estado_dest        CHAR(2) NOT NULL,
    endereco_dest      VARCHAR(200),
    cidade_part        VARCHAR(80) NOT NULL,
    estado_part        CHAR(2) NOT NULL,
    endereco_part      VARCHAR(200),
    FOREIGN KEY (cidade_dest, estado_dest) REFERENCES cidades(nome_cidade, estado),
    FOREIGN KEY (cidade_part, estado_part) REFERENCES cidades(nome_cidade, estado),
    CHECK (data_resolucao IS NULL OR data_resolucao >= data_solicitacao)
);

CREATE TABLE solicitam (
    id_solicitacao   SERIAL PRIMARY KEY,
    codigo_pedido    INTEGER NOT NULL REFERENCES pedidos(codigo) ON DELETE CASCADE,
    nome_servico     VARCHAR(80) NOT NULL REFERENCES servicos(nome_servico),
    UNIQUE (codigo_pedido, nome_servico)
);

CREATE TABLE atendimento (
    id_solicitacao   INTEGER NOT NULL REFERENCES solicitam(id_solicitacao) ON DELETE CASCADE,
    cpf_func         VARCHAR(14) NOT NULL REFERENCES funcionarios(cpf_func),
    PRIMARY KEY (id_solicitacao, cpf_func)
);

CREATE INDEX idx_solicitam_pedido  ON solicitam(codigo_pedido);
CREATE INDEX idx_pedidos_empresa   ON pedidos(id_empresa);
CREATE INDEX idx_pedidos_cliente   ON pedidos(cod_cliente);
CREATE INDEX idx_pedidos_cidadedest ON pedidos(cidade_dest, estado_dest);
CREATE INDEX idx_trabalha_em_func  ON trabalha_em(cpf_func);
CREATE INDEX idx_atendimento_func  ON atendimento(cpf_func);

CREATE INDEX idx_pedidos_executados ON pedidos(id_empresa)
    WHERE aceite = TRUE AND data_resolucao IS NOT NULL;

CREATE INDEX idx_telefone_cliente_cliente ON telefone_cliente(cod_cliente);

CREATE INDEX idx_acrescimos_transporte_servico ON acrescimos_transporte(nome_servico, limite_carga);
