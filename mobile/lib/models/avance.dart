/// Estados permitidos para un avance VR (iguales a la web PHP).
enum EstadoAvance {
  enProgreso('En Progreso'),
  completado('Completado'),
  pendiente('Pendiente');

  const EstadoAvance(this.api);

  /// Valor exacto que se guarda en `avances_vr.estado`.
  final String api;

  static EstadoAvance fromApi(String? valor) => EstadoAvance.values.firstWhere(
        (e) => e.api.toLowerCase() == (valor ?? '').trim().toLowerCase(),
        orElse: () => EstadoAvance.pendiente,
      );
}

/// Registro de la tabla `avances_vr`.
class Avance {
  const Avance({
    required this.id,
    required this.idUsuario,
    required this.modulo,
    required this.porcentaje,
    required this.estado,
    this.retroalimentacion = '',
    this.nombreCompleto,
    this.matricula,
  });

  final int id;
  final int idUsuario;
  final String modulo;
  final int porcentaje;
  final EstadoAvance estado;
  final String retroalimentacion;

  /// Solo presente en respuestas para gerencia.
  final String? nombreCompleto;
  final String? matricula;

  /// Progreso normalizado 0.0–1.0 para barras de progreso.
  double get fraccion => porcentaje.clamp(0, 100) / 100.0;

  factory Avance.fromJson(Map<String, dynamic> json) => Avance(
        id: _toInt(json['id_avance']),
        idUsuario: _toInt(json['id_usuario']),
        modulo: (json['modulo'] ?? '').toString(),
        porcentaje: _toInt(json['porcentaje']).clamp(0, 100),
        estado: EstadoAvance.fromApi(json['estado']?.toString()),
        retroalimentacion: (json['retroalimentacion'] ?? '').toString(),
        nombreCompleto: json['nombre_completo']?.toString(),
        matricula: json['matricula']?.toString(),
      );

  Avance copyWith({
    int? porcentaje,
    EstadoAvance? estado,
    String? retroalimentacion,
  }) =>
      Avance(
        id: id,
        idUsuario: idUsuario,
        modulo: modulo,
        porcentaje: porcentaje ?? this.porcentaje,
        estado: estado ?? this.estado,
        retroalimentacion: retroalimentacion ?? this.retroalimentacion,
        nombreCompleto: nombreCompleto,
        matricula: matricula,
      );
}

/// Promedio de avance de una lista (0–100).
int promedioAvance(List<Avance> avances) {
  if (avances.isEmpty) return 0;
  final total = avances.fold<int>(0, (s, a) => s + a.porcentaje);
  return (total / avances.length).round();
}

int _toInt(Object? v) {
  if (v is int) return v;
  if (v is double) return v.round();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}
