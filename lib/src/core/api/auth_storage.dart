import 'auth_storage_backend.dart';

class AuthStorage {
  AuthStorage._();

  static const String _keyApiKey = 'apiKey';
  static const String _keySessionId = 'sessionID';
  static const String _keyVendorId = 'vendorID';
  static const String _keyDeviceId = 'deviceID';
  static const String _keyVendorType = 'vendorType';
  static const String _keyPushToken = 'pushToken';
  static const String _keyLastSyncedPushToken = 'lastSyncedPushToken';
  static const String _keyLocationTitle = 'locationTitle';
  static const String _keyLocationSubtitle = 'locationSubtitle';
  static const String _keyLocationLatitude = 'locationLatitude';
  static const String _keyLocationLongitude = 'locationLongitude';
  static const String _keyWishlistPropertyIds = 'wishlistPropertyIds';

  static final AuthStorageBackend _backend = createAuthStorageBackend();
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) {
      return;
    }
    await _backend.init();
    _isInitialized = true;
  }

  static AuthStorageBackend get _store {
    assert(_isInitialized, 'AuthStorage.init() must be called first');
    return _backend;
  }

  // Getters
  static String? get apiKey => _store.getString(_keyApiKey);
  static String? get sessionId => _store.getString(_keySessionId);
  static String? get vendorId => _store.getString(_keyVendorId);
  static String? get deviceId => _store.getString(_keyDeviceId);
  static int? get vendorType => _store.getInt(_keyVendorType);
  static String? get pushToken => _store.getString(_keyPushToken);
  static String? get lastSyncedPushToken =>
      _store.getString(_keyLastSyncedPushToken);
  static String? get locationTitle => _store.getString(_keyLocationTitle);
  static String? get locationSubtitle => _store.getString(_keyLocationSubtitle);
  static double? get locationLatitude =>
      double.tryParse(_store.getString(_keyLocationLatitude) ?? '');
  static double? get locationLongitude =>
      double.tryParse(_store.getString(_keyLocationLongitude) ?? '');
  static Set<String> get wishlistPropertyIds {
    final String raw = _store.getString(_keyWishlistPropertyIds) ?? '';
    return raw
        .split('|')
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toSet();
  }

  static bool get isLoggedIn =>
      sessionId != null &&
      sessionId!.isNotEmpty &&
      vendorId != null &&
      vendorId!.isNotEmpty;

  // Setters
  static Future<void> setApiKey(String value) =>
      _store.setString(_keyApiKey, value);

  static Future<void> setSessionId(String value) =>
      _store.setString(_keySessionId, value);

  static Future<void> setVendorId(String value) =>
      _store.setString(_keyVendorId, value);

  static Future<void> setDeviceId(String value) =>
      _store.setString(_keyDeviceId, value);

  static Future<void> setVendorType(int value) =>
      _store.setInt(_keyVendorType, value);

  static Future<void> setPushToken(String value) =>
      _store.setString(_keyPushToken, value);

  static Future<void> setLastSyncedPushToken(String value) =>
      _store.setString(_keyLastSyncedPushToken, value);

  static Future<void> clearLastSyncedPushToken() =>
      _store.remove(_keyLastSyncedPushToken);

  static Future<void> saveLocation({
    required String title,
    required String subtitle,
    required double latitude,
    required double longitude,
  }) async {
    await _store.setString(_keyLocationTitle, title);
    await _store.setString(_keyLocationSubtitle, subtitle);
    await _store.setString(_keyLocationLatitude, latitude.toString());
    await _store.setString(_keyLocationLongitude, longitude.toString());
  }

  static Future<void> setWishlistPropertyIds(Set<String> ids) async {
    await _store.setString(_keyWishlistPropertyIds, ids.join('|'));
  }

  static Future<void> saveLoginCredentials({
    required String sessionId,
    required String vendorId,
    int? vendorType,
  }) async {
    await setSessionId(sessionId);
    await setVendorId(vendorId);
    if (vendorType != null) {
      await setVendorType(vendorType);
    }
  }

  static Future<void> clearAll() async {
    await _store.remove(_keySessionId);
    await _store.remove(_keyVendorId);
    await _store.remove(_keyVendorType);
    await clearLastSyncedPushToken();
    // Keep apiKey and deviceId for re-login
  }
}
