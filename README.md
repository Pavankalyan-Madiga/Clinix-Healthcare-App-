# Clinix

Clinix is an offline-first clinical mobile platform designed for simulated healthcare staff. It enables staff to manage patients, clinical tasks, notes, voice notes, vitals, messaging, QR/barcode scanning, and wound documentation while continuing to work without network connectivity.


## Project Overview

Clinix follows an offline-first architecture where the local database is the primary working environment. User actions are stored locally and synchronized with the backend when connectivity is restored.

The project was developed according to the requirements of the **Offline-First Clinical Mobile Platform** specification.

## Core Features

### Patient Management

- View patient list
- View patient profiles
- Patient search and selection
- Patient status management
- Local patient persistence

### Clinical Task Management

- Create and manage clinical tasks
- Assign tasks to staff
- Update task status
- Track task changes offline
- Synchronize task changes with the backend

### Notes

- Create clinical notes
- Associate notes with patients
- Store notes locally
- Work with notes while offline
- Synchronize notes when connectivity is restored

### Offline-First Capability

- Local SQLite persistence using Drift
- Offline patient and task operations
- Offline notes and voice notes
- Pending operation queue
- Automatic synchronization after connectivity is restored
- Retry handling
- Partial synchronization failure handling
- Data persistence across application restarts

### Synchronization

- Pending operation queue
- Retry mechanism
- Operation ordering
- Client-generated operation IDs
- Idempotent operations
- Server version tracking
- Conflict detection
- Conflict resolution
- Synchronization recovery

### Conflict Resolution

Clinix detects conflicting changes when multiple clients modify the same entity.

The project demonstrates:

- Concurrent changes
- Version comparison
- Conflict detection
- Keep Local resolution
- Keep Server resolution
- Final synchronized state

### Real-Time Updates

Clinix uses WebSockets for real-time synchronization.

The implementation supports:

- Persistent WebSocket connection
- Connection failure handling
- Automatic reconnection
- Missed-event recovery
- Duplicate event detection
- Stale event detection
- Application lifecycle recovery

### Additional Modules

The project implements four additional modules from the PRD.

1. **Patient QR/Barcode Scanning** — Uses the device camera to scan patient identifiers and open the corresponding patient profile.
2. **Patient Vitals** — Staff can record patient vitals and persist them locally for later synchronization.
3. **Staff Messaging** — Provides staff-to-staff messaging with local persistence and synchronization support.
4. **Wound/Photo Documentation** — Staff can capture wound photographs using the device camera, associate them with patients, add notes, and store the documentation locally.

### Voice Notes

Clinix supports clinical voice notes using the device microphone.

Features include:

- Native microphone recording
- Local audio storage
- Recording duration
- Patient association
- Local persistence
- Playback
- Offline recording
- Permission and recording error handling

## Architecture

```
                         CLINIX MOBILE APP
                                |
                                v
                    +----------------------+
                    |      Flutter UI      |
                    |      Riverpod        |
                    +----------+-----------+
                               |
                               v
                    +----------------------+
                    |    Local Database    |
                    |     Drift / SQLite   |
                    +----------+-----------+
                               |
                               v
                    +----------------------+
                    |      Sync Engine     |
                    | Queue / Retry        |
                    | Idempotency          |
                    | Version Tracking     |
                    | Conflict Resolution  |
                    +----------+-----------+
                               |
                    REST API  |  WebSocket
                               |
                               v
                    +----------------------+
                    |    FastAPI Backend   |
                    +----------+-----------+
                               |
                               v
                    +----------------------+
                    |      PostgreSQL      |
                    +----------------------+
```

## Offline-First Data Flow

```
User Action
     |
     v
Local Database
     |
     +--------------> UI Updated Immediately
     |
     v
Sync Operation Queue
     |
     v
Network Available?
     |
  +--+------+
  |         |
 NO        YES
  |         |
  v         v
Wait    Send Operation
            |
            v
       Backend Validation
            |
       +----+-----+
       |          |
    Success    Conflict
       |          |
       v          v
   Complete    Resolve
```

## Conflict Resolution Flow

```
Client A Change
       |
       v
Server Version Check
       ^
       |
Client B Change
       |
       v
Version Conflict
       |
       v
Conflict Detection
       |
   +---+----------+
   |              |
Keep Local    Keep Server
   |              |
   +------+-------+
          |
          v
   Final Consistent State
```

## WebSocket Recovery

```
WebSocket Connected
        |
        v
Receive Real-Time Event
        |
        v
Check Entity Version
        |
   +----+-----+
   |          |
Current     Stale /
Event       Duplicate
   |          |
   v          v
Apply       Ignore
Update
   |
   v
Connection Lost
   |
   v
Automatic Reconnect
   |
   v
Recover Missed Changes
   |
   v
Resume Real-Time Updates
```

## Technology Stack

### Mobile

- Flutter
- Dart
- Material 3
- Riverpod
- Drift
- SQLite
- WebSocket

### Native Capabilities

- Device Camera
- QR/Barcode Scanning
- Microphone
- Audio Recording
- Audio Playback
- Local File Storage

### Backend

- Python
- FastAPI
- PostgreSQL
- REST API
- WebSocket

## Project Structure

```
Clinix/
|
+-- clinix/
|   +-- lib/
|   |   +-- app/
|   |   +-- core/
|   |   |   +-- database/
|   |   |   +-- network/
|   |   |   +-- sync/
|   |   |   +-- websocket/
|   |   |   +-- storage/
|   |   |   +-- lifecycle/
|   |   +-- providers/
|   |   +-- features/
|   |   |   +-- auth/
|   |   |   +-- home/
|   |   |   +-- patients/
|   |   |   +-- tasks/
|   |   |   +-- notes/
|   |   |   +-- voice_notes/
|   |   |   +-- vitals/
|   |   |   +-- messaging/
|   |   |   +-- qr_scanner/
|   |   |   +-- wound_documentation/
|   |   +-- shared/
|   |   +-- android/
|   |   +-- ios/
|   |   +-- web/
|   |   +-- pubspec.yaml
|   |
+-- backend/
+-- docker-compose.yml
+-- README.md
+-- .gitignore
```

## Database

Clinix uses Drift with SQLite for persistent local storage.

The local database stores:

- Patients
- Tasks
- Notes
- Voice notes
- Sync operations
- Sync conflicts
- Entity versions
- Vitals
- Messages
- Wound photographs

The local database allows the application to continue working without network connectivity.

## Running the Backend

```bash
cd backend
source .venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

The API will be available at:

- `http://localhost:8000`
- FastAPI documentation: `http://localhost:8000/docs`

## Running the Flutter Application

```bash
cd clinix
flutter pub get
flutter run
```

For Chrome/Web:

```bash
flutter run -d chrome
```

## Building the Android APK

Create a release APK using:

```bash
cd clinix
flutter build apk --release
```

The generated APK will be located at:

```
clinix/build/app/outputs/flutter-apk/app-release.apk
```

The Android APK is the primary mobile application build for evaluation and demonstration.

## Building Flutter Web

```bash
cd clinix
flutter build web --release
```



## Authentication

Clinix uses simulated authentication for the project demonstration.

**Demo credentials:**

| Field | Value |
|---|---|
| Staff ID | `STAFF-001` |
| Password | `Clinix@123` |

No real healthcare authentication system is used.

## Testing

The project includes testing and validation for:

### Offline Functionality

- Offline data creation
- Offline data updates
- Local persistence
- Application restart persistence

### Synchronization

- Successful synchronization
- Failed synchronization
- Retry handling
- Partial synchronization failure
- Duplicate operations
- Idempotency
- Operation ordering

### Conflicts

- Concurrent client changes
- Version comparison
- Conflict detection
- Keep Local resolution
- Keep Server resolution
- Final consistency

### WebSockets

- Initial connection
- Real-time events
- Connection loss
- Automatic reconnection
- Duplicate events
- Stale events
- Missed-event recovery

### Native Features

- QR/barcode scanning
- Camera capture
- Microphone permission
- Voice recording
- Voice playback
- Local photo storage

### Lifecycle

- Background/foreground recovery
- Network reconnection
- WebSocket recovery
- Local data persistence

## Production Build

The project provides a production-oriented Android build for evaluation.

The project includes:

- Release APK
- Production-oriented configuration
- Environment configuration
- Backend setup instructions
- Seed/demo data
- Architecture documentation
- Testing documentation
- Project documentation
- Known limitations

## Demo

The project demonstration covers:

- User authentication
- Patient management
- Clinical task management
- Offline data creation
- Application restart
- Synchronization
- Retry and failure handling
- Conflict detection
- Conflict resolution
- WebSocket real-time updates
- WebSocket reconnection
- Voice notes
- QR/barcode scanning
- Patient vitals
- Staff messaging
- Wound/photo documentation

## Security Considerations

The application follows basic security practices appropriate for a simulated project.

- No real patient data is used
- Secrets are not committed to the repository
- Configuration is separated from application logic
- Backend endpoints validate synchronization operations
- Client operations use unique operation identifiers
- Server versions are used for conflict detection

## Scope and Limitations

Clinix is a simulated clinical platform developed for technical evaluation and demonstration.

The project does not include:

- Real hospital integrations
- Real EHR integration
- Real patient data
- Medical-device integration
- Regulatory certification
- HIPAA certification
- Advanced clinical decision support
- Large-scale hospital infrastructure
- Multi-region deployment

## AI Development Disclosure

AI coding and development assistants were used during development for:

- Architecture discussions
- Code implementation assistance
- Debugging
- Error analysis
- Synchronization design
- WebSocket implementation guidance
- Documentation generation
- Development workflow guidance

AI assistance was used as a development aid. The application was integrated, tested, and validated as part of the project development process.

## Project Deliverables

The project deliverables include:

- Flutter mobile application
- Android release APK
- FastAPI backend
- Docker configuration
- Offline-first synchronization system
- WebSocket real-time communication
- Architecture documentation
- Testing documentation
- Final project report
- AI tools documentation
- Source code repository

  ## 👨‍💻 Author

Developed by **Pavankalyan Madiga**

Role : **Mobile Engineer Intern(Flutter)**

[![GitHub](https://img.shields.io/badge/GitHub-Pavankalyan-Madiga-black?style=flat&logo=github)](https://github.com/Pavankalyan-Madiga) [![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?style=flat&logo=linkedin)](https://www.linkedin.com/in/pavankalyan-madiga/)


