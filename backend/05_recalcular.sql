-- =====================================================================
-- RECALCULO MANUAL (use apenas se voce populou 'solicitam' ANTES de criar
-- os triggers de 02_triggers.sql, e por isso 'preco' e 'preco_total'
-- ficaram parados no valor DEFAULT 0)
--
-- Pre-requisito: rode 02_triggers.sql primeiro (se ainda nao rodou).
-- Depois rode este script uma unica vez.
-- =====================================================================

-- 1) Recalcula o preco de cada solicitacao de servico (dispara o trigger
--    trg_calcula_preco, que e BEFORE UPDATE OF tempo_duracao/carga/nome_servico
--    -- por isso fazemos um "UPDATE que nao muda nada" so pra forcar o
--    trigger a rodar de novo em cada linha)
UPDATE solicitam SET tempo_duracao = tempo_duracao;

-- 2) Recalcula o preco_total de cada pedido a partir da soma ja corrigida
--    acima (redundante se o trigger trg_total_pedido ja rodou no passo 1,
--    mas serve de garantia/checagem)
UPDATE pedidos p
   SET preco_total = (SELECT COALESCE(SUM(s.preco), 0) FROM solicitam s WHERE s.codigo_pedido = p.codigo);

-- 3) Conferencia: nenhuma linha deve aparecer aqui
SELECT p.codigo, p.preco_total, COALESCE(SUM(s.preco), 0) AS soma_calculada
FROM pedidos p
LEFT JOIN solicitam s ON s.codigo_pedido = p.codigo
GROUP BY p.codigo, p.preco_total
HAVING ABS(p.preco_total - COALESCE(SUM(s.preco), 0)) > 0.01;
