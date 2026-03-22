# Scrib

Scrib records lectures, transcribes audio, and generates structured study notes.

## Secure API Key Setup (Backend)

This project now uses a local backend proxy so API keys are not stored in the Flutter app.

### 1. Start backend

```bash
cd backend
npm install
cp .env.example .env
```

Fill `backend/.env` with your real keys:

```env
PORT=8787
ASSEMBLYAI_KEY=your_key_here
ANTHROPIC_KEY=your_key_here
```

Run backend:

```bash
npm run dev
```

Health check:

```bash
http://localhost:8787/health
```

### 2. Run Flutter app

Android emulator (default in app constants is `http://10.0.2.2:8787`):

```bash
flutter run -d emulator-5554
```

If you use a real phone or different backend host, override backend URL:

```bash
flutter run --dart-define=BACKEND_BASE_URL=http://<your-ip>:8787
```

## Why this is safer

- Keys live in backend `.env`, not in git-tracked app code.
- App only talks to your backend.
- Backend talks to Anthropic/AssemblyAI using server-side secrets.
