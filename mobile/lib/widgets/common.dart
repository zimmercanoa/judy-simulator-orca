import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/avance.dart';
import '../services/judy_api.dart';
import '../state/session.dart';
import '../theme.dart';

/// Texto amigable para cualquier error.
String mensajeError(Object e) =>
    e is ApiException ? e.mensaje : 'Ocurrió un error inesperado.';

/// Si la API respondió 401, cierra la sesión local (vuelve al login).
void manejarErrorSesion(BuildContext context, Object e) {
  if (e is ApiException && e.noAutorizado) {
    context.read<SessionController>().sesionExpirada();
  }
}

void mostrarSnack(BuildContext context, String texto, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ));
}

/// Abre una URL https en el navegador del sistema.
Future<void> abrirUrl(BuildContext context, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    mostrarSnack(context, 'No se pudo abrir el navegador.', error: true);
  }
}

/// Logo del sitio según el brillo del tema.
class JudyLogo extends StatelessWidget {
  const JudyLogo({super.key, this.alto = 96});
  final double alto;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        oscuro ? 'assets/img/logo_oscuro.jpg' : 'assets/img/logo_blanco.jpg',
        height: alto,
        fit: BoxFit.contain,
        semanticLabel: 'Logo JuDy Simulator',
      ),
    );
  }
}

class CargandoView extends StatelessWidget {
  const CargandoView({super.key, this.texto = 'Cargando…'});
  final String texto;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(texto),
        ]),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.mensaje, this.onReintentar});
  final String mensaje;
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            if (onReintentar != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ]),
        ),
      );
}

Color colorEstado(EstadoAvance e) => switch (e) {
      EstadoAvance.completado => JudyColors.exito,
      EstadoAvance.enProgreso => JudyColors.naranja,
      EstadoAvance.pendiente => JudyColors.aviso,
    };

class EstadoChip extends StatelessWidget {
  const EstadoChip(this.estado, {super.key});
  final EstadoAvance estado;

  @override
  Widget build(BuildContext context) {
    final c = colorEstado(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c),
      ),
      child: Text(estado.api,
          style:
              TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

/// Tarjeta con barra de progreso de un módulo VR.
class AvanceCard extends StatelessWidget {
  const AvanceCard(
      {super.key, required this.avance, this.mostrarUsuario = false, this.onTap});

  final Avance avance;
  final bool mostrarUsuario;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mostrarUsuario && avance.nombreCompleto != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${avance.nombreCompleto} · ${avance.matricula ?? ''}',
                    style: tema.textTheme.labelMedium
                        ?.copyWith(color: tema.colorScheme.secondary),
                  ),
                ),
              Row(children: [
                const Icon(Icons.view_in_ar, color: JudyColors.naranja),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(avance.modulo,
                      style: tema.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                if (onTap != null) const Icon(Icons.edit, size: 18),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: avance.fraccion,
                      minHeight: 10,
                      color: colorEstado(avance.estado),
                      backgroundColor: tema.colorScheme.outlineVariant,
                      semanticsLabel: 'Progreso de ${avance.modulo}',
                      semanticsValue: '${avance.porcentaje}%',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${avance.porcentaje}%',
                    style: tema.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 10),
              EstadoChip(avance.estado),
              if (avance.retroalimentacion.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.comment_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(avance.retroalimentacion,
                          style: tema.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
