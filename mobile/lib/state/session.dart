import 'package:flutter/foundation.dart';

import '../config.dart';
import '../models/usuario.dart';
import '../services/demo_judy_api.dart';
import '../services/http_judy_api.dart';
import '../services/judy_api.dart';
import '../services/token_store.dart';

/// Estado global de sesión: qué API se usa (real o demo) y quién entró.
class SessionController extends ChangeNotifier {
  SessionController({
    required TokenStore store,
    JudyApi Function()? realApiFactory,
    JudyApi Function()? demoApiFactory,
  })  : _store = store,
        _realFactory = realApiFactory ?? (() => HttpJudyApi()),
        _demoFactory = demoApiFactory ?? (() => DemoJudyApi()) {
    _api = AppConfig.forceDemo ? _demoFactory() : _realFactory();
  }

  final TokenStore _store;
  final JudyApi Function() _realFactory;
  final JudyApi Function() _demoFactory;

  late JudyApi _api;
  Usuario? _usuario;
  bool _restaurado = false;

  JudyApi get api => _api;
  Usuario? get usuario => _usuario;
  bool get autenticado => _usuario != null;
  bool get esDemo => _api.esDemo;
  bool get restaurado => _restaurado;

  /// Cambia entre la API real y el modo demo (sin sesión abierta).
  void usarDemo(bool demo) {
    if (demo == _api.esDemo) return;
    _api = demo ? _demoFactory() : _realFactory();
    notifyListeners();
  }

  /// Recupera la sesión guardada al iniciar la app.
  /// [minimo] mantiene visible el splash al menos ese tiempo.
  Future<void> restaurar({Duration minimo = Duration.zero}) async {
    final espera = Future<void>.delayed(minimo);
    try {
      final token = await _store.read();
      if (token == null || token.isEmpty) return;
      if (token.startsWith(DemoJudyApi.prefijoToken)) {
        _api = _demoFactory();
      } else if (_api.esDemo) {
        _api = _realFactory();
      }
      _api.token = token;
      _usuario = await _api.me();
    } catch (e) {
      // Token vencido/revocado: se descarta. Otros errores (sin red)
      // también llevan al login, pero el token guardado se conserva.
      if (e is ApiException && e.noAutorizado) await _store.clear();
      _api.token = null;
      _usuario = null;
    } finally {
      await espera;
      _restaurado = true;
      notifyListeners();
    }
  }

  Future<void> login(String matricula, String password) async {
    final r = await _api.login(matricula.trim(), password);
    await _store.write(r.token);
    _usuario = r.usuario;
    notifyListeners();
  }

  /// Entra directamente en modo demo con el rol indicado.
  Future<void> entrarDemo(Rol rol) async {
    usarDemo(true);
    await login(rol == Rol.gerencia ? 'GER-001' : 'EMP-001',
        DemoJudyApi.passwordDemo);
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {
      // Aunque falle la red, la sesión local se cierra.
    }
    await _store.clear();
    _usuario = null;
    if (!AppConfig.forceDemo && _api.esDemo) _api = _realFactory();
    notifyListeners();
  }

  /// Elimina la cuenta en el servidor y borra la sesión local.
  Future<void> eliminarCuenta(String password) async {
    await _api.eliminarCuenta(password);
    await _store.clear();
    _api.token = null;
    _usuario = null;
    if (!AppConfig.forceDemo && _api.esDemo) _api = _realFactory();
    notifyListeners();
  }

  /// Llamar cuando la API responde 401 en cualquier pantalla.
  Future<void> sesionExpirada() async {
    await _store.clear();
    _api.token = null;
    _usuario = null;
    notifyListeners();
  }
}
