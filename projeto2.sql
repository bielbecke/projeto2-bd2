--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
-- Dumped by pg_dump version 17.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: fn_atualiza_total_pedido(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_atualiza_total_pedido() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_codigo INTEGER;
BEGIN
    v_codigo := COALESCE(NEW.codigo_pedido, OLD.codigo_pedido);
    UPDATE pedidos
       SET preco_total = (SELECT COALESCE(SUM(preco), 0) FROM solicitam WHERE codigo_pedido = v_codigo)
     WHERE codigo = v_codigo;
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.fn_atualiza_total_pedido() OWNER TO postgres;

--
-- Name: fn_bloqueia_update_manual_total(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_bloqueia_update_manual_total() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.preco_total <> OLD.preco_total AND
       NOT EXISTS (SELECT 1 FROM solicitam WHERE codigo_pedido = NEW.codigo AND
                   NEW.preco_total = (SELECT COALESCE(SUM(preco),0) FROM solicitam WHERE codigo_pedido = NEW.codigo)) THEN
        RAISE EXCEPTION 'preco_total nao pode ser alterado manualmente; ele e derivado de solicitam.';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_bloqueia_update_manual_total() OWNER TO postgres;

--
-- Name: fn_calcula_preco_solicitacao(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_calcula_preco_solicitacao() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_preco_hora   NUMERIC(10,2);
    v_percentual   NUMERIC(5,2) := 0;
BEGIN
    SELECT o.preco_hora INTO v_preco_hora
    FROM oferece o
    JOIN pedidos p ON p.id_empresa = o.id_empresa
                  AND p.cidade_dest = o.nome_cidade
                  AND p.estado_dest = o.estado
    WHERE p.codigo = NEW.codigo_pedido
      AND o.nome_servico = NEW.nome_servico;

    IF v_preco_hora IS NULL THEN
        RAISE EXCEPTION 'A empresa do pedido % nao oferece o servico % na cidade de destino.',
            NEW.codigo_pedido, NEW.nome_servico;
    END IF;

    -- acrescimo de Guindaste (bonus fixo em %)
    SELECT bonus_aum INTO v_percentual FROM guindastes WHERE nome_servico = NEW.nome_servico;

    -- acrescimo de Transporte (depende da faixa de carga informada)
    IF v_percentual IS NULL THEN
        SELECT percentual INTO v_percentual
        FROM acrescimos_transporte
        WHERE nome_servico = NEW.nome_servico
          AND limite_carga = (
                SELECT MIN(limite_carga) FROM acrescimos_transporte
                WHERE nome_servico = NEW.nome_servico
                  AND limite_carga >= COALESCE(NEW.carga, 0)
          );
    END IF;

    v_percentual := COALESCE(v_percentual, 0);

    NEW.preco := ROUND(NEW.tempo_duracao * v_preco_hora * (1 + v_percentual / 100.0), 2);
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_calcula_preco_solicitacao() OWNER TO postgres;

--
-- Name: fn_check_disjuncao_guindaste(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_check_disjuncao_guindaste() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM transportes WHERE nome_servico = NEW.nome_servico) THEN
        RAISE EXCEPTION 'Servico % ja e um Transporte. Hierarquia Guindaste/Transporte e disjunta.', NEW.nome_servico;
    END IF;
    UPDATE servicos SET especializacao = 'GUINDASTE' WHERE nome_servico = NEW.nome_servico;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_check_disjuncao_guindaste() OWNER TO postgres;

--
-- Name: fn_check_disjuncao_transporte(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_check_disjuncao_transporte() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM guindastes WHERE nome_servico = NEW.nome_servico) THEN
        RAISE EXCEPTION 'Servico % ja e um Guindaste. Hierarquia Guindaste/Transporte e disjunta.', NEW.nome_servico;
    END IF;
    UPDATE servicos SET especializacao = 'TRANSPORTE' WHERE nome_servico = NEW.nome_servico;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_check_disjuncao_transporte() OWNER TO postgres;

--
-- Name: fn_desmarca_especializacao(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_desmarca_especializacao() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE servicos SET especializacao = NULL WHERE nome_servico = OLD.nome_servico;
    RETURN OLD;
END;
$$;


ALTER FUNCTION public.fn_desmarca_especializacao() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: acrescimos_transporte; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.acrescimos_transporte (
    id_acrescimo integer NOT NULL,
    nome_servico character varying(80) NOT NULL,
    limite_carga numeric(12,2) NOT NULL,
    percentual numeric(5,2) NOT NULL,
    CONSTRAINT acrescimos_transporte_percentual_check CHECK ((percentual >= (0)::numeric))
);


ALTER TABLE public.acrescimos_transporte OWNER TO postgres;

--
-- Name: acrescimos_transporte_id_acrescimo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.acrescimos_transporte_id_acrescimo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.acrescimos_transporte_id_acrescimo_seq OWNER TO postgres;

--
-- Name: acrescimos_transporte_id_acrescimo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.acrescimos_transporte_id_acrescimo_seq OWNED BY public.acrescimos_transporte.id_acrescimo;


--
-- Name: atendimento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.atendimento (
    id_solicitacao integer NOT NULL,
    cpf_func character varying(14) NOT NULL
);


ALTER TABLE public.atendimento OWNER TO postgres;

--
-- Name: cidades; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cidades (
    nome_cidade character varying(80) NOT NULL,
    estado character(2) NOT NULL
);


ALTER TABLE public.cidades OWNER TO postgres;

--
-- Name: clientes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.clientes (
    cod_cliente integer NOT NULL,
    cpf character varying(14) NOT NULL,
    rg character varying(20),
    nome_completo character varying(150) NOT NULL,
    endereco character varying(200)
);


ALTER TABLE public.clientes OWNER TO postgres;

--
-- Name: clientes_cod_cliente_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.clientes_cod_cliente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.clientes_cod_cliente_seq OWNER TO postgres;

--
-- Name: clientes_cod_cliente_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.clientes_cod_cliente_seq OWNED BY public.clientes.cod_cliente;


--
-- Name: empresas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.empresas (
    id_empresa integer NOT NULL,
    nome character varying(120) NOT NULL,
    endereco character varying(200) NOT NULL
);


ALTER TABLE public.empresas OWNER TO postgres;

--
-- Name: empresas_id_empresa_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.empresas_id_empresa_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.empresas_id_empresa_seq OWNER TO postgres;

--
-- Name: empresas_id_empresa_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.empresas_id_empresa_seq OWNED BY public.empresas.id_empresa;


--
-- Name: funcionarios; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.funcionarios (
    cpf_func character varying(14) NOT NULL,
    rg_func character varying(20),
    endereco_func character varying(200),
    nome_completo_func character varying(150) NOT NULL,
    telefone_contato character varying(20),
    salario numeric(10,2),
    tipo_func character varying(40),
    CONSTRAINT funcionarios_salario_check CHECK ((salario > (0)::numeric))
);


ALTER TABLE public.funcionarios OWNER TO postgres;

--
-- Name: guindastes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.guindastes (
    nome_servico character varying(80) NOT NULL,
    tamanho_base numeric(10,2),
    altura numeric(10,2),
    bonus_aum numeric(5,2) DEFAULT 0 NOT NULL,
    CONSTRAINT guindastes_bonus_aum_check CHECK ((bonus_aum >= (0)::numeric))
);


ALTER TABLE public.guindastes OWNER TO postgres;

--
-- Name: oferece; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oferece (
    id_oferta integer NOT NULL,
    id_empresa integer NOT NULL,
    nome_cidade character varying(80) NOT NULL,
    estado character(2) NOT NULL,
    nome_servico character varying(80) NOT NULL,
    preco_hora numeric(10,2) NOT NULL,
    CONSTRAINT oferece_preco_hora_check CHECK ((preco_hora > (0)::numeric))
);


ALTER TABLE public.oferece OWNER TO postgres;

--
-- Name: oferece_id_oferta_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.oferece_id_oferta_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.oferece_id_oferta_seq OWNER TO postgres;

--
-- Name: oferece_id_oferta_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.oferece_id_oferta_seq OWNED BY public.oferece.id_oferta;


--
-- Name: pedidos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pedidos (
    codigo integer NOT NULL,
    data_solicitacao date DEFAULT CURRENT_DATE NOT NULL,
    data_resolucao date,
    preco_total numeric(12,2) DEFAULT 0 NOT NULL,
    aceite boolean DEFAULT false NOT NULL,
    id_empresa integer NOT NULL,
    cod_cliente integer NOT NULL,
    cidade_dest character varying(80) NOT NULL,
    estado_dest character(2) NOT NULL,
    endereco_dest character varying(200),
    cidade_part character varying(80) NOT NULL,
    estado_part character(2) NOT NULL,
    endereco_part character varying(200),
    CONSTRAINT pedidos_check CHECK (((data_resolucao IS NULL) OR (data_resolucao >= data_solicitacao)))
);


ALTER TABLE public.pedidos OWNER TO postgres;

--
-- Name: pedidos_codigo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pedidos_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pedidos_codigo_seq OWNER TO postgres;

--
-- Name: pedidos_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pedidos_codigo_seq OWNED BY public.pedidos.codigo;


--
-- Name: servicos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.servicos (
    nome_servico character varying(80) NOT NULL,
    tipo_servico character varying(60),
    especializacao character varying(12),
    CONSTRAINT servicos_especializacao_check CHECK ((((especializacao)::text = ANY ((ARRAY['GUINDASTE'::character varying, 'TRANSPORTE'::character varying])::text[])) OR (especializacao IS NULL)))
);


ALTER TABLE public.servicos OWNER TO postgres;

--
-- Name: solicitam; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.solicitam (
    id_solicitacao integer NOT NULL,
    codigo_pedido integer NOT NULL,
    nome_servico character varying(80) NOT NULL,
    tempo_duracao numeric(8,2) NOT NULL,
    carga numeric(12,2),
    data_fim date,
    preco numeric(12,2) DEFAULT 0 NOT NULL,
    CONSTRAINT solicitam_tempo_duracao_check CHECK ((tempo_duracao > (0)::numeric))
);


ALTER TABLE public.solicitam OWNER TO postgres;

--
-- Name: solicitam_id_solicitacao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.solicitam_id_solicitacao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.solicitam_id_solicitacao_seq OWNER TO postgres;

--
-- Name: solicitam_id_solicitacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.solicitam_id_solicitacao_seq OWNED BY public.solicitam.id_solicitacao;


--
-- Name: telefone_cliente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.telefone_cliente (
    id_telefone integer NOT NULL,
    cod_cliente integer NOT NULL,
    telefone character varying(20) NOT NULL
);


ALTER TABLE public.telefone_cliente OWNER TO postgres;

--
-- Name: telefone_cliente_id_telefone_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.telefone_cliente_id_telefone_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.telefone_cliente_id_telefone_seq OWNER TO postgres;

--
-- Name: telefone_cliente_id_telefone_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.telefone_cliente_id_telefone_seq OWNED BY public.telefone_cliente.id_telefone;


--
-- Name: telefone_empresa; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.telefone_empresa (
    id_empresa integer NOT NULL,
    telefone character varying(20) NOT NULL
);


ALTER TABLE public.telefone_empresa OWNER TO postgres;

--
-- Name: trabalha_em; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.trabalha_em (
    id_empresa integer NOT NULL,
    cpf_func character varying(14) NOT NULL,
    data_inicio date DEFAULT CURRENT_DATE NOT NULL,
    data_fim date,
    CONSTRAINT trabalha_em_check CHECK (((data_fim IS NULL) OR (data_fim >= data_inicio)))
);


ALTER TABLE public.trabalha_em OWNER TO postgres;

--
-- Name: transportes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transportes (
    nome_servico character varying(80) NOT NULL,
    limite_carga numeric(12,2)
);


ALTER TABLE public.transportes OWNER TO postgres;

--
-- Name: acrescimos_transporte id_acrescimo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acrescimos_transporte ALTER COLUMN id_acrescimo SET DEFAULT nextval('public.acrescimos_transporte_id_acrescimo_seq'::regclass);


--
-- Name: clientes cod_cliente; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clientes ALTER COLUMN cod_cliente SET DEFAULT nextval('public.clientes_cod_cliente_seq'::regclass);


--
-- Name: empresas id_empresa; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.empresas ALTER COLUMN id_empresa SET DEFAULT nextval('public.empresas_id_empresa_seq'::regclass);


--
-- Name: oferece id_oferta; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oferece ALTER COLUMN id_oferta SET DEFAULT nextval('public.oferece_id_oferta_seq'::regclass);


--
-- Name: pedidos codigo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos ALTER COLUMN codigo SET DEFAULT nextval('public.pedidos_codigo_seq'::regclass);


--
-- Name: solicitam id_solicitacao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.solicitam ALTER COLUMN id_solicitacao SET DEFAULT nextval('public.solicitam_id_solicitacao_seq'::regclass);


--
-- Name: telefone_cliente id_telefone; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telefone_cliente ALTER COLUMN id_telefone SET DEFAULT nextval('public.telefone_cliente_id_telefone_seq'::regclass);


--
-- Data for Name: acrescimos_transporte; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.acrescimos_transporte (id_acrescimo, nome_servico, limite_carga, percentual) FROM stdin;
1	Transporte Carga Leve	1000.00	1.00
2	Transporte Carga Leve	5000.00	2.50
3	Transporte Geral	750.00	10.00
4	Transporte por faixas de acréscimo	750.00	10.00
5	Transporte por faixas de acréscimo	1000.00	15.00
\.


--
-- Data for Name: atendimento; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.atendimento (id_solicitacao, cpf_func) FROM stdin;
3	333.333.333-33
6	333.333.333-33
35	444.444.444-44
35	333.333.333-33
41	333.333.333-33
43	333.333.333-33
43	444.444.444-44
44	444.444.444-44
45	28628634
48	444.444.444-44
48	333.333.333-33
49	28628634
50	28628634
50	435.532.656-25
56	28628634
57	333.333.333-33
59	333.333.333-33
\.


--
-- Data for Name: cidades; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cidades (nome_cidade, estado) FROM stdin;
Sao Paulo	SP
Campinas	SP
Rio de Janeiro	RJ
Belo Horizonte	MG
Boa Vista	RR
\.


--
-- Data for Name: clientes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.clientes (cod_cliente, cpf, rg, nome_completo, endereco) FROM stdin;
1	111.111.111-11	MG1111	Cliente A - Construtora Horizonte	Rua Augusta, 500 - Sao Paulo/SP
2	222.222.222-22	MG2222	Cliente B - Portos do Sul Ltda	Rua Moreira Cesar, 40 - Niteroi/RJ
3	123.456.789-13	54.865.245.8	Gabriel Basílio Beckedorff	Major Dantas Cortes
4	657.321.567-13		Marina da Costa Silva	Av. Brasil, 550
\.


--
-- Data for Name: empresas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.empresas (id_empresa, nome, endereco) FROM stdin;
1	TransLog Brasil	Avenida Paulista, 1106 - Sao Paulo/SP - CEP 04538-133
2	GuindasteMax	Avenida Rio Branco, 156 - Rio de Janeiro/RJ - CEP 20040-007
3	Exemplo	Exemplo, 12345
4	Mudanças Gabriel	Rua Major Dantas Cortez, 610
5	TeleportBrasil	Rua das Palmeiras, 120
\.


--
-- Data for Name: funcionarios; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.funcionarios (cpf_func, rg_func, endereco_func, nome_completo_func, telefone_contato, salario, tipo_func) FROM stdin;
333.333.333-33	RGF001	\N	Joao Silva	11-98888-0001	4500.00	Motorista
444.444.444-44	RGF002	\N	Maria Souza	21-98888-0002	5200.00	Operador
28628634	733588648	Major Dantas Cortes	Gabriel Basílio Beckedorff	11995007335	3750.00	Ajudante
435.532.656-25		Rua Alfredo dos Prazeres, 465	Matheus Gustavo	11 94568-4562	4200.00	Operador de Guindaste
\.


--
-- Data for Name: guindastes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.guindastes (nome_servico, tamanho_base, altura, bonus_aum) FROM stdin;
Icamento Torre 30t	30.00	40.00	5.00
guindaste 15t	15.00	50.00	5.00
Guindaste Cargas leves	10.00	15.00	5.00
\.


--
-- Data for Name: oferece; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.oferece (id_oferta, id_empresa, nome_cidade, estado, nome_servico, preco_hora) FROM stdin;
1	1	Sao Paulo	SP	Transporte Carga Leve	100.00
2	1	Campinas	SP	Transporte Carga Leve	90.00
3	2	Rio de Janeiro	RJ	Icamento Torre 30t	300.00
4	2	Rio de Janeiro	RJ	Consultoria Logistica	150.00
5	4	Sao Paulo	SP	Icamento Torre 30t	500.00
6	4	Belo Horizonte	MG	Icamento Torre 30t	350.00
7	1	Boa Vista	RR	guindaste 15t	150.00
8	4	Boa Vista	RR	Transporte Geral	90.00
9	4	Boa Vista	RR	Transporte por faixas de acréscimo	90.00
10	4	Boa Vista	RR	Icamento Torre 30t	250.00
\.


--
-- Data for Name: pedidos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pedidos (codigo, data_solicitacao, data_resolucao, preco_total, aceite, id_empresa, cod_cliente, cidade_dest, estado_dest, endereco_dest, cidade_part, estado_part, endereco_part) FROM stdin;
1	2026-01-05	2026-01-06	1010.00	t	1	1	Sao Paulo	SP	Rua Augusta, 500 - Sao Paulo/SP	Campinas	SP	Avenida Jose de Souza Campos, 100 - Campinas/SP
2	2026-01-10	2026-01-11	461.25	t	1	2	Campinas	SP	Avenida Jose de Souza Campos, 200 - Campinas/SP	Sao Paulo	SP	Avenida Paulista, 900 - Sao Paulo/SP
3	2026-02-01	2026-02-02	2820.00	t	2	1	Rio de Janeiro	RJ	Avenida Atlantica, 300 - Rio de Janeiro/RJ	Rio de Janeiro	RJ	Avenida Rio Branco, 156 - Rio de Janeiro/RJ
4	2026-02-15	2026-07-21	450.00	t	2	2	Rio de Janeiro	RJ	Rua Moreira Cesar, 40 - Niteroi/RJ	Rio de Janeiro	RJ	Avenida Rio Branco, 156 - Rio de Janeiro/RJ
33	2026-07-21	2026-07-21	922.50	t	1	2	Campinas	SP	Av. Bandeirantes, 12	Belo Horizonte	MG	Av. Juviuscreudo Serrado, 4567
5	2026-07-21	2026-07-21	90.90	t	1	2	Campinas	SP	Rua Major Dantas Cortez, 610	Belo Horizonte	MG	EACH-USP
35	2026-07-21	2026-07-21	5250.00	t	4	1	Sao Paulo	SP	Rua Cidade São Paulo, 89	Rio de Janeiro	RJ	Av. Lourenço Mattos, 234
36	2026-07-21	2026-07-21	3150.00	t	2	2	Rio de Janeiro	RJ	Rua Edu Chaves, 34	Belo Horizonte	MG	Rua Chuvas de Meteoro, 4567
27	2026-07-21	2026-07-21	512.50	t	1	2	Sao Paulo	SP	Rua Pampolho da Silva, 34	Sao Paulo	SP	Av. José Ademar dos Campos, 456
37	2026-07-22	2026-07-22	3675.00	t	4	3	Belo Horizonte	MG	Av. Ulisess da Silva, 1278	Rio de Janeiro	RJ	Rua Afonso da Fonseca, 456
40	2026-07-22	2026-07-22	181.80	t	1	3	Campinas	SP	Rua Afonso Biririta, 56	Belo Horizonte	MG	Av. Daniel Cordeiro, 12345
41	2026-07-23	2026-07-23	1260.00	t	4	3	Boa Vista	RR	Rua Nacionais, 19	Sao Paulo	SP	Rua Alvorada da Serra, 345
42	2026-07-23	\N	1449.00	f	4	3	Boa Vista	RR	fgfhrthth	Sao Paulo	SP	dgfghghgh
46	2026-07-24	\N	1807.50	f	4	3	Boa Vista	RR	ghfhfhfgh	Sao Paulo	SP	fhgfhgfhfg
48	2026-07-24	2026-07-24	198.00	t	4	3	Boa Vista	RR	fghfhfhfh	Belo Horizonte	MG	fgthgh
\.


--
-- Data for Name: servicos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.servicos (nome_servico, tipo_servico, especializacao) FROM stdin;
Consultoria Logistica	Servico Geral	\N
Icamento Torre 30t	Icamento	GUINDASTE
Transporte Carga Leve	Transporte	TRANSPORTE
guindaste 15t	içamento	GUINDASTE
Guindaste Cargas leves	içamento	GUINDASTE
Transporte Geral	\N	TRANSPORTE
Transporte por faixas de acréscimo	Transporte	TRANSPORTE
\.


--
-- Data for Name: solicitam; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.solicitam (id_solicitacao, codigo_pedido, nome_servico, tempo_duracao, carga, data_fim, preco) FROM stdin;
1	1	Transporte Carga Leve	10.00	800.00	\N	1010.00
2	2	Transporte Carga Leve	5.00	4000.00	\N	461.25
3	3	Icamento Torre 30t	8.00	\N	\N	2520.00
4	3	Consultoria Logistica	2.00	\N	\N	300.00
5	4	Consultoria Logistica	3.00	\N	\N	450.00
6	5	Transporte Carga Leve	1.00	5.00	\N	90.90
35	27	Transporte Carga Leve	5.00	5000.00	\N	512.50
41	33	Transporte Carga Leve	10.00	5000.00	\N	922.50
43	35	Icamento Torre 30t	10.00	30000.00	\N	5250.00
44	36	Icamento Torre 30t	10.00	10000.00	\N	3150.00
45	37	Icamento Torre 30t	10.00	10000.00	\N	3675.00
48	40	Transporte Carga Leve	2.00	500.00	\N	181.80
49	41	Transporte Geral	14.00	780.00	\N	1260.00
50	42	Transporte por faixas de acréscimo	14.00	780.00	\N	1449.00
56	46	Transporte por faixas de acréscimo	5.00	499.99	\N	495.00
57	46	Icamento Torre 30t	5.00	500.00	\N	1312.50
59	48	Transporte por faixas de acréscimo	2.00	300.00	\N	198.00
\.


--
-- Data for Name: telefone_cliente; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.telefone_cliente (id_telefone, cod_cliente, telefone) FROM stdin;
1	3	11995007335
2	4	11 98678-6543
\.


--
-- Data for Name: telefone_empresa; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.telefone_empresa (id_empresa, telefone) FROM stdin;
3	(11) 99500-7335
4	11995007335
5	(11) 4002-6758
\.


--
-- Data for Name: trabalha_em; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.trabalha_em (id_empresa, cpf_func, data_inicio, data_fim) FROM stdin;
4	28628634	2026-07-21	2030-10-24
4	435.532.656-25	2026-07-22	2026-07-22
2	333.333.333-33	2026-01-01	2026-07-23
1	333.333.333-33	2026-07-23	\N
\.


--
-- Data for Name: transportes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transportes (nome_servico, limite_carga) FROM stdin;
Transporte Carga Leve	5000.00
Transporte Geral	500.00
Transporte por faixas de acréscimo	500.00
\.


--
-- Name: acrescimos_transporte_id_acrescimo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.acrescimos_transporte_id_acrescimo_seq', 5, true);


--
-- Name: clientes_cod_cliente_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.clientes_cod_cliente_seq', 4, true);


--
-- Name: empresas_id_empresa_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.empresas_id_empresa_seq', 5, true);


--
-- Name: oferece_id_oferta_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.oferece_id_oferta_seq', 10, true);


--
-- Name: pedidos_codigo_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pedidos_codigo_seq', 48, true);


--
-- Name: solicitam_id_solicitacao_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.solicitam_id_solicitacao_seq', 59, true);


--
-- Name: telefone_cliente_id_telefone_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.telefone_cliente_id_telefone_seq', 2, true);


--
-- Name: acrescimos_transporte acrescimos_transporte_nome_servico_limite_carga_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acrescimos_transporte
    ADD CONSTRAINT acrescimos_transporte_nome_servico_limite_carga_key UNIQUE (nome_servico, limite_carga);


--
-- Name: acrescimos_transporte acrescimos_transporte_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acrescimos_transporte
    ADD CONSTRAINT acrescimos_transporte_pkey PRIMARY KEY (id_acrescimo);


--
-- Name: atendimento atendimento_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.atendimento
    ADD CONSTRAINT atendimento_pkey PRIMARY KEY (id_solicitacao, cpf_func);


--
-- Name: cidades cidades_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cidades
    ADD CONSTRAINT cidades_pkey PRIMARY KEY (nome_cidade, estado);


--
-- Name: clientes clientes_cpf_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_cpf_key UNIQUE (cpf);


--
-- Name: clientes clientes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_pkey PRIMARY KEY (cod_cliente);


--
-- Name: empresas empresas_nome_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.empresas
    ADD CONSTRAINT empresas_nome_key UNIQUE (nome);


--
-- Name: empresas empresas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.empresas
    ADD CONSTRAINT empresas_pkey PRIMARY KEY (id_empresa);


--
-- Name: funcionarios funcionarios_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.funcionarios
    ADD CONSTRAINT funcionarios_pkey PRIMARY KEY (cpf_func);


--
-- Name: guindastes guindastes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.guindastes
    ADD CONSTRAINT guindastes_pkey PRIMARY KEY (nome_servico);


--
-- Name: oferece oferece_id_empresa_nome_cidade_estado_nome_servico_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oferece
    ADD CONSTRAINT oferece_id_empresa_nome_cidade_estado_nome_servico_key UNIQUE (id_empresa, nome_cidade, estado, nome_servico);


--
-- Name: oferece oferece_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oferece
    ADD CONSTRAINT oferece_pkey PRIMARY KEY (id_oferta);


--
-- Name: pedidos pedidos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_pkey PRIMARY KEY (codigo);


--
-- Name: servicos servicos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.servicos
    ADD CONSTRAINT servicos_pkey PRIMARY KEY (nome_servico);


--
-- Name: solicitam solicitam_codigo_pedido_nome_servico_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.solicitam
    ADD CONSTRAINT solicitam_codigo_pedido_nome_servico_key UNIQUE (codigo_pedido, nome_servico);


--
-- Name: solicitam solicitam_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.solicitam
    ADD CONSTRAINT solicitam_pkey PRIMARY KEY (id_solicitacao);


--
-- Name: telefone_cliente telefone_cliente_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telefone_cliente
    ADD CONSTRAINT telefone_cliente_pkey PRIMARY KEY (id_telefone);


--
-- Name: telefone_empresa telefone_empresa_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telefone_empresa
    ADD CONSTRAINT telefone_empresa_pkey PRIMARY KEY (id_empresa, telefone);


--
-- Name: trabalha_em trabalha_em_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trabalha_em
    ADD CONSTRAINT trabalha_em_pkey PRIMARY KEY (id_empresa, cpf_func, data_inicio);


--
-- Name: transportes transportes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transportes
    ADD CONSTRAINT transportes_pkey PRIMARY KEY (nome_servico);


--
-- Name: idx_acrescimos_transporte_servico; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_acrescimos_transporte_servico ON public.acrescimos_transporte USING btree (nome_servico, limite_carga);


--
-- Name: idx_atendimento_func; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_atendimento_func ON public.atendimento USING btree (cpf_func);


--
-- Name: idx_pedidos_cidadedest; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pedidos_cidadedest ON public.pedidos USING btree (cidade_dest, estado_dest);


--
-- Name: idx_pedidos_cliente; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pedidos_cliente ON public.pedidos USING btree (cod_cliente);


--
-- Name: idx_pedidos_empresa; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pedidos_empresa ON public.pedidos USING btree (id_empresa);


--
-- Name: idx_pedidos_executados; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pedidos_executados ON public.pedidos USING btree (id_empresa) WHERE ((aceite = true) AND (data_resolucao IS NOT NULL));


--
-- Name: idx_solicitam_pedido; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_solicitam_pedido ON public.solicitam USING btree (codigo_pedido);


--
-- Name: idx_telefone_cliente_cliente; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_telefone_cliente_cliente ON public.telefone_cliente USING btree (cod_cliente);


--
-- Name: idx_trabalha_em_func; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_trabalha_em_func ON public.trabalha_em USING btree (cpf_func);


--
-- Name: pedidos trg_bloqueia_total_manual; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_bloqueia_total_manual BEFORE UPDATE OF preco_total ON public.pedidos FOR EACH ROW EXECUTE FUNCTION public.fn_bloqueia_update_manual_total();


--
-- Name: solicitam trg_calcula_preco; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_calcula_preco BEFORE INSERT OR UPDATE OF tempo_duracao, carga, nome_servico ON public.solicitam FOR EACH ROW EXECUTE FUNCTION public.fn_calcula_preco_solicitacao();


--
-- Name: guindastes trg_guindaste_del; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_guindaste_del AFTER DELETE ON public.guindastes FOR EACH ROW EXECUTE FUNCTION public.fn_desmarca_especializacao();


--
-- Name: guindastes trg_guindaste_disjoint; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_guindaste_disjoint BEFORE INSERT ON public.guindastes FOR EACH ROW EXECUTE FUNCTION public.fn_check_disjuncao_guindaste();


--
-- Name: solicitam trg_total_pedido; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_total_pedido AFTER INSERT OR DELETE OR UPDATE OF preco ON public.solicitam FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_total_pedido();


--
-- Name: transportes trg_transporte_del; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_transporte_del AFTER DELETE ON public.transportes FOR EACH ROW EXECUTE FUNCTION public.fn_desmarca_especializacao();


--
-- Name: transportes trg_transporte_disjoint; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_transporte_disjoint BEFORE INSERT ON public.transportes FOR EACH ROW EXECUTE FUNCTION public.fn_check_disjuncao_transporte();


--
-- Name: acrescimos_transporte acrescimos_transporte_nome_servico_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.acrescimos_transporte
    ADD CONSTRAINT acrescimos_transporte_nome_servico_fkey FOREIGN KEY (nome_servico) REFERENCES public.transportes(nome_servico) ON DELETE CASCADE;


--
-- Name: atendimento atendimento_cpf_func_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.atendimento
    ADD CONSTRAINT atendimento_cpf_func_fkey FOREIGN KEY (cpf_func) REFERENCES public.funcionarios(cpf_func);


--
-- Name: atendimento atendimento_id_solicitacao_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.atendimento
    ADD CONSTRAINT atendimento_id_solicitacao_fkey FOREIGN KEY (id_solicitacao) REFERENCES public.solicitam(id_solicitacao) ON DELETE CASCADE;


--
-- Name: guindastes guindastes_nome_servico_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.guindastes
    ADD CONSTRAINT guindastes_nome_servico_fkey FOREIGN KEY (nome_servico) REFERENCES public.servicos(nome_servico) ON DELETE CASCADE;


--
-- Name: oferece oferece_id_empresa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oferece
    ADD CONSTRAINT oferece_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES public.empresas(id_empresa);


--
-- Name: oferece oferece_nome_cidade_estado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oferece
    ADD CONSTRAINT oferece_nome_cidade_estado_fkey FOREIGN KEY (nome_cidade, estado) REFERENCES public.cidades(nome_cidade, estado);


--
-- Name: oferece oferece_nome_servico_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oferece
    ADD CONSTRAINT oferece_nome_servico_fkey FOREIGN KEY (nome_servico) REFERENCES public.servicos(nome_servico);


--
-- Name: pedidos pedidos_cidade_dest_estado_dest_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_cidade_dest_estado_dest_fkey FOREIGN KEY (cidade_dest, estado_dest) REFERENCES public.cidades(nome_cidade, estado);


--
-- Name: pedidos pedidos_cidade_part_estado_part_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_cidade_part_estado_part_fkey FOREIGN KEY (cidade_part, estado_part) REFERENCES public.cidades(nome_cidade, estado);


--
-- Name: pedidos pedidos_cod_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_cod_cliente_fkey FOREIGN KEY (cod_cliente) REFERENCES public.clientes(cod_cliente);


--
-- Name: pedidos pedidos_id_empresa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES public.empresas(id_empresa);


--
-- Name: solicitam solicitam_codigo_pedido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.solicitam
    ADD CONSTRAINT solicitam_codigo_pedido_fkey FOREIGN KEY (codigo_pedido) REFERENCES public.pedidos(codigo) ON DELETE CASCADE;


--
-- Name: solicitam solicitam_nome_servico_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.solicitam
    ADD CONSTRAINT solicitam_nome_servico_fkey FOREIGN KEY (nome_servico) REFERENCES public.servicos(nome_servico);


--
-- Name: telefone_cliente telefone_cliente_cod_cliente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telefone_cliente
    ADD CONSTRAINT telefone_cliente_cod_cliente_fkey FOREIGN KEY (cod_cliente) REFERENCES public.clientes(cod_cliente) ON DELETE CASCADE;


--
-- Name: telefone_empresa telefone_empresa_id_empresa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telefone_empresa
    ADD CONSTRAINT telefone_empresa_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES public.empresas(id_empresa) ON DELETE CASCADE;


--
-- Name: trabalha_em trabalha_em_cpf_func_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trabalha_em
    ADD CONSTRAINT trabalha_em_cpf_func_fkey FOREIGN KEY (cpf_func) REFERENCES public.funcionarios(cpf_func) ON DELETE CASCADE;


--
-- Name: trabalha_em trabalha_em_id_empresa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trabalha_em
    ADD CONSTRAINT trabalha_em_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES public.empresas(id_empresa) ON DELETE CASCADE;


--
-- Name: transportes transportes_nome_servico_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transportes
    ADD CONSTRAINT transportes_nome_servico_fkey FOREIGN KEY (nome_servico) REFERENCES public.servicos(nome_servico) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

