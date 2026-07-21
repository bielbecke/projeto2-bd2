from database.base import BaseDatabase


class ClientesDatabase(BaseDatabase):
    def get_clientes(self):
        return self.db.execute_select_all("""
            SELECT c.cod_cliente, c.cpf, c.rg, c.nome_completo, c.endereco,
                   COALESCE(array_agg(t.telefone) FILTER (WHERE t.telefone IS NOT NULL), '{}') AS telefones
            FROM clientes c
            LEFT JOIN telefone_cliente t ON t.cod_cliente = c.cod_cliente
            GROUP BY c.cod_cliente
            ORDER BY c.cod_cliente DESC
        """)

    def criar_cliente(self, cpf: str, rg: str | None, nome_completo: str,
                       endereco: str | None, telefone: str | None) -> dict:
        cliente = self.db.execute_insert_returning(
            "INSERT INTO clientes (cpf, rg, nome_completo, endereco) VALUES (%s, %s, %s, %s) "
            "RETURNING cod_cliente",
            (cpf, rg, nome_completo, endereco),
        )
        cod_cliente = cliente["cod_cliente"]

        if telefone:
            self.db.execute_statement(
                "INSERT INTO telefone_cliente (cod_cliente, telefone) VALUES (%s, %s)",
                (cod_cliente, telefone),
            )

        return {"cod_cliente": cod_cliente}