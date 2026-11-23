import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:judy_simulator/config.dart';

void main() {
  test('AppConfig.appVersion coincide con version: de pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final m = RegExp(r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$', multiLine: true)
        .firstMatch(pubspec);
    expect(m, isNotNull, reason: 'pubspec.yaml debe tener version: X.Y.Z+N');
    expect(AppConfig.appVersion, m!.group(1));
    expect(AppConfig.appVersionCode, int.parse(m.group(2)!));
  });

  test('descargas/app.json del sitio usa la misma versión', () {
    final f = File('../descargas/app.json');
    if (!f.existsSync()) return; // fuera del repo completo
    final json = f.readAsStringSync();
    expect(json, contains('"version": "${AppConfig.appVersion}"'));
    expect(json, contains('"version_code": ${AppConfig.appVersionCode}'));
  });
}
