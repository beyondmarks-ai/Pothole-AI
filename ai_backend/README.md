# RoadCare AI backend

This server keeps the Azure AI Foundry credential outside the Android APK. It
accepts a road photo, asks the configured GPT-4.1 mini deployment for strict
structured analysis, rejects unrelated/uncertain images, and calculates the
priority deterministically from 70% severity and 30% AI confidence.

## Local run

Set the endpoint and deployment variables shown in `.env.example` in the
process environment, then run. Local development can use the current Azure CLI
login without an API key by setting `AZURE_OPENAI_USE_IDENTITY=true`:

```powershell
npm start
```

The Flutter debug app uses `http://127.0.0.1:7071/analyze` through `adb reverse`.
Production should deploy this container behind HTTPS and pass the URL using:

```powershell
flutter build apk --release --dart-define=ROADCARE_AI_API_URL=https://YOUR-API/analyze
```

Do not put the Azure key in Flutter, source control, or `--dart-define`.
