from database.base import BaseDatabase


class EmpresasDatabase(BaseDatabase):
    def get_empresas(self):
        return self.db.execute_select_all("""
            SELECT e.id_empresa, e.nome, e.endereco,
                   COALESCE(array_agg(t.telefone) FILTER (WHERE t.telefone IS NOT NULL), '{}') AS telefones
            FROM empresas e
            LEFT JOIN telefone_empresa t ON t.id_empresa = e.id_empresa
            GROUP BY e.id_empresa
            ORDER BY e.id_empresa DESC
        """)

    def criar_empresa(self, nome: str, endereco: str, telefones: list[str] | None = None) -> dict:
        empresa = self.db.execute_insert_returning(
            "INSERT INTO empresas (nome, endereco) VALUES (%s, %s) RETURNING id_empresa",
            (nome, endereco),
        )
        id_empresa = empresa["id_empresa"]

        for telefone in telefones or []:
            self.db.execute_statement(
                "INSERT INTO telefone_empresa (id_empresa, telefone) VALUES (%s, %s)",
                (id_empresa, telefone),
            )

        return {"id_empresa": id_empresa}