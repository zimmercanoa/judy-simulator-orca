import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/avance.dart';
import '../models/usuario.dart';
import '../state/session.dart';
import '../widgets/common.dart';

/// Panel de gerencia: solicitudes de cuenta y edición de avances.
class GerenciaScreen extends StatelessWidget {
  const GerenciaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Column(children: [
        TabBar(tabs: [
          Tab(icon: Icon(Icons.how_to_reg_outlined), text: 'Solicitudes'),
          Tab(icon: Icon(Icons.view_in_ar_outlined), text: 'Avances VR'),
        ]),
        Expanded(
          child: TabBarView(children: [_SolicitudesTab(), _AvancesTab()]),
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------------
// Solicitudes pendientes
// ------------------------------------------------------------------
class _SolicitudesTab extends StatefulWidget {
  const _SolicitudesTab();

  @override
  State<_SolicitudesTab> createState() => _SolicitudesTabState();
}

class _SolicitudesTabState extends State<_SolicitudesTab>
    with AutomaticKeepAliveClientMixin {
  List<UsuarioPendiente>? _lista;
  String? _error;
  final Set<int> _procesando = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _error = null);
    try {
      final datos =
          await context.read<SessionController>().api.usuariosPendientes();
      if (mounted) setState(() => _lista = datos);
    } catch (e) {
      if (!mounted) return;
      manejarErrorSesion(context, e);
      setState(() => _error = mensajeError(e));
    }
  }

  Future<void> _resolver(UsuarioPendiente u, bool aprobar) async {
    Rol? rol;
    if (aprobar) {
      rol = await showModalBottomSheet<Rol>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('Asignar rol a ${u.nombreCompleto}',
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            ListTile(
              leading: const Icon(Icons.engineering),
              title: const Text('Empleado'),
              subtitle: const Text('Ve su propio progreso VR'),
              onTap: () => Navigator.pop(ctx, Rol.empleado),
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Gerencia'),
              subtitle: const Text('Aprueba cuentas y edita avances'),
              onTap: () => Navigator.pop(ctx, Rol.gerencia),
            ),
          ]),
        ),
      );
      if (rol == null) return;
    } else {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rechazar solicitud'),
          content: Text('¿Rechazar la cuenta de ${u.nombreCompleto} (${u.matricula})?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Rechazar')),
          ],
        ),
      );
      if (ok != true) return;
    }
    if (!mounted) return;

    setState(() => _procesando.add(u.id));
    try {
      await context
          .read<SessionController>()
          .api
          .resolverUsuario(u.id, aprobar: aprobar, rol: rol);
      if (!mounted) return;
      setState(() => _lista?.removeWhere((p) => p.id == u.id));
      mostrarSnack(context,
          aprobar ? '${u.matricula} aprobado como ${rol!.etiqueta}' : '${u.matricula} rechazado');
    } catch (e) {
      if (!mounted) return;
      manejarErrorSesion(context, e);
      mostrarSnack(context, mensajeError(e), error: true);
    } finally {
      if (mounted) setState(() => _procesando.remove(u.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_lista == null && _error == null) return const CargandoView();
    if (_lista == null) return ErrorView(mensaje: _error!, onReintentar: _cargar);
    final lista = _lista!;

    return RefreshIndicator(
      onRefresh: _cargar,
      child: lista.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 80),
                Icon(Icons.inbox_outlined, size: 56),
                SizedBox(height: 12),
                Text('No hay solicitudes pendientes.',
                    textAlign: TextAlign.center),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: lista.length,
              itemBuilder: (context, i) {
                final u = lista[i];
                final ocupado = _procesando.contains(u.id);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                              child: Icon(Icons.person_outline)),
                          title: Text(u.nombreCompleto),
                          subtitle: Text([u.matricula, u.email]
                              .where((s) => s.isNotEmpty)
                              .join(' · ')),
                        ),
                        if (ocupado)
                          const LinearProgressIndicator()
                        else
                          Row(children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _resolver(u, false),
                                icon: const Icon(Icons.close),
                                label: const Text('Rechazar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _resolver(u, true),
                                icon: const Icon(Icons.check),
                                label: const Text('Aprobar'),
                              ),
                            ),
                          ]),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ------------------------------------------------------------------
// Avances de todos los empleados
// ------------------------------------------------------------------
class _AvancesTab extends StatefulWidget {
  const _AvancesTab();

  @override
  State<_AvancesTab> createState() => _AvancesTabState();
}

class _AvancesTabState extends State<_AvancesTab>
    with AutomaticKeepAliveClientMixin {
  List<Avance>? _avances;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _error = null);
    try {
      final datos = await context.read<SessionController>().api.avances();
      if (mounted) setState(() => _avances = datos);
    } catch (e) {
      if (!mounted) return;
      manejarErrorSesion(context, e);
      setState(() => _error = mensajeError(e));
    }
  }

  Future<void> _editar(Avance a) async {
    final actualizado = await showModalBottomSheet<Avance>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => EditarAvanceSheet(avance: a),
    );
    if (actualizado != null && mounted) {
      setState(() {
        final i = _avances!.indexWhere((x) => x.id == actualizado.id);
        if (i >= 0) _avances![i] = actualizado;
      });
      mostrarSnack(context, 'Avance actualizado');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_avances == null && _error == null) return const CargandoView();
    if (_avances == null) {
      return ErrorView(mensaje: _error!, onReintentar: _cargar);
    }
    final avances = _avances!;
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        padding: const EdgeInsets.all(12),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (avances.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Text('Todavía no hay avances registrados.',
                  textAlign: TextAlign.center),
            ),
          for (final a in avances)
            AvanceCard(avance: a, mostrarUsuario: true, onTap: () => _editar(a)),
        ],
      ),
    );
  }
}

/// Formulario para editar porcentaje, estado y retroalimentación.
class EditarAvanceSheet extends StatefulWidget {
  const EditarAvanceSheet({super.key, required this.avance});
  final Avance avance;

  @override
  State<EditarAvanceSheet> createState() => _EditarAvanceSheetState();
}

class _EditarAvanceSheetState extends State<EditarAvanceSheet> {
  late double _porcentaje = widget.avance.porcentaje.toDouble();
  late EstadoAvance _estado = widget.avance.estado;
  late final _retro =
      TextEditingController(text: widget.avance.retroalimentacion);
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _retro.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final r = await context.read<SessionController>().api.actualizarAvance(
            idAvance: widget.avance.id,
            porcentaje: _porcentaje.round(),
            estado: _estado,
            retroalimentacion: _retro.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(r);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = mensajeError(e);
        _guardando = false;
      });
      manejarErrorSesion(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.avance;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(a.modulo, style: Theme.of(context).textTheme.titleLarge),
            if (a.nombreCompleto != null)
              Text('${a.nombreCompleto} · ${a.matricula ?? ''}'),
            const SizedBox(height: 16),
            Text('Porcentaje: ${_porcentaje.round()}%'),
            Slider(
              value: _porcentaje,
              min: 0,
              max: 100,
              divisions: 20,
              label: '${_porcentaje.round()}%',
              onChanged: _guardando
                  ? null
                  : (v) => setState(() {
                        _porcentaje = v;
                        if (v >= 100) _estado = EstadoAvance.completado;
                      }),
            ),
            const SizedBox(height: 8),
            SegmentedButton<EstadoAvance>(
              segments: [
                for (final e in EstadoAvance.values)
                  ButtonSegment(value: e, label: Text(e.api)),
              ],
              selected: {_estado},
              onSelectionChanged: _guardando
                  ? null
                  : (s) => setState(() => _estado = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _retro,
              maxLines: 4,
              maxLength: 2000,
              enabled: !_guardando,
              decoration: const InputDecoration(
                  labelText: 'Retroalimentación', alignLabelWithHint: true),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }
}
