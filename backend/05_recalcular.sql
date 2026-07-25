
UPDATE solicitam SET tempo_duracao = tempo_duracao;

UPDATE pedidos p
   SET preco_total = (SELECT COALESCE(SUM(s.preco), 0) FROM solicitam s WHERE s.codigo_pedido = p.codigo);

SELECT p.codigo, p.preco_total, COALESCE(SUM(s.preco), 0) AS soma_calculada
FROM pedidos p
LEFT JOIN solicitam s ON s.codigo_pedido = p.codigo
GROUP BY p.codigo, p.preco_total
HAVING ABS(p.preco_total - COALESCE(SUM(s.preco), 0)) > 0.01;
