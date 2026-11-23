import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/session.dart';
import '../utils/validadores.dart';
import '../widgets/common.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _form = GlobalKey<FormState>();
  final _matricula = TextEditingController();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _telefono = TextEditingController();
  final _password = TextEditingController();
  final _confirmar = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    for (final c in [_matricula, _nombre, _correo, _telefono, _password, _confirmar]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      final mensaje = await context.read<SessionController>().api.registro(
            matricula: _matricula.text.trim(),
            nombre: _nombre.text.trim(),
            correo: _correo.text.trim(),
            telefono: _telefono.text.trim(),
            password: _password.text,
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline, size: 40),
          title: const Text('Solicitud enviada'),
          content: Text(mensaje),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido')),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) mostrarSnack(context, mensajeError(e), error: true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esDemo = context.watch<SessionController>().esDemo;
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tu cuenta quedará pendiente hasta que gerencia la apruebe '
                  'y te asigne un rol.${esDemo ? ' (Modo demo)' : ''}',
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _matricula,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                      labelText: 'Matrícula *',
                      prefixIcon: Icon(Icons.badge_outlined)),
                  validator: validarMatricula,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nombre,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                      labelText: 'Nombre completo *',
                      prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => validarRequerido(v, 'tu nombre'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _correo,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Correo electrónico *',
                      prefixIcon: Icon(Icons.email_outlined)),
                  validator: validarCorreo,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefono,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone_outlined)),
                  validator: validarTelefono,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Contraseña * (mínimo 8)',
                      prefixIcon: Icon(Icons.lock_outline)),
                  validator: validarPassword,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmar,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Confirmar contraseña *',
                      prefixIcon: Icon(Icons.lock_reset)),
                  validator: (v) => v != _password.text
                      ? 'Las contraseñas no coinciden'
                      : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _cargando ? null : _registrar,
                  child: _cargando
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Text('Enviar solicitud'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
