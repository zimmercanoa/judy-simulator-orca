import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/token_store.dart';
import 'state/session.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(JudyApp(session: SessionController(store: SecureTokenStore())));
}

class JudyApp extends StatelessWidget {
  const JudyApp({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: session,
      child: MaterialApp(
        title: 'JuDy Simulator',
        debugShowCheckedModeBanner: false,
        theme: judyTheme(Brightness.light),
        darkTheme: judyTheme(Brightness.dark),
        home: const _RaizSesion(),
      ),
    );
  }
}

/// Decide la pantalla principal según el estado de la sesión.
class _RaizSesion extends StatelessWidget {
  const _RaizSesion();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SessionController>();
    if (!s.restaurado) return const SplashScreen();
    return s.autenticado ? const HomeScreen() : const LoginScreen();
  }
}
