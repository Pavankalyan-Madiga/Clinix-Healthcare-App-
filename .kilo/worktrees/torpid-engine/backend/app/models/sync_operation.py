from datetime import datetime

from sqlmodel import Field, SQLModel


class SyncOperation(SQLModel, table=True):
    id: int | None = Field(
        default=None,
        primary_key=True,
    )

    operation_id: str = Field(
        unique=True,
        index=True,
    )

    entity_type: str

    entity_id: str

    operation_type: str

    payload: str

    base_version: int | None = None

    server_version: int = 1

    status: str = "COMPLETED"

    created_at: datetime = Field(
        default_factory=datetime.utcnow,
    )

    processed_at: datetime | None = None