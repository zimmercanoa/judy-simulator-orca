import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/session.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Pantalla de bienvenida: muestra el logo mientras se restaura la sesión.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Duración mínima para que el logo sea visible.
    context
        .read<SessionController>()
        .restaurar(minimo: const Duration(milliseconds: 1200));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JudyColors.azulMarino,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const JudyLogo(alto: 140),
          const SizedBox(height: 24),
          Text('JuDy Simulator',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Capacitación VR en seguridad fotovoltaica',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 32),
          const CircularProgressIndicator(),
        ]),
      ),
    );
  }
}
