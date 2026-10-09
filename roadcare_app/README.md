# RoadCare AI

Flutter Android application for AI-assisted road-damage reporting and an accountable municipal maintenance workflow.

## Implemented in this prototype

- Role-based demo sign-in for citizens, officers, maintenance teams, and administrators
- Citizen dashboard showing only the uploader's reports and live progress
- Operational dashboard with road-health, pending, active, and critical metrics
- Searchable and filterable incident register
- OpenStreetMap incident map with severity markers
- Camera/gallery evidence collection and device GPS capture
- Simulated pretrained YOLOv8 RDD analysis result with an explicit officer-review state
- Manual municipal review, approval/rejection, and maintenance assignment
- Repair start, completion evidence, rework, and authorized closure transitions
- Per-case audit timeline, status, severity, priority, health score, and team ownership
- Maintenance work queue, profile, system status, and dark mode
- Responsive Material 3 design and reusable UI components

The repository currently uses an in-memory demo repository so the complete mobile workflow can be reviewed without cloud credentials. Data resets when the process restarts. Replace `IncidentController` with a secured cloud repository before production use.

## Run

```powershell
flutter pub get
flutter run
```

Demo accounts are selected by role. The citizen demo uses `citizen@roadcare.app`; the municipal demo uses `officer@bidar.gov.in`. The password is `roadcare`.

## Verification

```powershell
flutter analyze
flutter test
```

## Android release

The project can create a locally installable release candidate with the debug key:

```powershell
flutter build apk --release --target-platform android-arm64
flutter build appbundle --release
```

For Play Store delivery, create an upload key, copy `android/key.properties.example` to `android/key.properties`, and fill in the private values. Gradle automatically uses that upload key when the file exists. Never commit the keystore or `key.properties`.

Android packaging requires free Gradle/temp space. On this workstation, redirect `GRADLE_USER_HOME`, `PUB_CACHE`, `TEMP`, and `TMP` to `D:\Pothole\.tool-cache`.

## Planned API boundary

The backend should provide endpoints for authentication, media upload, processing jobs, incidents, verification, assignments, repair evidence, closure, notifications, and dashboard metrics. AI inference remains on the backend; the mobile app uploads evidence and renders structured results.
