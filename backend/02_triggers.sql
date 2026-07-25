
CREATE OR REPLACE FUNCTION fn_check_disjuncao_guindaste()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM transportes WHERE nome_servico = NEW.nome_servico) THEN
        RAISE EXCEPTION 'Servico % ja e um Transporte. Hierarquia Guindaste/Transporte e disjunta.', NEW.nome_servico;
    END IF;
    UPDATE servicos SET especializacao = 'GUINDASTE' WHERE nome_servico = NEW.nome_servico;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_guindaste_disjoint
BEFORE INSERT ON guindastes
FOR EACH ROW EXECUTE FUNCTION fn_check_disjuncao_guindaste();

CREATE OR REPLACE FUNCTION fn_check_disjuncao_transporte()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM guindastes WHERE nome_servico = NEW.nome_servico) THEN
        RAISE EXCEPTION 'Servico % ja e um Guindaste. Hierarquia Guindaste/Transporte e disjunta.', NEW.nome_servico;
    END IF;
    UPDATE servicos SET especializacao = 'TRANSPORTE' WHERE nome_servico = NEW.nome_servico;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_transporte_disjoint
BEFORE INSERT ON transportes
FOR EACH ROW EXECUTE FUNCTION fn_check_disjuncao_transporte();

CREATE OR REPLACE FUNCTION fn_desmarca_especializacao()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE servicos SET especializacao = NULL WHERE nome_servico = OLD.nome_servico;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_guindaste_del  AFTER DELETE ON guindastes  FOR EACH ROW EXECUTE FUNCTION fn_desmarca_especializacao();
CREATE TRIGGER trg_transporte_del AFTER DELETE ON transportes FOR EACH ROW EXECUTE FUNCTION fn_desmarca_especializacao();


CREATE OR REPLACE FUNCTION fn_calcula_preco_solicitacao()
RETURNS TRIGGER AS $$
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

    SELECT bonus_aum INTO v_percentual FROM guindastes WHERE nome_servico = NEW.nome_servico;

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
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_calcula_preco
BEFORE INSERT OR UPDATE OF tempo_duracao, carga, nome_servico ON solicitam
FOR EACH ROW EXECUTE FUNCTION fn_calcula_preco_solicitacao();



CREATE OR REPLACE FUNCTION fn_atualiza_total_pedido()
RETURNS TRIGGER AS $$
DECLARE
    v_codigo INTEGER;
BEGIN
    v_codigo := COALESCE(NEW.codigo_pedido, OLD.codigo_pedido);
    UPDATE pedidos
       SET preco_total = (SELECT COALESCE(SUM(preco), 0) FROM solicitam WHERE codigo_pedido = v_codigo)
     WHERE codigo = v_codigo;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_total_pedido
AFTER INSERT OR UPDATE OF preco OR DELETE ON solicitam
FOR EACH ROW EXECUTE FUNCTION fn_atualiza_total_pedido();

CREATE OR REPLACE FUNCTION fn_bloqueia_update_manual_total()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.preco_total <> OLD.preco_total AND
       NOT EXISTS (SELECT 1 FROM solicitam WHERE codigo_pedido = NEW.codigo AND
                   NEW.preco_total = (SELECT COALESCE(SUM(preco),0) FROM solicitam WHERE codigo_pedido = NEW.codigo)) THEN
        RAISE EXCEPTION 'preco_total nao pode ser alterado manualmente; ele e derivado de solicitam.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_bloqueia_total_manual
BEFORE UPDATE OF preco_total ON pedidos
FOR EACH ROW EXECUTE FUNCTION fn_bloqueia_update_manual_total();


CREATE OR REPLACE FUNCTION fn_valida_cidades_pedido()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM oferece
        WHERE id_empresa = NEW.id_empresa
          AND nome_cidade = NEW.cidade_dest AND estado = NEW.estado_dest
    ) THEN
        RAISE EXCEPTION 'A empresa % nao presta servicos em %/% (cidade de destino).',
            NEW.id_empresa, NEW.cidade_dest, NEW.estado_dest;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM oferece
        WHERE id_empresa = NEW.id_empresa
          AND nome_cidade = NEW.cidade_part AND estado = NEW.estado_part
    ) THEN
        RAISE EXCEPTION 'A empresa % nao presta servicos em %/% (cidade de partida).',
            NEW.id_empresa, NEW.cidade_part, NEW.estado_part;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_valida_cidades_pedido
BEFORE INSERT OR UPDATE OF id_empresa, cidade_dest, estado_dest, cidade_part, estado_part ON pedidos
FOR EACH ROW EXECUTE FUNCTION fn_valida_cidades_pedido();
