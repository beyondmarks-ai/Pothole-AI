# RoadCare AI

Flutter Android application for AI-assisted road-damage reporting and an accountable municipal maintenance workflow.

## Implemented in this prototype

- Role-based demo sign-in for citizens, officers, maintenance teams, and administrators
- Citizen dashboard showing only the uploader's reports and live progress
- Operational dashboard with road-health, pending, active, and critical metrics
- Searchable and filterable incident register
- OpenStreetMap incident map with severity markers
- Camera/gallery evidence collection and device GPS capture
- Azure AI Foundry GPT-4.1 mini image validation, damage classification, severity, confidence, and priority scoring
- Automatic rejection of unrelated images and low-confidence road evidence
- Manual municipal review, approval/rejection, and maintenance assignment
- Repair start, completion evidence, rework, and authorized closure transitions
- Per-case audit timeline, status, severity, priority, health score, and team ownership
- Maintenance work queue, profile, system status, and dark mode
- Responsive Material 3 design and reusable UI components

The incident repository remains in-memory for this prototype, so data resets when the process restarts. Image inference is real when the secure backend URL is supplied. Replace `IncidentController` with a secured cloud repository before production use.

## Run

```powershell
flutter pub get
flutter run --dart-define=ROADCARE_AI_API_URL=https://roadcare-ai-api-617db5.azurewebsites.net/api/analyze
```

Demo accounts are selected by role. The citizen demo uses `citizen@roadcare.app`; the municipal demo uses `officer@bidar.gov.in`. The password is `roadcare`.

## AI image analysis

The backend is in `../ai_backend`. It sends the image to an Azure AI Foundry
GPT-4.1 mini deployment using strict structured output. A case is created only
when the image shows a road, supported damage is visible, and confidence is at
least 65%. Priority is calculated as 70% severity plus 30% confidence.

The Azure API key is server-only. Never add it to Flutter or a build command.
For a local physical-device test, run the backend on port 7071, use
`adb reverse tcp:7071 tcp:7071`, and build with:

```powershell
flutter run --dart-define=ROADCARE_AI_API_URL=http://127.0.0.1:7071/analyze
```

The standalone version 1.1.0 release uses the public HTTPS Azure Function and
does not require ADB, a development computer, or a local backend process.

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
