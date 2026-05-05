import 'auth_storage_backend_base.dart';

AuthStorageBackend createAuthStorageBackend() => _MemoryAuthStorageBackend();

class _MemoryAuthStorageBackend implements AuthStorageBackend {
  final Map<String, Object?> _values = <String, Object?>{};

  @override
  Future<void> init() async {}

  @override
  String? getString(String key) {
    final Object? value = _values[key];
    return value is String ? value : null;
  }

  @override
  int? getInt(String key) {
    final Object? value = _values[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> setInt(String key, int value) async {
    _values[key] = value;
  }

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }
}
