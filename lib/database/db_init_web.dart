import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Web needs the wasm-backed factory.
void initDatabaseFactory() {
  databaseFactory = databaseFactoryFfiWeb;
}
