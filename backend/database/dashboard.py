from database.base import BaseDatabase


class DashboardDatabase(BaseDatabase):
    def resumo(self) -> dict:
        n_pedidos = self.db.execute_select_one("SELECT COUNT(*) AS n FROM pedidos")["n"]
        faturado = self.db.execute_select_one(
            "SELECT COALESCE(SUM(preco_total),0) AS v FROM pedidos "
            "WHERE aceite = TRUE AND data_resolucao IS NOT NULL"
        )["v"]
        pendentes = self.db.execute_select_one(
            "SELECT COUNT(*) AS n FROM pedidos WHERE data_resolucao IS NULL"
        )["n"]
        n_servicos = self.db.execute_select_one("SELECT COUNT(*) AS n FROM servicos")["n"]
        return {
            "pedidos": n_pedidos,
            "faturado": faturado,
            "pendentes": pendentes,
            "servicos_cadastrados": n_servicos,
        }

    def qtd_por_cidade(self):
        return self.db.execute_select_all("""
            SELECT p.cidade_dest || '/' || p.estado_dest AS cidade, COUNT(*) AS qtd
            FROM solicitam s JOIN pedidos p ON p.codigo = s.codigo_pedido
            GROUP BY p.cidade_dest, p.estado_dest
            ORDER BY qtd DESC
        """)

    def valor_por_cidade(self):
        return self.db.execute_select_all("""
            SELECT cidade_dest || '/' || estado_dest AS cidade, SUM(preco_total) AS valor
            FROM pedidos
            GROUP BY cidade_dest, estado_dest
            ORDER BY valor DESC
        """)

    def top_cidades_valor(self):
        return self.db.execute_select_all("""
            SELECT cidade_dest || '/' || estado_dest AS cidade, SUM(preco_total) AS valor
            FROM pedidos
            GROUP BY cidade_dest, estado_dest
            ORDER BY valor DESC LIMIT 5
        """)

    def top_cidades_qtd(self):
        return self.db.execute_select_all("""
            SELECT p.cidade_dest || '/' || p.estado_dest AS cidade, COUNT(*) AS qtd
            FROM solicitam s JOIN pedidos p ON p.codigo = s.codigo_pedido
            GROUP BY p.cidade_dest, p.estado_dest
            ORDER BY qtd DESC LIMIT 5
        """)

    def top_empresas_qtd(self):
        return self.db.execute_select_all("""
            SELECT e.nome, COUNT(*) AS qtd
            FROM solicitam s
            JOIN pedidos p ON p.codigo = s.codigo_pedido
            JOIN empresas e ON e.id_empresa = p.id_empresa
            GROUP BY e.id_empresa
            ORDER BY qtd DESC LIMIT 5
        """)

    def top_empresas_valor(self):
        return self.db.execute_select_all("""
            SELECT e.nome, SUM(p.preco_total) AS valor
            FROM pedidos p
            JOIN empresas e ON e.id_empresa = p.id_empresa
            WHERE p.aceite = TRUE AND p.data_resolucao IS NOT NULL
            GROUP BY e.id_empresa, e.nome
            ORDER BY valor DESC LIMIT 5
        """)