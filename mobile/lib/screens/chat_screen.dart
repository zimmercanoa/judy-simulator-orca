import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/session.dart';
import '../theme.dart';
import '../widgets/common.dart';

class _Mensaje {
  const _Mensaje(this.texto, {required this.propio, this.error = false});
  final String texto;
  final bool propio;
  final bool error;
}

/// Asistente virtual (proxy a Gemini en el servidor, o respuestas demo).
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with AutomaticKeepAliveClientMixin {
  final _entrada = TextEditingController();
  final _scroll = ScrollController();
  final List<_Mensaje> _mensajes = [
    const _Mensaje(
        '¡Hola! Soy el asistente de JuDy Simulator. Pregúntame sobre las '
        'normas NOM-009 y NOM-029, los módulos VR o el registro. '
        'Por privacidad no comparto datos personales.',
        propio: false),
  ];
  bool _enviando = false;

  static const _sugerencias = [
    '¿Qué exige la NOM-009?',
    '¿Qué es el bloqueo y etiquetado?',
    '¿Cómo se aprueba mi cuenta?',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _entrada.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _enviar([String? texto]) async {
    final msg = (texto ?? _entrada.text).trim();
    if (msg.isEmpty || _enviando) return;
    if (msg.length > 1000) {
      mostrarSnack(context, 'Máximo 1000 caracteres.', error: true);
      return;
    }
    _entrada.clear();
    setState(() {
      _mensajes.add(_Mensaje(msg, propio: true));
      _enviando = true;
    });
    _bajar();
    try {
      final r = await context.read<SessionController>().api.chat(msg);
      if (mounted) setState(() => _mensajes.add(_Mensaje(r, propio: false)));
    } catch (e) {
      if (!mounted) return;
      manejarErrorSesion(context, e);
      setState(() =>
          _mensajes.add(_Mensaje(mensajeError(e), propio: false, error: true)));
    } finally {
      if (mounted) setState(() => _enviando = false);
      _bajar();
    }
  }

  void _bajar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final esquema = Theme.of(context).colorScheme;
    return Column(children: [
      Expanded(
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.all(12),
          itemCount: _mensajes.length + (_enviando ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == _mensajes.length) {
              return const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5)),
                ),
              );
            }
            final m = _mensajes[i];
            return Align(
              alignment: m.propio ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.8),
                decoration: BoxDecoration(
                  color: m.error
                      ? esquema.errorContainer
                      : m.propio
                          ? JudyColors.naranja
                          : esquema.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: m.propio
                      ? null
                      : Border.all(color: esquema.outlineVariant),
                ),
                child: SelectableText(
                  m.texto,
                  style: TextStyle(
                      color: m.error
                          ? esquema.onErrorContainer
                          : m.propio
                              ? Colors.white
                              : esquema.onSurface),
                ),
              ),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Tus preguntas se envían a Google Gemini para generar la respuesta. '
          'No escribas datos personales.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ),
      if (_mensajes.length == 1)
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final s in _sugerencias)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(label: Text(s), onPressed: () => _enviar(s)),
                ),
            ],
          ),
        ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _entrada,
                minLines: 1,
                maxLines: 4,
                maxLength: 1000,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _enviar(),
                decoration: const InputDecoration(
                  hintText: 'Escribe tu pregunta…',
                  counterText: '',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Enviar',
              onPressed: _enviando ? null : _enviar,
              icon: const Icon(Icons.send),
            ),
          ]),
        ),
      ),
    ]);
  }
}
