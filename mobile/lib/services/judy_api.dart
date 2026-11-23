import '../models/avance.dart';
import '../models/usuario.dart';

/// Error de la API con un mensaje listo para mostrar al usuario.
class ApiException implements Exception {
  const ApiException(this.mensaje, {this.status, this.antiBot = false});

  final String mensaje;
  final int? status;

  /// `true` si el hosting devolvió el desafío JavaScript anti-bots
  /// (InfinityFree gratuito) en lugar de JSON.
  final bool antiBot;

  bool get noAutorizado => status == 401;

  @override
  String toString() => mensaje;
}

/// Resultado de un inicio de sesión.
class LoginResult {
  const LoginResult({required this.token, required this.usuario});
  final String token;
  final Usuario usuario;
}

/// Contrato común para la API real y el modo demo.
abstract class JudyApi {
  /// Token Bearer actual (null si no hay sesión).
  String? get token;
  set token(String? value);

  bool get esDemo;

  Future<LoginResult> login(String matricula, String password);
  Future<void> logout();
  Future<Usuario> me();

  /// Avances propios; gerencia recibe todos (o los de [idUsuario]).
  Future<List<Avance>> avances({int? idUsuario});

  /// Solo gerencia.
  Future<Avance> actualizarAvance({
    required int idAvance,
    required int porcentaje,
    required EstadoAvance estado,
    required String retroalimentacion,
  });

  /// Solo gerencia.
  Future<List<UsuarioPendiente>> usuariosPendientes();

  /// Solo gerencia. [rol] es obligatorio si [aprobar] es `true`.
  Future<void> resolverUsuario(int idUsuario, {required bool aprobar, Rol? rol});

  /// Devuelve el mensaje de confirmación del servidor.
  Future<String> registro({
    required String matricula,
    required String nombre,
    required String correo,
    required String telefono,
    required String password,
  });

  Future<String> chat(String mensaje);

  Future<String> contacto({
    required String nombre,
    required String correo,
    required String mensaje,
  });
}
