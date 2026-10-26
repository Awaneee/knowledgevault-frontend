// Opens the on-disk cache database for the current platform: a SQLite file
// on mobile/desktop, OPFS/IndexedDB-backed WASM SQLite in the browser.
export 'native.dart' if (dart.library.js_interop) 'web.dart';
