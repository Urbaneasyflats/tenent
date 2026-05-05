import 'dart:convert';
import 'dart:io';

import 'auth_storage_backend_base.dart';

AuthStorageBackend createAuthStorageBackend() => _FileAuthStorageBackend();

class _FileAuthStorageBackend implements AuthStorageBackend {
  static const String _fileName = 'urbaneasyflats_mobile_auth_storage.json';

  final Map<String, Object?> _values = <String, Object?>{};
  File? _storageFile;
  bool _isInitialized = false;

  @override
  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    _isInitialized = true;
    _storageFile = _resolveStorageFile();
    if (_storageFile == null) {
      return;
    }

    try {
      if (!await _storageFile!.exists()) {
        return;
      }

      final String raw = await _storageFile!.readAsString();
      if (raw.trim().isEmpty) {
        return;
      }

      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return;
      }

      _values
        ..clear()
        ..addAll(decoded.cast<String, Object?>());
    } catch (_) {
      _values.clear();
    }
  }

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
    await _persist();
  }

  @override
  Future<void> setInt(String key, int value) async {
    _values[key] = value;
    await _persist();
  }

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
    await _persist();
  }

  Future<void> _persist() async {
    if (_storageFile == null) {
      return;
    }

    try {
      await _storageFile!.parent.create(recursive: true);
      await _storageFile!.writeAsString(jsonEncode(_values), flush: true);
    } catch (_) {
      // Keep the in-memory cache even if disk persistence is unavailable.
    }
  }

  File? _resolveStorageFile() {
    try {
      return File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}$_fileName',
      );
    } catch (_) {
      return null;
    }
  }
}
