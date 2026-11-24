import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistencia del token de sesión.
abstract class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

/// Guarda el token en Keychain (iOS) / almacenamiento cifrado (Android).
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _clave = 'judy_api_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: _clave);
    } catch (_) {
      // Almacenamiento corrupto o no disponible: se pide login de nuevo.
      return null;
    }
  }

  @override
  Future<void> write(String token) => _storage.write(key: _clave, value: token);

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _clave);
    } catch (_) {}
  }
}

/// Implementación en memoria (pruebas).
class MemoryTokenStore implements TokenStore {
  String? valor;

  @override
  Future<String?> read() async => valor;

  @override
  Future<void> write(String token) async => valor = token;

  @override
  Future<void> clear() async => valor = null;
}
