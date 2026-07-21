from database.base import BaseDatabase


class CidadesDatabase(BaseDatabase):
    def get_cidades(self):
        return self.db.execute_select_all(
            "SELECT nome_cidade, estado FROM cidades ORDER BY estado, nome_cidade"
        )

    def criar_cidade(self, nome_cidade: str, estado: str) -> dict:
        self.db.execute_statement(
            """INSERT INTO cidades (nome_cidade, estado) VALUES (%s, %s)
               ON CONFLICT (nome_cidade, estado) DO NOTHING""",
            (nome_cidade, estado.upper()),
        )
        return {"nome_cidade": nome_cidade, "estado": estado.upper()}