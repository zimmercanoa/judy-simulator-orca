import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/usuario.dart';
import '../services/judy_api.dart';
import '../state/session.dart';
import '../widgets/common.dart';
import 'contacto_screen.dart';
import 'normas_screen.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _matricula = TextEditingController();
  final _password = TextEditingController();
  bool _cargando = false;
  bool _verPassword = false;
  ApiException? _error;

  @override
  void dispose() {
    _matricula.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    await _ejecutar(() => context
        .read<SessionController>()
        .login(_matricula.text, _password.text));
  }

  Future<void> _entrarDemo(Rol rol) =>
      _ejecutar(() => context.read<SessionController>().entrarDemo(rol));

  Future<void> _ejecutar(Future<void> Function() accion) async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await accion();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            const ApiException('Ocurrió un error inesperado. Inténtalo de nuevo.'));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final tema = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: JudyLogo(alto: 110)),
                    const SizedBox(height: 16),
                    Text('Iniciar sesión',
                        textAlign: TextAlign.center,
                        style: tema.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      session.esDemo
                          ? 'Modo demo: datos simulados, sin servidor'
                          : 'Servidor: ${AppConfig.apiBaseUrl}',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _matricula,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                          labelText: 'Matrícula',
                          prefixIcon: Icon(Icons.badge_outlined)),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Escribe tu matrícula'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: !_verPassword,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _cargando ? null : _entrar(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _verPassword ? 'Ocultar' : 'Mostrar',
                          icon: Icon(_verPassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _verPassword = !_verPassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Escribe tu contraseña'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _ErrorLogin(error: _error!, onDemo: () => _entrarDemo(Rol.empleado)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _cargando ? null : _entrar,
                      child: _cargando
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white))
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _cargando
                          ? null
                          : () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const RegistroScreen())),
                      child: const Text('¿No tienes cuenta? Regístrate'),
                    ),
                    const Divider(height: 32),
                    Text('Probar sin servidor (modo demo)',
                        textAlign: TextAlign.center,
                        style: tema.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _cargando ? null : () => _entrarDemo(Rol.empleado),
                          icon: const Icon(Icons.engineering),
                          label: const Text('Empleado'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _cargando ? null : () => _entrarDemo(Rol.gerencia),
                          icon: const Icon(Icons.admin_panel_settings),
                          label: const Text('Gerencia'),
                        ),
                      ),
                    ]),
                    if (!AppConfig.forceDemo)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Usar datos simulados'),
                        subtitle: const Text(
                            'Demo: EMP-001 o GER-001 / contraseña demo1234'),
                        value: session.esDemo,
                        onChanged: _cargando
                            ? null
                            : (v) {
                                setState(() => _error = null);
                                session.usarDemo(v);
                              },
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const NormasScreen(
                                      conAppBar: true))),
                          icon: const Icon(Icons.menu_book_outlined),
                          label: const Text('Normas STPS'),
                        ),
                        TextButton.icon(
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const ContactoScreen(
                                      conAppBar: true))),
                          icon: const Icon(Icons.mail_outline),
                          label: const Text('Contacto'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorLogin extends StatelessWidget {
  const _ErrorLogin({required this.error, required this.onDemo});
  final ApiException error;
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Card(
      color: esquema.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(error.antiBot ? Icons.shield_outlined : Icons.error_outline,
                color: esquema.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(error.mensaje,
                  style: TextStyle(color: esquema.onErrorContainer)),
            ),
          ]),
          if (error.antiBot || error.status == null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                  onPressed: onDemo, child: const Text('Usar modo demo')),
            ),
        ]),
      ),
    );
  }
}
