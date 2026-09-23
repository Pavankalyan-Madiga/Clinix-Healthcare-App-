from datetime import datetime

from sqlmodel import Field, SQLModel


class EntityVersion(SQLModel, table=True):
    id: int | None = Field(
        default=None,
        primary_key=True,
    )

    entity_type: str

    entity_id: str

    version: int = 1

    updated_at: datetime = Field(
        default_factory=datetime.utcnow,
    )

    __table_args__ = (
        {
            "sqlite_autoincrement": True,
        },
    )