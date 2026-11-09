// Picks the right sqflite factory for the platform without importing
// web-only code into Android/iOS/desktop builds.
export 'db_init_stub.dart' if (dart.library.js_interop) 'db_init_web.dart';
