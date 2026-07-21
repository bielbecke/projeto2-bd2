from database.base import BaseDatabase


class PedidoInvalido(Exception):
    "levantada quando um trigger do banco recusa a operacao (regra de negocio violada)"


class PedidosDatabase(BaseDatabase):
    def get_pedidos(self):
        return self.db.execute_select_all("""
            SELECT p.codigo, p.data_solicitacao, p.data_resolucao, p.preco_total, p.aceite,
                   e.nome AS empresa, c.nome_completo AS cliente,
                   p.cidade_dest, p.estado_dest, p.cidade_part, p.estado_part,
                   COALESCE(json_agg(json_build_object(
                       'id_solicitacao', s.id_solicitacao, 'nome_servico', s.nome_servico,
                       'tempo_duracao', s.tempo_duracao, 'carga', s.carga, 'preco', s.preco,
                       'funcionarios', (
                           SELECT COALESCE(array_agg(fn.nome_completo_func), '{}')
                           FROM atendimento a JOIN funcionarios fn ON fn.cpf_func = a.cpf_func
                           WHERE a.id_solicitacao = s.id_solicitacao
                       )
                   )) FILTER (WHERE s.id_solicitacao IS NOT NULL), '[]') AS itens
            FROM pedidos p
            JOIN empresas e ON e.id_empresa = p.id_empresa
            JOIN clientes c ON c.cod_cliente = p.cod_cliente
            LEFT JOIN solicitam s ON s.codigo_pedido = p.codigo
            GROUP BY p.codigo, e.nome, c.nome_completo
            ORDER BY p.codigo DESC
        """)

    def criar_pedido(self, id_empresa: int, cod_cliente: int,
                      cidade_dest: str, estado_dest: str, endereco_dest: str | None,
                      cidade_part: str, estado_part: str, endereco_part: str | None,
                      aceite: bool, itens: list[dict]) -> dict:
        "cria o pedido + cada servico solicitado + a equipe de cada servico, tudo numa sequencia; qualquer erro de trigger vira PedidoInvalido com mensagem clara"
        if not itens:
            raise PedidoInvalido("O pedido precisa de pelo menos um servico solicitado")

        try:
            pedido = self.db.execute_insert_returning(
                """INSERT INTO pedidos (data_solicitacao, aceite, id_empresa, cod_cliente,
                    cidade_dest, estado_dest, endereco_dest, cidade_part, estado_part, endereco_part)
                   VALUES (CURRENT_DATE, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                   RETURNING codigo""",
                (aceite, id_empresa, cod_cliente, cidade_dest, estado_dest.upper(),
                 endereco_dest, cidade_part, estado_part.upper(), endereco_part),
            )
        except Exception as erro:
            # pega o trigger (d): cidade de destino/partida fora da area de atuacao da empresa
            raise PedidoInvalido(_mensagem_amigavel(erro)) from erro

        codigo = pedido["codigo"]

        for item in itens:
            try:
                solicitacao = self.db.execute_insert_returning(
                    "INSERT INTO solicitam (codigo_pedido, nome_servico, tempo_duracao, carga) "
                    "VALUES (%s, %s, %s, %s) RETURNING id_solicitacao",
                    (codigo, item["nome_servico"], item["tempo_duracao"], item.get("carga")),
                )
            except Exception as erro:
                # pega o trigger (c): empresa nao oferece esse servico na cidade de destino
                raise PedidoInvalido(
                    f"Nao foi possivel adicionar '{item['nome_servico']}': "
                    f"a empresa nao oferece esse servico na cidade de destino."
                ) from erro

            id_solicitacao = solicitacao["id_solicitacao"]

            for cpf_func in item.get("funcionarios") or []:
                try:
                    self.db.execute_statement(
                        "INSERT INTO atendimento (id_solicitacao, cpf_func) VALUES (%s, %s)",
                        (id_solicitacao, cpf_func),
                    )
                except Exception as erro:
                    raise PedidoInvalido(
                        f"Nao foi possivel atribuir o funcionario ao servico '{item['nome_servico']}'."
                    ) from erro

        pedido_final = self.db.execute_select_one(
            "SELECT preco_total FROM pedidos WHERE codigo = %s", (codigo,)
        )
        return {"codigo": codigo, "preco_total": pedido_final["preco_total"]}

    def resolver_pedido(self, codigo: int) -> bool:
        "marca um pedido como aceito e concluido hoje (servico 'executado')"
        resultado = self.db.execute_insert_returning(
            "UPDATE pedidos SET aceite = TRUE, data_resolucao = CURRENT_DATE "
            "WHERE codigo = %s RETURNING codigo",
            (codigo,),
        )
        return resultado is not None

    def atribuir_funcionario(self, id_solicitacao: int, cpf_func: str) -> dict:
        try:
            self.db.execute_statement(
                "INSERT INTO atendimento (id_solicitacao, cpf_func) VALUES (%s, %s)",
                (id_solicitacao, cpf_func),
            )
        except Exception as erro:
            raise PedidoInvalido(_mensagem_amigavel(erro)) from erro
        return {"ok": True}


def _mensagem_amigavel(erro: Exception) -> str:
    "pega so a primeira linha da mensagem de erro do Postgres (a mensagem do RAISE EXCEPTION do trigger), sem o traceback tecnico do driver"
    return str(erro).split("\n")[0]