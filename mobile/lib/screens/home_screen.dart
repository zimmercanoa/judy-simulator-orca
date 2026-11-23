import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/session.dart';
import 'chat_screen.dart';
import 'contacto_screen.dart';
import 'dashboard_screen.dart';
import 'gerencia_screen.dart';
import 'normas_screen.dart';

/// Contenedor principal con navegación inferior según el rol.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final usuario = session.usuario!;
    final esGerencia = usuario.esGerencia;

    final paginas = <_Pagina>[
      if (esGerencia)
        const _Pagina('Gerencia', Icons.admin_panel_settings_outlined,
            Icons.admin_panel_settings, GerenciaScreen())
      else
        const _Pagina('Mi progreso', Icons.insights_outlined, Icons.insights,
            DashboardScreen()),
      const _Pagina('Asistente', Icons.smart_toy_outlined, Icons.smart_toy,
          ChatScreen()),
      const _Pagina('Normas', Icons.menu_book_outlined, Icons.menu_book,
          NormasScreen()),
      const _Pagina('Contacto', Icons.mail_outline, Icons.mail, ContactoScreen()),
    ];
    final i = _indice.clamp(0, paginas.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(paginas[i].titulo),
          Text('${usuario.nombreCompleto} · ${usuario.rol.etiqueta}',
              style: Theme.of(context).textTheme.bodySmall),
        ]),
        actions: [
          if (session.esDemo)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Chip(label: Text('DEMO'), visualDensity: VisualDensity.compact),
            ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmarSalida(context),
          ),
        ],
      ),
      body: IndexedStack(
          index: i, children: [for (final p in paginas) p.pantalla]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        onDestinationSelected: (n) => setState(() => _indice = n),
        destinations: [
          for (final p in paginas)
            NavigationDestination(
                icon: Icon(p.icono),
                selectedIcon: Icon(p.iconoActivo),
                label: p.titulo),
        ],
      ),
    );
  }

  Future<void> _confirmarSalida(BuildContext context) async {
    final session = context.read<SessionController>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas salir de tu cuenta?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salir')),
        ],
      ),
    );
    if (ok == true) await session.logout();
  }
}

class _Pagina {
  const _Pagina(this.titulo, this.icono, this.iconoActivo, this.pantalla);
  final String titulo;
  final IconData icono;
  final IconData iconoActivo;
  final Widget pantalla;
}
