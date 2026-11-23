/// Roles válidos en la tabla `usuarios`.
enum Rol {
  empleado,
  gerencia,
  porAsignar;

  static Rol fromApi(String? valor) {
    switch (valor) {
      case 'gerencia':
        return Rol.gerencia;
      case 'empleado':
        return Rol.empleado;
      default:
        return Rol.porAsignar;
    }
  }

  String get api => switch (this) {
        Rol.empleado => 'empleado',
        Rol.gerencia => 'gerencia',
        Rol.porAsignar => 'por_asignar',
      };

  String get etiqueta => switch (this) {
        Rol.empleado => 'Empleado',
        Rol.gerencia => 'Gerencia',
        Rol.porAsignar => 'Por asignar',
      };
}

/// Usuario autenticado (datos públicos devueltos por `api/me.php`).
class Usuario {
  const Usuario({
    required this.id,
    required this.matricula,
    required this.nombreCompleto,
    required this.rol,
  });

  final int id;
  final String matricula;
  final String nombreCompleto;
  final Rol rol;

  bool get esGerencia => rol == Rol.gerencia;

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: _toInt(json['id_usuario']),
        matricula: (json['matricula'] ?? '').toString(),
        nombreCompleto: (json['nombre_completo'] ?? '').toString(),
        rol: Rol.fromApi(json['rol']?.toString()),
      );

  Map<String, dynamic> toJson() => {
        'id_usuario': id,
        'matricula': matricula,
        'nombre_completo': nombreCompleto,
        'rol': rol.api,
      };
}

/// Solicitud de cuenta pendiente de aprobación (solo gerencia).
class UsuarioPendiente {
  const UsuarioPendiente({
    required this.id,
    required this.matricula,
    required this.nombreCompleto,
    this.email = '',
    this.telefono = '',
  });

  final int id;
  final String matricula;
  final String nombreCompleto;
  final String email;
  final String telefono;

  factory UsuarioPendiente.fromJson(Map<String, dynamic> json) =>
      UsuarioPendiente(
        id: _toInt(json['id_usuario']),
        matricula: (json['matricula'] ?? '').toString(),
        nombreCompleto: (json['nombre_completo'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        telefono: (json['telefono'] ?? '').toString(),
      );
}

int _toInt(Object? v) {
  if (v is int) return v;
  return int.tryParse(v?.toString() ?? '') ?? 0;
}
