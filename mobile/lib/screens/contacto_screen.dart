import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../state/session.dart';
import '../utils/validadores.dart';
import '../widgets/common.dart';

/// Formulario de contacto (envía por correo desde el servidor).
class ContactoScreen extends StatefulWidget {
  const ContactoScreen({super.key, this.conAppBar = false});
  final bool conAppBar;

  @override
  State<ContactoScreen> createState() => _ContactoScreenState();
}

class _ContactoScreenState extends State<ContactoScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _mensaje = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _mensaje.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      final r = await context.read<SessionController>().api.contacto(
            nombre: _nombre.text.trim(),
            correo: _correo.text.trim(),
            mensaje: _mensaje.text.trim(),
          );
      if (!mounted) return;
      _mensaje.clear();
      mostrarSnack(context, r);
    } catch (e) {
      if (mounted) mostrarSnack(context, mensajeError(e), error: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _abrirWeb() async {
    final ok = await launchUrl(Uri.parse(AppConfig.webUrl),
        mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      mostrarSnack(context, 'No se pudo abrir el navegador.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contenido = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('¿Dudas sobre la capacitación o tu cuenta? Escríbenos.',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombre,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => validarRequerido(v, 'tu nombre'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _correo,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'Correo', prefixIcon: Icon(Icons.email_outlined)),
              validator: validarCorreo,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mensaje,
              maxLines: 5,
              maxLength: 3000,
              decoration: const InputDecoration(
                  labelText: 'Mensaje', alignLabelWithHint: true),
              validator: (v) => validarRequerido(v, 'tu mensaje'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _enviando ? null : _enviar,
              icon: _enviando
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
              label: const Text('Enviar mensaje'),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _abrirWeb,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Abrir portal web de JuDy Simulator'),
            ),
          ],
        ),
      ),
    );
    if (!widget.conAppBar) return contenido;
    return Scaffold(appBar: AppBar(title: const Text('Contacto')), body: contenido);
  }
}
