import 'dart:async';

import '../models/avance.dart';
import '../models/usuario.dart';
import 'judy_api.dart';

/// API simulada en memoria para usar la app sin servidor.
///
/// Usuarios demo (contraseña `demo1234`):
///  - `EMP-001`  Operador Demo (empleado)
///  - `GER-001`  Gerente Demo (gerencia)
class DemoJudyApi implements JudyApi {
  DemoJudyApi({this.latencia = const Duration(milliseconds: 350)}) {
    _reiniciar();
  }

  static const String passwordDemo = 'demo1234';
  static const String prefijoToken = 'demo-';

  final Duration latencia;

  @override
  String? token;

  @override
  bool get esDemo => true;

  late Map<String, Usuario> _usuarios;
  late List<Avance> _avances;
  late List<UsuarioPendiente> _pendientes;
  int _siguienteId = 10;

  void _reiniciar() {
    _usuarios = {
      'EMP-001': const Usuario(
          id: 2,
          matricula: 'EMP-001',
          nombreCompleto: 'Operador Demo',
          rol: Rol.empleado),
      'EMP-002': const Usuario(
          id: 5,
          matricula: 'EMP-002',
          nombreCompleto: 'Técnica Demo',
          rol: Rol.empleado),
      'GER-001': const Usuario(
          id: 1,
          matricula: 'GER-001',
          nombreCompleto: 'Gerente Demo',
          rol: Rol.gerencia),
    };
    _avances = [
      const Avance(
          id: 1,
          idUsuario: 2,
          modulo: 'Fase 1: Instalación (NOM-029)',
          porcentaje: 100,
          estado: EstadoAvance.completado,
          retroalimentacion:
              'Excelente dominio de los procedimientos eléctricos y uso de equipo de protección básico.',
          nombreCompleto: 'Operador Demo',
          matricula: 'EMP-001'),
      const Avance(
          id: 2,
          idUsuario: 2,
          modulo: 'Fase 2: Mantenimiento (NOM-009)',
          porcentaje: 40,
          estado: EstadoAvance.enProgreso,
          retroalimentacion:
              'Buen control en altura, reforzar la revisión de líneas de vida antes de ascender.',
          nombreCompleto: 'Operador Demo',
          matricula: 'EMP-001'),
      const Avance(
          id: 3,
          idUsuario: 2,
          modulo: 'Fase 3: Rescate en altura (NOM-009)',
          porcentaje: 0,
          estado: EstadoAvance.pendiente,
          nombreCompleto: 'Operador Demo',
          matricula: 'EMP-001'),
      const Avance(
          id: 4,
          idUsuario: 5,
          modulo: 'Fase 1: Instalación (NOM-029)',
          porcentaje: 75,
          estado: EstadoAvance.enProgreso,
          retroalimentacion:
              'Verificar la ausencia de tensión con el multímetro antes de cada conexión.',
          nombreCompleto: 'Técnica Demo',
          matricula: 'EMP-002'),
    ];
    _pendientes = [
      const UsuarioPendiente(
          id: 3,
          matricula: 'PEND-001',
          nombreCompleto: 'Solicitante Demo 1',
          email: 'solicitante1@example.com'),
      const UsuarioPendiente(
          id: 4,
          matricula: 'PEND-002',
          nombreCompleto: 'Solicitante Demo 2',
          email: 'solicitante2@example.com'),
    ];
  }

  Future<void> _esperar() => Future<void>.delayed(latencia);

  Usuario _actual() {
    final t = token;
    if (t == null || !t.startsWith(prefijoToken)) {
      throw const ApiException('Sesión inválida o expirada.', status: 401);
    }
    final u = _usuarios[t.substring(prefijoToken.length)];
    if (u == null) {
      throw const ApiException('Sesión inválida o expirada.', status: 401);
    }
    return u;
  }

  Usuario _gerencia() {
    final u = _actual();
    if (!u.esGerencia) {
      throw const ApiException('No tienes permisos para esta acción.',
          status: 403);
    }
    return u;
  }

  @override
  Future<LoginResult> login(String matricula, String password) async {
    await _esperar();
    final u = _usuarios[matricula.trim().toUpperCase()];
    if (u == null || password != passwordDemo) {
      throw const ApiException(
          'Matrícula o contraseña incorrectas (demo: EMP-001 o GER-001 / demo1234).',
          status: 401);
    }
    token = '$prefijoToken${u.matricula}';
    return LoginResult(token: token!, usuario: u);
  }

  @override
  Future<void> logout() async {
    token = null;
  }

  @override
  Future<Usuario> me() async {
    await _esperar();
    return _actual();
  }

  @override
  Future<List<Avance>> avances({int? idUsuario}) async {
    await _esperar();
    final u = _actual();
    if (!u.esGerencia) {
      return _avances.where((a) => a.idUsuario == u.id).toList();
    }
    if (idUsuario == null) return List.of(_avances);
    return _avances.where((a) => a.idUsuario == idUsuario).toList();
  }

  @override
  Future<Avance> actualizarAvance({
    required int idAvance,
    required int porcentaje,
    required EstadoAvance estado,
    required String retroalimentacion,
  }) async {
    await _esperar();
    _gerencia();
    if (porcentaje < 0 || porcentaje > 100) {
      throw const ApiException('El porcentaje debe estar entre 0 y 100.',
          status: 400);
    }
    final i = _avances.indexWhere((a) => a.id == idAvance);
    if (i < 0) throw const ApiException('El avance no existe.', status: 404);
    final nuevo = _avances[i].copyWith(
        porcentaje: porcentaje,
        estado: estado,
        retroalimentacion: retroalimentacion.trim());
    _avances[i] = nuevo;
    return nuevo;
  }

  @override
  Future<List<UsuarioPendiente>> usuariosPendientes() async {
    await _esperar();
    _gerencia();
    return List.of(_pendientes);
  }

  @override
  Future<void> resolverUsuario(int idUsuario,
      {required bool aprobar, Rol? rol}) async {
    await _esperar();
    _gerencia();
    if (aprobar && rol != Rol.empleado && rol != Rol.gerencia) {
      throw const ApiException('El rol debe ser empleado o gerencia.',
          status: 400);
    }
    final i = _pendientes.indexWhere((p) => p.id == idUsuario);
    if (i < 0) {
      throw const ApiException('El usuario no existe o ya no está pendiente.',
          status: 409);
    }
    final p = _pendientes.removeAt(i);
    if (aprobar) {
      _usuarios[p.matricula] = Usuario(
          id: p.id,
          matricula: p.matricula,
          nombreCompleto: p.nombreCompleto,
          rol: rol!);
    }
  }

  @override
  Future<String> registro({
    required String matricula,
    required String nombre,
    required String correo,
    required String telefono,
    required String password,
  }) async {
    await _esperar();
    final m = matricula.trim().toUpperCase();
    if (_usuarios.containsKey(m) || _pendientes.any((p) => p.matricula == m)) {
      throw const ApiException('Esa matrícula ya está registrada.',
          status: 409);
    }
    _pendientes.add(UsuarioPendiente(
        id: _siguienteId++,
        matricula: m,
        nombreCompleto: nombre.trim(),
        email: correo.trim(),
        telefono: telefono.trim()));
    return 'Registro recibido (demo). Gerencia debe aprobar tu cuenta antes de iniciar sesión.';
  }

  @override
  Future<String> chat(String mensaje) async {
    await _esperar();
    _actual();
    return respuestaDemo(mensaje);
  }

  /// Respuestas locales sobre normas y uso de la plataforma.
  static String respuestaDemo(String mensaje) {
    final m = mensaje.toLowerCase();
    if (RegExp(r'correo|tel[eé]fono|contraseña|password|matr[ií]cula de')
        .hasMatch(m)) {
      return 'Por privacidad no puedo acceder ni compartir datos personales. '
          'Si necesitas ayuda con tu cuenta, usa el formulario de contacto.';
    }
    if (m.contains('009') || m.contains('altura')) {
      return 'La NOM-009-STPS-2011 regula los trabajos en altura (a partir de '
          '1.80 m). Exige análisis de riesgos, sistema personal de detención de '
          'caídas (arnés, línea de vida y punto de anclaje), permiso de trabajo, '
          'capacitación del personal y un plan de rescate.';
    }
    if (m.contains('029') || m.contains('eléctric') || m.contains('electric')) {
      return 'La NOM-029-STPS-2011 establece condiciones de seguridad para el '
          'mantenimiento de instalaciones eléctricas: procedimientos de '
          'des-energizado, bloqueo y etiquetado (LOTO), verificación de ausencia '
          'de tensión, equipo de protección personal dieléctrico y personal autorizado.';
    }
    if (m.contains('registr') || m.contains('cuenta') || m.contains('aprob')) {
      return 'Regístrate desde la pantalla de inicio con tu matrícula. Gerencia '
          'revisará tu solicitud y te asignará el rol de empleado o gerencia; '
          'después podrás iniciar sesión.';
    }
    if (m.contains('módulo') || m.contains('modulo') || m.contains('vr')) {
      return 'JuDy Simulator entrena en realidad virtual la instalación y el '
          'mantenimiento seguro de paneles fotovoltaicos por fases: instalación '
          '(NOM-029), mantenimiento en altura (NOM-009) y rescate.';
    }
    return '(Modo demo) Puedo orientarte sobre las normas NOM-009 y NOM-029, '
        'los módulos VR y el registro. Pregunta, por ejemplo: '
        '"¿Qué exige la NOM-009?"';
  }

  @override
  Future<void> eliminarCuenta(String password) async {
    await _esperar();
    final u = _actual();
    if (password != passwordDemo) {
      throw const ApiException('La contraseña no es correcta.', status: 401);
    }
    _usuarios.remove(u.matricula);
    _avances.removeWhere((a) => a.idUsuario == u.id);
    token = null;
  }

  @override
  Future<VersionInfo?> ultimaVersion() async => null;

  @override
  Future<String> contacto({
    required String nombre,
    required String correo,
    required String mensaje,
  }) async {
    await _esperar();
    return 'Mensaje registrado (demo). En el servidor real se envía por correo al equipo.';
  }
}
