/// Validadores de formularios alineados con las reglas de `api/registro.php`.
library;

final _reMatricula = RegExp(r'^[A-Za-z0-9_-]{3,20}$');
final _reCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final _reTelefono = RegExp(r'^[0-9 +()-]{7,15}$');

String? validarRequerido(String? v, String campo) =>
    (v == null || v.trim().isEmpty) ? 'Escribe $campo' : null;

String? validarMatricula(String? v) {
  final t = v?.trim() ?? '';
  if (t.isEmpty) return 'Escribe tu matrícula';
  if (!_reMatricula.hasMatch(t)) {
    return 'Solo letras, números, guion y guion bajo (3-20)';
  }
  return null;
}

String? validarCorreo(String? v) {
  final t = v?.trim() ?? '';
  if (t.isEmpty) return 'Escribe tu correo';
  if (t.length > 100 || !_reCorreo.hasMatch(t)) return 'Correo no válido';
  return null;
}

/// Teléfono opcional.
String? validarTelefono(String? v) {
  final t = v?.trim() ?? '';
  if (t.isEmpty) return null;
  return _reTelefono.hasMatch(t) ? null : 'Teléfono no válido';
}

String? validarPassword(String? v) {
  final t = v ?? '';
  if (t.length < 8) return 'Mínimo 8 caracteres';
  if (t.length > 72) return 'Máximo 72 caracteres';
  return null;
}
