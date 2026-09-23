from fastapi import FastAPI
from fastapi import WebSocket, WebSocketDisconnect


from app.database import create_db_and_tables
from app.routers.sync import router as sync_router

from app.websocket_manager import manager


app = FastAPI(
    title="Clinix Backend",
    version="1.0.0",
)


@app.on_event("startup")
def on_startup():
    create_db_and_tables()


app.include_router(sync_router)


@app.get("/health")
def health():
    return {
        "status": "ok",
        "service": "clinix-backend",
    }
    
    
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)

    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    except Exception:
        manager.disconnect(websocket)