import 'package:flutter/material.dart';

import '../theme.dart';

class _Seccion {
  const _Seccion(this.titulo, this.puntos, {this.icono = Icons.check_circle_outline});
  final String titulo;
  final List<String> puntos;
  final IconData icono;
}

class _Norma {
  const _Norma(this.clave, this.nombre, this.resumen, this.icono, this.secciones);
  final String clave;
  final String nombre;
  final String resumen;
  final IconData icono;
  final List<_Seccion> secciones;
}

const _normas = [
  _Norma(
    'NOM-009-STPS-2011',
    'Condiciones de seguridad para realizar trabajos en altura',
    'Aplica a actividades a 1.80 m o más sobre el nivel de referencia, como la '
        'instalación de paneles en techos y estructuras.',
    Icons.height,
    [
      _Seccion('Antes de subir', [
        'Analizar las condiciones del lugar: altura, clima, superficies frágiles y bordes sin protección.',
        'Contar con autorización por escrito y personal capacitado para trabajos en altura.',
        'Inspeccionar arnés, líneas de vida, conectores y puntos de anclaje antes de cada uso.',
      ]),
      _Seccion('Sistemas de protección', [
        'Sistema personal para detención de caídas: arnés de cuerpo completo, línea de vida y anclaje certificado.',
        'Sistemas de restricción o posicionamiento cuando aplique.',
        'Andamios, plataformas de elevación o escaleras en buen estado y bien asentados.',
        'Delimitar y señalizar el área inferior para proteger a terceros.',
      ], icono: Icons.shield_outlined),
      _Seccion('Emergencias', [
        'Plan de atención a emergencias y rescate de trabajadores suspendidos.',
        'Botiquín y personal con conocimientos de primeros auxilios.',
        'Vigilancia de la salud de los trabajadores que realizan trabajos en altura.',
      ], icono: Icons.emergency_outlined),
    ],
  ),
  _Norma(
    'NOM-029-STPS-2011',
    'Mantenimiento de las instalaciones eléctricas en los centros de trabajo',
    'Define condiciones de seguridad para el mantenimiento de instalaciones '
        'eléctricas, incluidas las de sistemas fotovoltaicos.',
    Icons.electrical_services,
    [
      _Seccion('Planeación', [
        'Diagrama unifilar actualizado y procedimientos de seguridad por escrito.',
        'Análisis de riesgos de la actividad y autorización por escrito del personal.',
        'Capacitación del personal según la tarea que realiza.',
      ]),
      _Seccion('Trabajo seguro', [
        'Des-energizar, aplicar bloqueo y etiquetado (candados y tarjetas) antes de intervenir.',
        'Verificar la ausencia de tensión con un equipo probado; los paneles generan energía con luz solar.',
        'Colocar puesta a tierra temporal y delimitar la zona de trabajo.',
        'Usar equipo de protección personal dieléctrico y herramientas aisladas.',
      ], icono: Icons.lock_outline),
      _Seccion('Emergencias', [
        'Plan de atención a emergencias por choque eléctrico, quemaduras o arco eléctrico.',
        'Medios para rescatar y atender a un trabajador accidentado.',
      ], icono: Icons.emergency_outlined),
    ],
  ),
];

/// Información de las normas STPS cubiertas por los módulos VR.
class NormasScreen extends StatelessWidget {
  const NormasScreen({super.key, this.conAppBar = false});

  /// `true` cuando se abre desde el login (fuera del Home).
  final bool conAppBar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final lista = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Los módulos de JuDy Simulator entrenan en realidad virtual la '
          'instalación y el mantenimiento seguro de paneles fotovoltaicos '
          'conforme a estas normas de la STPS.',
          style: tema.textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        for (final n in _normas)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: JudyColors.naranja,
                foregroundColor: Colors.white,
                child: Icon(n.icono),
              ),
              title: Text(n.clave,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(n.nombre),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.resumen, style: tema.textTheme.bodyMedium),
                for (final s in n.secciones) ...[
                  const SizedBox(height: 12),
                  Text(s.titulo,
                      style: tema.textTheme.titleSmall?.copyWith(
                          color: JudyColors.naranja,
                          fontWeight: FontWeight.bold)),
                  for (final p in s.puntos)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(s.icono, size: 18, color: tema.colorScheme.secondary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(p)),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Resumen informativo con fines de capacitación. Consulta siempre el '
          'texto oficial publicado en el Diario Oficial de la Federación.',
          style: tema.textTheme.bodySmall,
        ),
      ],
    );

    if (!conAppBar) return lista;
    return Scaffold(appBar: AppBar(title: const Text('Normas STPS')), body: lista);
  }
}
