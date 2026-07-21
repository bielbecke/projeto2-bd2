"Classe base compartilhada por todas as *Database (Cidades, Clientes, Empresas...)"
from database.conector import DatabaseManager


class BaseDatabase:
    def __init__(self, db_provider: DatabaseManager | None = None) -> None:
        self.db = db_provider or DatabaseManager()