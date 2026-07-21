"Camada que gerencia o db"
from typing import Any
from psycopg2 import pool
from psycopg2.extras import DictCursor

# pool de conexões compartilhado por toda a aplicação: cada requisição pega
# uma conexão emprestada e devolve no final, em vez de abrir uma conexão
# TCP nova a cada clique no frontend (e em vez de todo mundo brigar pelo
# mesmo cursor, que era a causa do KeyError anterior)
_pool = pool.ThreadedConnectionPool(
    minconn=1,
    maxconn=10,
    dbname="projeto2",
    user="postgres",
    password="postgres",
    host="127.0.0.1",
    port=5432,
)


class DatabaseManager:
    "classe de gerenciamento do db"

    def __init__(self) -> None:
        self.conn = _pool.getconn()
        self.cursor = self.conn.cursor(cursor_factory=DictCursor)

    def __del__(self) -> None:
        # devolve a conexão pro pool quando este DatabaseManager for
        # descartado (fim da requisição), em vez de fechar de vez
        try:
            _pool.putconn(self.conn)
        except Exception:
            pass

    def execute_statement(self, statement: str, params: tuple = ()) -> None:
        "usado para inserções, deleções, alter tables"
        try:
            self.cursor.execute(statement, params)
            self.conn.commit()
        except Exception:
            # sem isso, uma unica query com erro (ex: um trigger recusando
            # a insercao) deixa a conexao "presa" numa transacao abortada,
            # e TODAS as proximas requisicoes passam a falhar ate reiniciar
            # o servidor -- o rollback devolve a conexao pra um estado usavel
            self.conn.rollback()
            raise

    def execute_insert_returning(self, statement: str, params: tuple = ()) -> dict[str, Any] | None:
        "usado para INSERT/UPDATE ... RETURNING (pega a linha afetada sem outro SELECT)"
        try:
            self.cursor.execute(statement, params)
            self.conn.commit()
            resultado = self.cursor.fetchone()
            return dict(resultado) if resultado else None
        except Exception:
            self.conn.rollback()
            raise

    def execute_select_all(self, query: str, params: tuple = ()) -> list[dict[str, Any]]:
        "usado para selects no geral"
        try:
            self.cursor.execute(query, params)
            return [dict(item) for item in self.cursor.fetchall()]
        except Exception:
            self.conn.rollback()
            raise

    def execute_select_one(self, query: str, params: tuple = ()) -> dict | None:
        "usado para select com apenas uma linha de resposta"
        try:
            self.cursor.execute(query, params)
            query_result = self.cursor.fetchone()
        except Exception:
            self.conn.rollback()
            raise

        if not query_result:
            return None

        return dict(query_result)