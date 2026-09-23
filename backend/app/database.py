from sqlmodel import SQLModel, create_engine

from app.models.entity_version import EntityVersion
from app.models.sync_operation import SyncOperation


DATABASE_URL = "sqlite:///clinix.db"

engine = create_engine(
    DATABASE_URL,
    echo=False,
    connect_args={
        "check_same_thread": False,
    },
)


def create_db_and_tables():
    SQLModel.metadata.create_all(engine)