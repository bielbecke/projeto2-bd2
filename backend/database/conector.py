"Camada que gerencia o db"
from typing import Any
import psycopg2
from psycopg2.extras import DictCursor


class DatabaseManager:
    "classe de gerenciamento do db"

    def __init__(self) -> None:
        self.conn = psycopg2.connect(
            dbname="projeto2",
            user="postgres",
            password="postgres",
            host="127.0.0.1",
            port=5432,
        )
        self.cursor = self.conn.cursor(cursor_factory=DictCursor)

    def execute_statement(self, statement: str, params: tuple = ()) -> None:
        "usado para inserções, deleções, alter tables"
        try:
            self.cursor.execute(statement, params)
            self.conn.commit()
        except Exception:
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

    def executar_na_transacao(self, statement: str, params: tuple = ()) -> None:
        "como execute_statement, mas sem commitar"
        self.cursor.execute(statement, params)

    def executar_returning_na_transacao(self, statement: str, params: tuple = ()) -> dict[str, Any] | None:
        "como execute_insert_returning, mas sem commitar"
        self.cursor.execute(statement, params)
        resultado = self.cursor.fetchone()
        return dict(resultado) if resultado else None

    def commit(self) -> None:
        self.conn.commit()

    def rollback(self) -> None:
        self.conn.rollback()

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