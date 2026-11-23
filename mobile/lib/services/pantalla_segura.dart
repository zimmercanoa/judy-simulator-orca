import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Activa FLAG_SECURE en Android (bloquea capturas de pantalla y la vista
/// previa en "recientes") mientras una pantalla sensible está visible.
class PantallaSegura {
  PantallaSegura._();

  static const _canal = MethodChannel('judy/seguridad');

  /// Pantallas seguras abiertas (p. ej. Registro encima de Login).
  static int _activas = 0;

  static Future<void> activar(bool activar) async {
    _activas = (_activas + (activar ? 1 : -1)).clamp(0, 1000);
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _canal
          .invokeMethod<void>('pantallaSegura', {'activar': _activas > 0});
    } on MissingPluginException {
      // Pruebas o plataforma sin implementación nativa: se ignora.
    } on PlatformException {
      // No debe impedir usar la app.
    }
  }
}

/// Mezcla para `State`: FLAG_SECURE activo durante la vida de la pantalla.
mixin PantallaSeguraMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    PantallaSegura.activar(true);
  }

  @override
  void dispose() {
    PantallaSegura.activar(false);
    super.dispose();
  }
}
