from database.base import BaseDatabase


class ServicosDatabase(BaseDatabase):
    def get_servicos(self):
        return self.db.execute_select_all(
            "SELECT nome_servico, tipo_servico, especializacao FROM servicos ORDER BY nome_servico"
        )

    def criar_servico(self, nome_servico: str, tipo_servico: str | None, especializacao: str | None,
                       tamanho_base: float | None = None, altura: float | None = None,
                       bonus_aum: float = 0, limite_carga: float | None = None,
                       faixas: list[dict] | None = None) -> dict:
        self.db.execute_statement(
            "INSERT INTO servicos (nome_servico, tipo_servico) VALUES (%s, %s)",
            (nome_servico, tipo_servico),
        )

        if especializacao == "GUINDASTE":
            self.db.execute_statement(
                "INSERT INTO guindastes (nome_servico, tamanho_base, altura, bonus_aum) "
                "VALUES (%s, %s, %s, %s)",
                (nome_servico, tamanho_base, altura, bonus_aum or 0),
            )
        elif especializacao == "TRANSPORTE":
            self.db.execute_statement(
                "INSERT INTO transportes (nome_servico, limite_carga) VALUES (%s, %s)",
                (nome_servico, limite_carga),
            )
            for faixa in faixas or []:
                self.db.execute_statement(
                    "INSERT INTO acrescimos_transporte (nome_servico, limite_carga, percentual) "
                    "VALUES (%s, %s, %s)",
                    (nome_servico, faixa["limite_carga"], faixa["percentual"]),
                )

        return {"nome_servico": nome_servico}

    # ---------------- oferece: empresa x cidade x servico -> preco/hora ----------------
    def criar_oferta(self, id_empresa: int, nome_cidade: str, estado: str,
                      nome_servico: str, preco_hora: float) -> dict:
        self.db.execute_statement(
            "INSERT INTO oferece (id_empresa, nome_cidade, estado, nome_servico, preco_hora) "
            "VALUES (%s, %s, %s, %s, %s)",
            (id_empresa, nome_cidade, estado.upper(), nome_servico, preco_hora),
        )
        return {"ok": True}

    def get_ofertas(self, id_empresa: int | None = None, nome_cidade: str | None = None,
                     estado: str | None = None):
        query = """
            SELECT o.id_oferta, o.id_empresa, e.nome AS nome_empresa, o.nome_cidade, o.estado,
                   o.nome_servico, o.preco_hora
            FROM oferece o JOIN empresas e ON e.id_empresa = o.id_empresa
            WHERE 1=1
        """
        params: list = []
        if id_empresa is not None:
            query += " AND o.id_empresa = %s"
            params.append(id_empresa)
        if nome_cidade is not None:
            query += " AND o.nome_cidade = %s"
            params.append(nome_cidade)
        if estado is not None:
            query += " AND o.estado = %s"
            params.append(estado.upper())
        query += " ORDER BY o.id_oferta DESC"

        return self.db.execute_select_all(query, tuple(params))