from database.base import BaseDatabase


class FuncionariosDatabase(BaseDatabase):
    def get_funcionarios(self, id_empresa: int | None = None):
        "se id_empresa for passado, so retorna quem tem vinculo ATIVO nela"
        if id_empresa is not None:
            return self.db.execute_select_all(
                """SELECT f.* FROM funcionarios f
                   JOIN trabalha_em t ON t.cpf_func = f.cpf_func
                   WHERE t.id_empresa = %s AND t.data_fim IS NULL
                   ORDER BY f.nome_completo_func""",
                (id_empresa,),
            )
        return self.db.execute_select_all(
            "SELECT * FROM funcionarios ORDER BY nome_completo_func"
        )

    def criar_funcionario(self, cpf_func: str, rg_func: str | None, endereco_func: str | None,
                           nome_completo_func: str, telefone_contato: str | None,
                           salario: float | None, tipo_func: str | None) -> dict:
        self.db.execute_statement(
            """INSERT INTO funcionarios (cpf_func, rg_func, endereco_func, nome_completo_func,
                telefone_contato, salario, tipo_func) VALUES (%s, %s, %s, %s, %s, %s, %s)""",
            (cpf_func, rg_func, endereco_func, nome_completo_func, telefone_contato, salario, tipo_func),
        )
        return {"cpf_func": cpf_func}

    # ---------------- trabalha_em: funcionario x empresa (N:N com periodo) ----------------
    def get_vinculos(self):
        return self.db.execute_select_all("""
            SELECT t.id_empresa, e.nome AS nome_empresa, t.cpf_func, f.nome_completo_func,
                   t.data_inicio, t.data_fim
            FROM trabalha_em t
            JOIN empresas e ON e.id_empresa = t.id_empresa
            JOIN funcionarios f ON f.cpf_func = t.cpf_func
            ORDER BY t.data_inicio DESC
        """)

    def criar_vinculo(self, id_empresa: int, cpf_func: str, data_inicio: str,
                       data_fim: str | None = None) -> dict:
        self.db.execute_statement(
            "INSERT INTO trabalha_em (id_empresa, cpf_func, data_inicio, data_fim) VALUES (%s, %s, %s, %s)",
            (id_empresa, cpf_func, data_inicio, data_fim),
        )
        return {"ok": True}

    def encerrar_vinculo(self, id_empresa: int, cpf_func: str) -> dict | None:
        return self.db.execute_insert_returning(
            """UPDATE trabalha_em SET data_fim = CURRENT_DATE
               WHERE id_empresa = %s AND cpf_func = %s AND data_fim IS NULL
               RETURNING data_inicio""",
            (id_empresa, cpf_func),
        )