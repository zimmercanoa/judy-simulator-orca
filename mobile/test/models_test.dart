import 'package:flutter_test/flutter_test.dart';
import 'package:judy_simulator/models/avance.dart';
import 'package:judy_simulator/models/usuario.dart';
import 'package:judy_simulator/utils/validadores.dart';

void main() {
  group('Usuario', () {
    test('fromJson acepta ids como texto y mapea el rol', () {
      final u = Usuario.fromJson({
        'id_usuario': '7',
        'matricula': 'GER-001',
        'nombre_completo': 'Gerente',
        'rol': 'gerencia',
      });
      expect(u.id, 7);
      expect(u.esGerencia, isTrue);
      expect(u.toJson()['rol'], 'gerencia');
    });

    test('rol desconocido => porAsignar', () {
      expect(Rol.fromApi('otro'), Rol.porAsignar);
      expect(Rol.fromApi(null), Rol.porAsignar);
      expect(Rol.porAsignar.api, 'por_asignar');
    });
  });

  group('Avance', () {
    test('fromJson normaliza porcentaje y estado', () {
      final a = Avance.fromJson({
        'id_avance': 1,
        'id_usuario': 2,
        'modulo': 'Fase 1',
        'porcentaje': '150',
        'estado': 'completado',
        'retroalimentacion': null,
      });
      expect(a.porcentaje, 100);
      expect(a.fraccion, 1.0);
      expect(a.estado, EstadoAvance.completado);
      expect(a.retroalimentacion, '');
      expect(a.nombreCompleto, isNull);
    });

    test('estado desconocido => Pendiente; api conserva texto exacto', () {
      expect(EstadoAvance.fromApi('???'), EstadoAvance.pendiente);
      expect(EstadoAvance.enProgreso.api, 'En Progreso');
    });

    test('promedioAvance', () {
      Avance av(int p) => Avance(
          id: p, idUsuario: 1, modulo: 'm', porcentaje: p, estado: EstadoAvance.enProgreso);
      expect(promedioAvance(const []), 0);
      expect(promedioAvance([av(100), av(40), av(0)]), 47);
    });

    test('copyWith solo cambia lo indicado', () {
      const a = Avance(
          id: 1, idUsuario: 2, modulo: 'm', porcentaje: 10, estado: EstadoAvance.pendiente);
      final b = a.copyWith(porcentaje: 60, estado: EstadoAvance.enProgreso);
      expect(b.porcentaje, 60);
      expect(b.estado, EstadoAvance.enProgreso);
      expect(b.modulo, 'm');
    });
  });

  group('Validadores', () {
    test('matrícula', () {
      expect(validarMatricula('EMP-001'), isNull);
      expect(validarMatricula(''), isNotNull);
      expect(validarMatricula('a b'), isNotNull);
    });
    test('correo, teléfono y contraseña', () {
      expect(validarCorreo('a@b.co'), isNull);
      expect(validarCorreo('malo'), isNotNull);
      expect(validarTelefono(''), isNull);
      expect(validarTelefono('55 1234 5678'), isNull);
      expect(validarTelefono('abc'), isNotNull);
      expect(validarPassword('1234567'), isNotNull);
      expect(validarPassword('12345678'), isNull);
    });
  });
}
