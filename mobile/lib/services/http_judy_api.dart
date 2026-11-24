import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/avance.dart';
import '../models/usuario.dart';
import 'judy_api.dart';

/// Cliente HTTP de la API REST PHP (`api/*.php`).
class HttpJudyApi implements JudyApi {
  HttpJudyApi({
    String baseUrl = AppConfig.apiBaseUrl,
    http.Client? client,
    this.timeout = AppConfig.timeout,
  })  : baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  final Duration timeout;

  @override
  String? token;

  @override
  bool get esDemo => false;

  Uri _uri(String endpoint, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl/$endpoint').replace(queryParameters: query);

  Map<String, String> _headers({bool json = false}) => {
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json; charset=utf-8',
        if (token != null) 'Authorization': 'Bearer $token',
        // Respaldo si el hosting descarta Authorization (PHP como CGI).
        'X-Api-Token': ?token,
      };

  Future<Map<String, dynamic>> _get(String endpoint,
          [Map<String, String>? query]) =>
      _send(() => _client.get(_uri(endpoint, query), headers: _headers()));

  Future<Map<String, dynamic>> _post(String endpoint,
          [Map<String, dynamic> body = const {}]) =>
      _send(() => _client.post(
            _uri(endpoint),
            headers: _headers(json: true),
            body: jsonEncode(body),
          ));

  Future<Map<String, dynamic>> _send(
      Future<http.Response> Function() request) async {
    if (baseUrl.contains('CUENTA.alwaysdata.net')) {
      throw const ApiException(
          'Esta compilación no tiene servidor configurado (SITE_URL). '
          'Usa el modo demo.');
    }
    final http.Response res;
    try {
      res = await request().timeout(timeout);
    } on TimeoutException {
      throw const ApiException(
          'El servidor tardó demasiado en responder. Revisa tu conexión.');
    } on http.ClientException {
      // IOClient envuelve SocketException/HandshakeException en ClientException.
      throw const ApiException(
          'Sin conexión con el servidor. Revisa tu internet o usa el modo demo.');
    }
    return decodeResponse(res);
  }

  /// Decodifica la respuesta y la convierte en [ApiException] si no es
  /// un JSON `ok`. Público para poder probarlo.
  static Map<String, dynamic> decodeResponse(http.Response res) {
    final body = utf8.decode(res.bodyBytes, allowMalformed: true);
    if (esDesafioAntiBot(body)) {
      throw ApiException(
        'El hosting del servidor bloqueó la app con un desafío anti-bots '
        '(InfinityFree). Compila la app con SITE_URL apuntando a alwaysdata; '
        'mientras tanto usa el modo demo o el portal web.',
        status: res.statusCode,
        antiBot: true,
      );
    }
    Object? data;
    try {
      data = jsonDecode(body);
    } on FormatException {
      throw ApiException(
        'Respuesta inesperada del servidor (HTTP ${res.statusCode}).',
        status: res.statusCode,
      );
    }
    if (data is! Map<String, dynamic>) {
      throw ApiException('Respuesta inválida del servidor.',
          status: res.statusCode);
    }
    if (res.statusCode < 200 || res.statusCode >= 300 || data['ok'] != true) {
      throw ApiException(
        (data['error'] ?? 'Error del servidor (HTTP ${res.statusCode}).')
            .toString(),
        status: res.statusCode,
      );
    }
    return data;
  }

  /// Detecta la página de InfinityFree que exige JavaScript (`aes.js`,
  /// cookie `__test`) en lugar de la respuesta JSON.
  static bool esDesafioAntiBot(String body) {
    final b = body.trimLeft();
    if (b.startsWith('{') || b.startsWith('[')) return false;
    return b.contains('aes.js') ||
        b.contains('__test=') ||
        b.contains('slowAES') ||
        b.contains('This site requires Javascript to work');
  }

  @override
  Future<LoginResult> login(String matricula, String password) async {
    final data = await _post(
        'login.php', {'matricula': matricula, 'password': password});
    final t = data['token']?.toString() ?? '';
    if (t.isEmpty) throw const ApiException('El servidor no devolvió token.');
    token = t;
    return LoginResult(
      token: t,
      usuario: Usuario.fromJson(
          Map<String, dynamic>.from(data['usuario'] as Map? ?? const {})),
    );
  }

  @override
  Future<void> logout() async {
    try {
      if (token != null) await _post('logout.php');
    } finally {
      token = null;
    }
  }

  @override
  Future<Usuario> me() async {
    final data = await _get('me.php');
    return Usuario.fromJson(
        Map<String, dynamic>.from(data['usuario'] as Map? ?? const {}));
  }

  @override
  Future<List<Avance>> avances({int? idUsuario}) async {
    final data = await _get('avances.php',
        idUsuario == null ? null : {'id_usuario': '$idUsuario'});
    final lista = (data['avances'] as List? ?? const []);
    return lista
        .map((e) => Avance.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<Avance> actualizarAvance({
    required int idAvance,
    required int porcentaje,
    required EstadoAvance estado,
    required String retroalimentacion,
  }) async {
    final data = await _post('avances.php', {
      'id_avance': idAvance,
      'porcentaje': porcentaje,
      'estado': estado.api,
      'retroalimentacion': retroalimentacion,
    });
    return Avance.fromJson(
        Map<String, dynamic>.from(data['avance'] as Map? ?? const {}));
  }

  @override
  Future<List<UsuarioPendiente>> usuariosPendientes() async {
    final data = await _get('usuarios.php');
    final lista = (data['usuarios'] as List? ?? const []);
    return lista
        .map((e) =>
            UsuarioPendiente.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> resolverUsuario(int idUsuario,
      {required bool aprobar, Rol? rol}) async {
    await _post('usuarios.php', {
      'id_usuario': idUsuario,
      'accion': aprobar ? 'aprobar' : 'rechazar',
      if (rol != null) 'rol': rol.api,
    });
  }

  @override
  Future<String> registro({
    required String matricula,
    required String nombre,
    required String correo,
    required String telefono,
    required String password,
  }) async {
    final data = await _post('registro.php', {
      'matricula': matricula,
      'nombre': nombre,
      'correo': correo,
      'telefono': telefono,
      'password': password,
    });
    return (data['mensaje'] ?? 'Registro recibido.').toString();
  }

  @override
  Future<String> chat(String mensaje) async {
    final data = await _post('asistente.php', {'mensaje': mensaje});
    return (data['respuesta'] ?? '').toString();
  }

  @override
  Future<void> eliminarCuenta(String password) async {
    await _post('eliminar_cuenta.php', {'password': password});
    token = null;
  }

  @override
  Future<VersionInfo?> ultimaVersion() async {
    try {
      final data = await _get('version.php');
      if (data['publicada'] != true) return null;
      return VersionInfo(
        version: (data['version'] ?? '').toString(),
        versionCode: int.tryParse('${data['version_code']}') ?? 0,
        descargaUrl:
            (data['descarga_url'] ?? AppConfig.descargaUrl).toString(),
        notas: (data['notas'] ?? '').toString(),
      );
    } on ApiException {
      // Sin red o servidor bloqueado: no se avisa de actualizaciones.
      return null;
    }
  }

  @override
  Future<String> contacto({
    required String nombre,
    required String correo,
    required String mensaje,
  }) async {
    final data = await _post('contacto.php',
        {'nombre': nombre, 'correo': correo, 'mensaje': mensaje});
    return (data['mensaje'] ?? 'Mensaje enviado.').toString();
  }
}
