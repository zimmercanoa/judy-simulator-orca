import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/avance.dart';
import '../state/session.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Dashboard del empleado: progreso por módulo VR.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Avance>? _avances;
  String? _error;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final datos = await context.read<SessionController>().api.avances();
      if (mounted) setState(() => _avances = datos);
    } catch (e) {
      if (!mounted) return;
      manejarErrorSesion(context, e);
      setState(() => _error = mensajeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando && _avances == null) {
      return const CargandoView(texto: 'Cargando tu progreso…');
    }
    if (_error != null && _avances == null) {
      return ErrorView(mensaje: _error!, onReintentar: _cargar);
    }
    final avances = _avances ?? const <Avance>[];
    final completados =
        avances.where((a) => a.estado == EstadoAvance.completado).length;

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _Resumen(
              promedio: promedioAvance(avances),
              completados: completados,
              total: avances.length),
          const SizedBox(height: 12),
          Text('Módulos de realidad virtual',
              style: Theme.of(context).textTheme.titleMedium),
          if (avances.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Aún no tienes módulos asignados. Gerencia registrará tu '
                'avance cuando completes tu primera sesión VR.',
                textAlign: TextAlign.center,
              ),
            )
          else
            for (final a in avances) AvanceCard(avance: a),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen(
      {required this.promedio, required this.completados, required this.total});
  final int promedio;
  final int completados;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: JudyColors.azulMarino,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(fit: StackFit.expand, children: [
              CircularProgressIndicator(
                value: promedio / 100,
                strokeWidth: 8,
                backgroundColor: Colors.white24,
              ),
              Center(
                child: Text('$promedio%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Avance general',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              Text('$completados de $total módulos completados',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text('NOM-009 · NOM-029 STPS',
                  style: TextStyle(color: JudyColors.naranja)),
            ]),
          ),
        ]),
      ),
    );
  }
}
