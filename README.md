# finance_tracker

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Building the Android APK

One-time setup: add 4 repo secrets (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`,
`KEY_ALIAS`, `KEY_PASSWORD`) under Settings > Secrets and variables > Actions.
Every build is then signed with the same key, so new APKs **update the
installed app and keep its data**. Never commit the keystore, and keep a backup.

Then push to `main` (or run **Build Android APK** from the Actions tab) and
download `finance-tracker-apk` from the run's Artifacts.

Local build: put your keystore details in `android/key.properties`, then
`flutter pub get && flutter build apk --release`.

Never change `applicationId` or the signing key, or Android treats it as a different app.
