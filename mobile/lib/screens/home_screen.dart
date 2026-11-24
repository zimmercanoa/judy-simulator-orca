import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../services/judy_api.dart';
import '../state/session.dart';
import '../widgets/common.dart';
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
  VersionInfo? _nuevaVersion;

  @override
  void initState() {
    super.initState();
    _buscarActualizacion();
  }

  /// Consulta api/version.php; si hay una versión más nueva, muestra un aviso.
  Future<void> _buscarActualizacion() async {
    final info = await context.read<SessionController>().api.ultimaVersion();
    if (!mounted || info == null) return;
    if (info.versionCode > AppConfig.appVersionCode) {
      setState(() => _nuevaVersion = info);
    }
  }

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
          PopupMenuButton<String>(
            tooltip: 'Mi cuenta',
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (v) {
              switch (v) {
                case 'privacidad':
                  abrirUrl(context, AppConfig.privacidadUrl);
                case 'eliminar':
                  _eliminarCuenta(context);
                case 'salir':
                  _confirmarSalida(context);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'privacidad',
                  child: ListTile(
                      leading: Icon(Icons.privacy_tip_outlined),
                      title: Text('Aviso de privacidad'))),
              PopupMenuItem(
                  value: 'eliminar',
                  child: ListTile(
                      leading: Icon(Icons.delete_forever_outlined),
                      title: Text('Eliminar mi cuenta'))),
              PopupMenuItem(
                  value: 'salir',
                  child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Cerrar sesión'))),
            ],
          ),
        ],
      ),
      body: Column(children: [
        if (_nuevaVersion != null)
          MaterialBanner(
            leading: const Icon(Icons.system_update),
            content: Text(
                'Hay una nueva versión (${_nuevaVersion!.version}). Descárgala para obtener mejoras y correcciones.'),
            actions: [
              TextButton(
                  onPressed: () => setState(() => _nuevaVersion = null),
                  child: const Text('Después')),
              FilledButton(
                  onPressed: () =>
                      abrirUrl(context, _nuevaVersion!.descargaUrl),
                  child: const Text('Descargar')),
            ],
          ),
        Expanded(
          child: IndexedStack(
              index: i, children: [for (final p in paginas) p.pantalla]),
        ),
      ]),
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

/// Diálogo de confirmación con contraseña para eliminar la cuenta.
Future<void> _eliminarCuenta(BuildContext context) async {
  final session = context.read<SessionController>();
  // El messenger de MaterialApp sobrevive al cambio Home -> Login.
  final messenger = ScaffoldMessenger.of(context);
  final password = await showDialog<String>(
    context: context,
    builder: (_) => const _DialogoEliminarCuenta(),
  );
  if (password == null || !context.mounted) return;
  try {
    await session.eliminarCuenta(password);
    messenger.showSnackBar(const SnackBar(
        content: Text('Tu cuenta y tus datos fueron eliminados.')));
  } catch (e) {
    if (context.mounted) mostrarSnack(context, mensajeError(e), error: true);
  }
}

class _DialogoEliminarCuenta extends StatefulWidget {
  const _DialogoEliminarCuenta();

  @override
  State<_DialogoEliminarCuenta> createState() => _DialogoEliminarCuentaState();
}

class _DialogoEliminarCuentaState extends State<_DialogoEliminarCuenta> {
  final _password = TextEditingController();
  bool _confirmo = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listo = _confirmo && _password.text.isNotEmpty;
    return AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, size: 40),
      title: const Text('Eliminar mi cuenta'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text(
              'Se borrarán definitivamente tu cuenta, tus datos personales y '
              'tu historial de avances VR. Esta acción no se puede deshacer.'),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Contraseña actual'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _confirmo,
            onChanged: (v) => setState(() => _confirmo = v ?? false),
            title: const Text('Entiendo que es permanente'),
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: listo ? () => Navigator.pop(context, _password.text) : null,
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}

class _Pagina {
  const _Pagina(this.titulo, this.icono, this.iconoActivo, this.pantalla);
  final String titulo;
  final IconData icono;
  final IconData iconoActivo;
  final Widget pantalla;
}
