import 'auth_storage_backend_base.dart';
import 'auth_storage_backend_stub.dart'
    if (dart.library.io) 'auth_storage_backend_io.dart' as backend;

export 'auth_storage_backend_base.dart';

AuthStorageBackend createAuthStorageBackend() =>
    backend.createAuthStorageBackend();
