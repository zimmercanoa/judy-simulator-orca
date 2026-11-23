import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:judy_simulator/models/avance.dart';
import 'package:judy_simulator/models/usuario.dart';
import 'package:judy_simulator/services/demo_judy_api.dart';
import 'package:judy_simulator/services/http_judy_api.dart';
import 'package:judy_simulator/services/judy_api.dart';
import 'package:judy_simulator/services/token_store.dart';
import 'package:judy_simulator/state/session.dart';

/// Página real devuelta por InfinityFree a clientes sin JavaScript.
const _desafioInfinityFree =
    '<html><body><script type="text/javascript" src="/aes.js" ></script>'
    '<script>function toNumbers(d){var e=[];}var a=toNumbers("f6");'
    'document.cookie="__test="+toHex(slowAES.decrypt(c,2,a,b))+"; path=/";'
    'location.href="https://judysimulator.wuaze.com/?i=1";</script>'
    '<noscript>This site requires Javascript to work, please enable '
    'Javascript in your browser or use a browser with Javascript support'
    '</noscript></body></html>';

http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body), status,
    headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  group('HttpJudyApi', () {
    test('login envía JSON, guarda token y usa Bearer después', () async {
      final peticiones = <http.Request>[];
      final api = HttpJudyApi(
        baseUrl: 'https://api.test/api/',
        client: MockClient((req) async {
          peticiones.add(req);
          if (req.url.path.endsWith('login.php')) {
            return _json({
              'ok': true,
              'token': 'a' * 64,
              'usuario': {
                'id_usuario': 2,
                'matricula': 'EMP-001',
                'nombre_completo': 'Operador',
                'rol': 'empleado'
              }
            });
          }
          return _json({
            'ok': true,
            'avances': [
              {
                'id_avance': 1,
                'id_usuario': 2,
                'modulo': 'Fase 1',
                'porcentaje': 40,
                'estado': 'En Progreso',
                'retroalimentacion': 'ok'
              }
            ]
          });
        }),
      );

      final r = await api.login('EMP-001', 'secreto');
      expect(r.usuario.rol, Rol.empleado);
      expect(api.token, 'a' * 64);
      expect(peticiones.first.url.toString(), 'https://api.test/api/login.php');
      expect(jsonDecode(peticiones.first.body),
          {'matricula': 'EMP-001', 'password': 'secreto'});

      final avances = await api.avances();
      expect(avances.single.porcentaje, 40);
      expect(peticiones.last.headers['Authorization'], 'Bearer ${'a' * 64}');
    });

    test('error JSON del servidor se convierte en ApiException', () async {
      final api = HttpJudyApi(
        baseUrl: 'https://api.test/api',
        client: MockClient((_) async =>
            _json({'ok': false, 'error': 'Matrícula o contraseña incorrectas.'}, 401)),
      );
      expect(
        () => api.login('x', 'y'),
        throwsA(isA<ApiException>()
            .having((e) => e.status, 'status', 401)
            .having((e) => e.noAutorizado, 'noAutorizado', isTrue)
            .having((e) => e.mensaje, 'mensaje', contains('incorrectas'))),
      );
    });

    test('detecta el desafío anti-bots de InfinityFree', () async {
      expect(HttpJudyApi.esDesafioAntiBot(_desafioInfinityFree), isTrue);
      expect(HttpJudyApi.esDesafioAntiBot('{"ok":true}'), isFalse);

      final api = HttpJudyApi(
        baseUrl: 'https://api.test/api',
        client: MockClient((_) async => http.Response(_desafioInfinityFree, 200,
            headers: {'content-type': 'text/html'})),
      );
      expect(
        () => api.me(),
        throwsA(isA<ApiException>().having((e) => e.antiBot, 'antiBot', isTrue)),
      );
    });

    test('HTML desconocido => error genérico, no crash', () {
      expect(
        () => HttpJudyApi.decodeResponse(http.Response('<h1>500</h1>', 500)),
        throwsA(isA<ApiException>().having((e) => e.antiBot, 'antiBot', isFalse)),
      );
    });

    test('actualizarAvance envía el estado exacto de la BD', () async {
      late Map<String, dynamic> enviado;
      final api = HttpJudyApi(
        baseUrl: 'https://api.test/api',
        client: MockClient((req) async {
          enviado = jsonDecode(req.body) as Map<String, dynamic>;
          return _json({
            'ok': true,
            'avance': {
              ...enviado,
              'id_usuario': 2,
              'modulo': 'Fase 2',
            }
          });
        }),
      )..token = 'b' * 64;
      final a = await api.actualizarAvance(
          idAvance: 2,
          porcentaje: 80,
          estado: EstadoAvance.enProgreso,
          retroalimentacion: 'Bien');
      expect(enviado['estado'], 'En Progreso');
      expect(a.porcentaje, 80);
    });
  });

  group('DemoJudyApi', () {
    test('empleado solo ve sus avances y no puede editar', () async {
      final api = DemoJudyApi(latencia: Duration.zero);
      await api.login('emp-001', DemoJudyApi.passwordDemo);
      final avances = await api.avances();
      expect(avances, isNotEmpty);
      expect(avances.every((a) => a.idUsuario == 2), isTrue);
      expect(
        () => api.actualizarAvance(
            idAvance: 1, porcentaje: 5, estado: EstadoAvance.pendiente, retroalimentacion: ''),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 403)),
      );
    });

    test('gerencia aprueba solicitudes y edita avances', () async {
      final api = DemoJudyApi(latencia: Duration.zero);
      await api.login('GER-001', DemoJudyApi.passwordDemo);
      final pendientes = await api.usuariosPendientes();
      await api.resolverUsuario(pendientes.first.id, aprobar: true, rol: Rol.empleado);
      expect((await api.usuariosPendientes()).length, pendientes.length - 1);

      final editado = await api.actualizarAvance(
          idAvance: 2, porcentaje: 100, estado: EstadoAvance.completado, retroalimentacion: 'Listo');
      expect(editado.porcentaje, 100);
      expect((await api.avances(idUsuario: 2)).firstWhere((a) => a.id == 2).estado,
          EstadoAvance.completado);
    });

    test('credenciales incorrectas y chat sin datos personales', () async {
      final api = DemoJudyApi(latencia: Duration.zero);
      expect(() => api.login('EMP-001', 'mal'), throwsA(isA<ApiException>()));
      expect(DemoJudyApi.respuestaDemo('dame el correo de Juan'),
          contains('privacidad'));
      expect(DemoJudyApi.respuestaDemo('¿Qué es la NOM-009?'), contains('altura'));
    });
  });

  group('SessionController', () {
    test('login demo persiste token y restaurar lo recupera', () async {
      final store = MemoryTokenStore();
      JudyApi demo() => DemoJudyApi(latencia: Duration.zero);
      final s1 = SessionController(store: store, demoApiFactory: demo);
      await s1.entrarDemo(Rol.gerencia);
      expect(s1.autenticado, isTrue);
      expect(s1.esDemo, isTrue);
      expect(store.valor, startsWith(DemoJudyApi.prefijoToken));

      final s2 = SessionController(store: store, demoApiFactory: demo);
      await s2.restaurar();
      expect(s2.restaurado, isTrue);
      expect(s2.usuario?.esGerencia, isTrue);

      await s2.logout();
      expect(s2.autenticado, isFalse);
      expect(store.valor, isNull);
    });

    test('token rechazado (401) se borra al restaurar', () async {
      final store = MemoryTokenStore()..valor = 'c' * 64;
      final s = SessionController(
        store: store,
        realApiFactory: () => HttpJudyApi(
          baseUrl: 'https://api.test/api',
          client: MockClient((_) async =>
              _json({'ok': false, 'error': 'Sesión inválida o expirada.'}, 401)),
        ),
      );
      await s.restaurar();
      expect(s.autenticado, isFalse);
      expect(store.valor, isNull);
    });
  });
}
