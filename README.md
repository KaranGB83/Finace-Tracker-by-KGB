# Finance Tracker by KGB

A simple, offline money tracker for Android. Create a **book** for each purpose
(Personal, Business, "Father's money"…), then record **credits** (money in) and
**debits** (money out). Each book keeps a running balance in ₹.

All data is stored on your phone in a local SQLite database. Nothing is sent
anywhere and no account or internet connection is needed.

## Features

- **Books:** create books with a title, description and opening balance. They are shown in a 2-column grid. Long-press a book to delete it (and all its transactions).
- **Credit / Debit:** add transactions with an amount, a note and an optional description.
- **Edit transactions:** tap a transaction to change its amount, note, description, or switch it between credit and debit. The balance is corrected automatically and the original date is kept.
- **Delete transactions:** long-press a transaction. The balance is reversed automatically.
- **Backup / Restore:** the ⋮ menu on the home screen copies all your data to the clipboard as text (**Backup**) and reads it back in (**Restore**). Restore merges into existing data and never deletes anything.
- Balance and transaction changes are saved in a single database transaction, so they can't get out of sync.

## Install on your phone

1. Open the repo's **Actions** tab and open the latest successful **Build Android APK** run.
2. Download the `finance-tracker-apk` artifact, unzip it, and copy `app-release.apk` to your phone.
3. Tap the file and allow "install from unknown sources" when asked.

New versions install **over** the old one and keep your data, as long as they are built by this workflow (see below).

> **Back up regularly.** Open ⋮ → **Backup** and paste the result into Notes or an email. Uninstalling the app erases its data.

## Building the APK

### With GitHub Actions (recommended)

The workflow in `.github/workflows/build-apk.yml` builds a signed release APK on every push to `main`, or when you run **Build Android APK** manually from the Actions tab.

One-time setup: add four repository secrets under **Settings → Secrets and variables → Actions**:

| Secret | What it is |
|--------|------------|
| `KEYSTORE_BASE64` | your release keystore (`.jks`), base64-encoded |
| `KEYSTORE_PASSWORD` | keystore password |
| `KEY_ALIAS` | key alias |
| `KEY_PASSWORD` | key password |

The build stops with a "Missing repo secrets" error if they aren't set.

### Locally

Requires Flutter 3.41.x and JDK 17.

```bash
flutter pub get
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`. To sign it with your release key, create `android/key.properties`:

```properties
storeFile=/absolute/path/to/release.jks
storePassword=...
keyAlias=...
keyPassword=...
```

Without `key.properties`, local builds fall back to the debug key (fine for testing, but it can't update a release-signed install).

## Important: keep these stable

Android only updates an installed app in place if the **app ID** and the **signing key** are unchanged.

- App ID: `com.kgb.financetracker`
- Signing key: the keystore behind the secrets above

**Keep a safe backup of the keystore and its passwords, and never commit them to the repo** (`*.jks` and `key.properties` are git-ignored). If either the app ID or the key changes, Android treats it as a different app, and the old app's data can't be carried over except by Backup / Restore.

Bump `version` in `pubspec.yaml` (for example `1.1.0+2` → `1.1.1+3`) for every release. The number after `+` must increase or Android won't accept the update.

## Flutter version

The CI workflow is pinned to Flutter `3.41.x`, matching this project's Android setup (Gradle 8.14, Android Gradle Plugin 8.11, Kotlin 2.2). Newer Flutter releases require Gradle 9 and AGP 9, which needs a manual migration of the files in `android/`; see Flutter's [AGP 9 migration guide](https://docs.flutter.dev/release/breaking-changes/migrate-to-agp-9) before changing the pinned version.

## Project structure

```
lib/
├── main.dart                 App entry point and theme
├── database/
│   ├── dao.dart              All database access (books, transactions, backup/restore)
│   └── db_init*.dart         Picks the right SQLite factory (web vs. mobile)
├── models/
│   ├── book.dart
│   └── transaction.dart
└── screens/
    ├── home_screen.dart      Book grid, create/delete book, backup/restore
    └── book_screen.dart      Balance, transaction list, add/edit/delete
test/
└── widget_test.dart          Model tests
```

Built with Flutter, [`sqflite`](https://pub.dev/packages/sqflite), `uuid` and `intl`.

## Known limitations

- Transactions are stamped with the time they are added; the date can't be edited.
- Currency is fixed to ₹.
- The web build isn't set up. It needs `sqlite3.wasm` and `sqflite_sw.js` in `web/`; run `dart run sqflite_common_ffi_web:setup` to generate them.