from datetime import datetime
import json
from pathlib import Path
from typing import Any
from uuid import uuid4

from fastapi import (
    APIRouter,
    Depends,
    File,
    HTTPException,
    UploadFile,
)
from pydantic import BaseModel
from sqlmodel import Session, select

from app.database import engine
from app.models.entity_version import EntityVersion
from app.models.sync_operation import SyncOperation
from app.websocket_manager import manager


router = APIRouter(
    prefix="/sync",
    tags=["Sync"],
)


def get_session():
    with Session(engine) as session:
        yield session


class SyncRequest(BaseModel):
    operation_id: str
    entity_type: str
    entity_id: str
    operation_type: str
    payload: dict[str, Any]
    base_version: int | None = None


class ConflictResolutionRequest(BaseModel):
    operation_id: str
    entity_type: str
    entity_id: str
    payload: dict[str, Any]
    base_version: int
    resolution: str


class SyncResponse(BaseModel):
    operation_id: str
    status: str
    server_version: int
    synced_at: datetime


SUPPORTED_ENTITY_TYPES = {
    "PATIENT",
    "TASK",
    "VITAL",
    "MESSAGE",
    "WOUND_PHOTO",
}


@router.post("/wound-photos/upload")
async def upload_wound_photo(
    file: UploadFile = File(...),
):
    upload_directory = Path(
        "uploads/wound_photos"
    )

    upload_directory.mkdir(
        parents=True,
        exist_ok=True,
    )

    original_name = (
        file.filename or "wound_photo.jpg"
    )

    extension = Path(
        original_name
    ).suffix.lower()

    if not extension:
        extension = ".jpg"

    allowed_extensions = {
        ".jpg",
        ".jpeg",
        ".png",
        ".webp",
    }

    if extension not in allowed_extensions:
        raise HTTPException(
            status_code=400,
            detail="Unsupported image format",
        )

    filename = (
        f"{uuid4().hex}{extension}"
    )

    destination = (
        upload_directory / filename
    )

    contents = await file.read()

    if not contents:
        raise HTTPException(
            status_code=400,
            detail="Empty image file",
        )

    if len(contents) > 10 * 1024 * 1024:
        raise HTTPException(
            status_code=413,
            detail="Image size exceeds 10 MB",
        )

    destination.write_bytes(contents)

    return {
        "file_path": str(destination),
        "filename": filename,
    }


@router.post(
    "/operations",
    response_model=SyncResponse,
)
async def sync_operation(
    operation: SyncRequest,
    session: Session = Depends(get_session),
):
    if operation.entity_type not in SUPPORTED_ENTITY_TYPES:
        raise HTTPException(
            status_code=400,
            detail=(
                f"Unsupported entity type: "
                f"{operation.entity_type}"
            ),
        )

    existing = session.exec(
        select(SyncOperation).where(
            SyncOperation.operation_id
            == operation.operation_id
        )
    ).first()

    if existing:
        return SyncResponse(
            operation_id=existing.operation_id,
            status=existing.status,
            server_version=existing.server_version,
            synced_at=(
                existing.processed_at
                or existing.created_at
            ),
        )

    entity = session.exec(
        select(EntityVersion).where(
            EntityVersion.entity_type
            == operation.entity_type,
            EntityVersion.entity_id
            == operation.entity_id,
        )
    ).first()

    if entity is None:
        entity = EntityVersion(
            entity_type=operation.entity_type,
            entity_id=operation.entity_id,
            version=1,
        )

        session.add(entity)
        session.commit()
        session.refresh(entity)

    if operation.base_version is not None:
        if operation.base_version != entity.version:
            latest_operation = session.exec(
                select(SyncOperation)
                .where(
                    SyncOperation.entity_type
                    == operation.entity_type,
                    SyncOperation.entity_id
                    == operation.entity_id,
                    SyncOperation.status
                    == "COMPLETED",
                )
                .order_by(
                    SyncOperation.server_version.desc()
                )
            ).first()

            server_payload = None

            if latest_operation is not None:
                server_payload = json.loads(
                    latest_operation.payload
                )

            raise HTTPException(
                status_code=409,
                detail={
                    "type": "CONFLICT",
                    "operation_id": (
                        operation.operation_id
                    ),
                    "entity_type": (
                        operation.entity_type
                    ),
                    "entity_id": (
                        operation.entity_id
                    ),
                    "client_version": (
                        operation.base_version
                    ),
                    "server_version": (
                        entity.version
                    ),
                    "server_payload": server_payload,
                },
            )

    entity.version += 1
    entity.updated_at = datetime.utcnow()

    record = SyncOperation(
        operation_id=operation.operation_id,
        entity_type=operation.entity_type,
        entity_id=operation.entity_id,
        operation_type=operation.operation_type,
        payload=json.dumps(
            operation.payload
        ),
        base_version=operation.base_version,
        server_version=entity.version,
        status="COMPLETED",
        processed_at=datetime.utcnow(),
    )

    session.add(record)
    session.commit()
    session.refresh(record)

    await manager.broadcast(
        {
            "type": "SYNC_UPDATE",
            "operation_id": (
                record.operation_id
            ),
            "entity_type": (
                record.entity_type
            ),
            "entity_id": (
                record.entity_id
            ),
            "operation_type": (
                record.operation_type
            ),
            "payload": operation.payload,
            "server_version": (
                record.server_version
            ),
        }
    )

    return SyncResponse(
        operation_id=record.operation_id,
        status=record.status,
        server_version=record.server_version,
        synced_at=record.processed_at,
    )


@router.post(
    "/resolve",
    response_model=SyncResponse,
)
async def resolve_conflict(
    request: ConflictResolutionRequest,
    session: Session = Depends(get_session),
):
    if request.resolution not in {
        "KEEP_LOCAL",
        "KEEP_SERVER",
    }:
        raise HTTPException(
            status_code=400,
            detail="Invalid conflict resolution",
        )

    if request.entity_type not in SUPPORTED_ENTITY_TYPES:
        raise HTTPException(
            status_code=400,
            detail=(
                f"Unsupported entity type: "
                f"{request.entity_type}"
            ),
        )

    entity = session.exec(
        select(EntityVersion).where(
            EntityVersion.entity_type
            == request.entity_type,
            EntityVersion.entity_id
            == request.entity_id,
        )
    ).first()

    if entity is None:
        raise HTTPException(
            status_code=404,
            detail="Entity not found",
        )

    existing = session.exec(
        select(SyncOperation).where(
            SyncOperation.operation_id
            == request.operation_id
        )
    ).first()

    if existing is not None:
        return SyncResponse(
            operation_id=existing.operation_id,
            status=existing.status,
            server_version=existing.server_version,
            synced_at=(
                existing.processed_at
                or existing.created_at
            ),
        )

    if request.base_version > entity.version:
        raise HTTPException(
            status_code=409,
            detail={
                "type": "INVALID_VERSION",
                "operation_id": (
                    request.operation_id
                ),
                "entity_type": (
                    request.entity_type
                ),
                "entity_id": (
                    request.entity_id
                ),
                "client_version": (
                    request.base_version
                ),
                "server_version": (
                    entity.version
                ),
            },
        )

    entity.version += 1
    entity.updated_at = datetime.utcnow()

    record = SyncOperation(
        operation_id=request.operation_id,
        entity_type=request.entity_type,
        entity_id=request.entity_id,
        operation_type="CONFLICT_RESOLUTION",
        payload=json.dumps(
            request.payload
        ),
        base_version=entity.version - 1,
        server_version=entity.version,
        status="COMPLETED",
        processed_at=datetime.utcnow(),
    )

    session.add(record)
    session.commit()
    session.refresh(record)

    await manager.broadcast(
        {
            "type": "SYNC_UPDATE",
            "operation_id": (
                record.operation_id
            ),
            "entity_type": (
                record.entity_type
            ),
            "entity_id": (
                record.entity_id
            ),
            "operation_type": (
                record.operation_type
            ),
            "payload": request.payload,
            "server_version": (
                record.server_version
            ),
        }
    )

    return SyncResponse(
        operation_id=record.operation_id,
        status=record.status,
        server_version=record.server_version,
        synced_at=record.processed_at,
    )


@router.get(
    "/entities/{entity_type}/{entity_id}",
)
def get_server_entity(
    entity_type: str,
    entity_id: str,
    session: Session = Depends(get_session),
):
    if entity_type not in SUPPORTED_ENTITY_TYPES:
        raise HTTPException(
            status_code=400,
            detail=(
                f"Unsupported entity type: "
                f"{entity_type}"
            ),
        )

    entity = session.exec(
        select(EntityVersion).where(
            EntityVersion.entity_type
            == entity_type,
            EntityVersion.entity_id
            == entity_id,
        )
    ).first()

    if entity is None:
        raise HTTPException(
            status_code=404,
            detail="Entity not found",
        )

    latest_operation = session.exec(
        select(SyncOperation)
        .where(
            SyncOperation.entity_type
            == entity_type,
            SyncOperation.entity_id
            == entity_id,
            SyncOperation.status
            == "COMPLETED",
        )
        .order_by(
            SyncOperation.server_version.desc()
        )
    ).first()

    payload = None

    if latest_operation is not None:
        payload = json.loads(
            latest_operation.payload
        )

    return {
        "entity_type": entity_type,
        "entity_id": entity_id,
        "server_version": entity.version,
        "payload": payload,
    }


@router.get("/changes")
def get_changes(
    since: int = 0,
    session: Session = Depends(get_session),
):
    operations = session.exec(
        select(SyncOperation)
        .where(
            SyncOperation.status
            == "COMPLETED",
            SyncOperation.server_version
            > since,
        )
        .order_by(
            SyncOperation.server_version.asc()
        )
    ).all()

    return {
        "changes": [
            {
                "operation_id": (
                    operation.operation_id
                ),
                "entity_type": (
                    operation.entity_type
                ),
                "entity_id": (
                    operation.entity_id
                ),
                "operation_type": (
                    operation.operation_type
                ),
                "payload": json.loads(
                    operation.payload
                ),
                "server_version": (
                    operation.server_version
                ),
            }
            for operation in operations
        ]
    }