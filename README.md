# Simple Multiplayer Chess

Flutter chess client with a FastAPI/WebSocket server. The server owns accounts, password hashing, access tokens, and email verification; Firebase is not used.

## Configure the backend

For production, configure a long random `JWT_SECRET` and SMTP credentials from your email provider:

```bash
export JWT_SECRET='replace-with-a-long-random-secret'
export DATA_ENCRYPTION_KEY='a-Fernet-compatible-32-byte-base64-key'
export PUBLIC_API_URL='http://localhost:8000'
export SMTP_HOST='smtp.example.com'
export SMTP_PORT='587'
export SMTP_USERNAME='your-smtp-username'
export SMTP_PASSWORD='your-smtp-password'
export SMTP_FROM='Chess <no-reply@example.com>'
```

For local development, Docker starts Mailpit automatically. Verification and reset messages appear at `http://localhost:8025`; no mail-provider account is required. Add SMTP variables only when deploying and sending real email.

Start the API:

```bash
docker compose up --build
```

Run the Flutter app from the project root:

```bash
flutter pub get
flutter run --dart-define=API_URL=http://localhost:8000
```

For an Android emulator use `http://10.0.2.2:8000` for `API_URL`.

## Usage

Register two accounts, verify each email in Mailpit, then sign in on two devices or browser profiles. Choose **Start a new game**, select 5/10/15 minutes and a color, find the other player, and send an invitation. The recipient accepts it from **Invitations**; both players then open it from **Active Games**. Moves, clocks, results, restart requests, and disconnect pauses are synchronized through the backend.

## Android and browser launch

Build a debug APK with `flutter build apk --debug`; it is written to `build/app/outputs/flutter-apk/app-debug.apk`. Install it with `adb install -r build/app/outputs/flutter-apk/app-debug.apk`, or run directly on an emulator with `flutter run -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:8000`. Run in Chrome with `flutter run -d chrome --dart-define=API_URL=http://localhost:8000`.

## Account flow

Registration creates a player record, stores a scrypt password hash, encrypts the username and email at rest, and emails a single-use link to `GET /auth/verify-email?token=...`. A keyed lookup digest supports account uniqueness and login without storing plaintext account details. The Flutter app persists the backend JWT and shows the player name on the home and profile screens.

API endpoints include `POST /auth/register`, `POST /auth/login`, `POST /auth/resend-verification`, `GET /auth/verify-email`, `GET /users/me`, game routes, and the game WebSocket.
