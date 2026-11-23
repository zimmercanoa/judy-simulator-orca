import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judy_simulator/main.dart';
import 'package:judy_simulator/services/demo_judy_api.dart';
import 'package:judy_simulator/services/token_store.dart';
import 'package:judy_simulator/state/session.dart';

void main() {
  testWidgets('splash → login → modo demo empleado → dashboard', (tester) async {
    final session = SessionController(
      store: MemoryTokenStore(),
      demoApiFactory: () => DemoJudyApi(latencia: Duration.zero),
    );
    await tester.pumpWidget(JudyApp(session: session));
    expect(find.text('JuDy Simulator'), findsOneWidget); // splash

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);

    final botonEmpleado = find.widgetWithText(OutlinedButton, 'Empleado');
    await tester.ensureVisible(botonEmpleado);
    await tester.tap(botonEmpleado);
    await tester.pumpAndSettle();

    expect(find.text('Mi progreso'), findsWidgets);
    expect(find.text('Fase 1: Instalación (NOM-029)'), findsOneWidget);
    expect(find.text('DEMO'), findsOneWidget);
  });

  testWidgets('modo demo gerencia muestra solicitudes pendientes', (tester) async {
    final session = SessionController(
      store: MemoryTokenStore(),
      demoApiFactory: () => DemoJudyApi(latencia: Duration.zero),
    );
    await tester.pumpWidget(JudyApp(session: session));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    final botonGerencia = find.widgetWithText(OutlinedButton, 'Gerencia');
    await tester.ensureVisible(botonGerencia);
    await tester.tap(botonGerencia);
    await tester.pumpAndSettle();

    expect(find.text('Solicitudes'), findsOneWidget);
    expect(find.text('Solicitante Demo 1'), findsOneWidget);
  });
}
