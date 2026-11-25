import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controladores/sesion.dart';
import '../widgets/comunes.dart';

class RecuperarPassword extends StatefulWidget {
  final String correoInicial;

  const RecuperarPassword({super.key, required this.correoInicial});

  @override
  State<RecuperarPassword> createState() => _RecuperarPasswordState();
}

class _RecuperarPasswordState extends State<RecuperarPassword> {
  final formulario = GlobalKey<FormState>();
  late final TextEditingController correo;
  final codigo = TextEditingController();
  final password = TextEditingController();
  final confirmacion = TextEditingController();
  String? solicitudId;
  String? error;
  bool trabajando = false, ocultar = true, puedeReenviar = false;
  Timer? esperaReenvio;

  @override
  void initState() {
    super.initState();
    correo = TextEditingController(text: widget.correoInicial.trim());
  }

  @override
  void dispose() {
    esperaReenvio?.cancel();
    correo.dispose();
    codigo.dispose();
    password.dispose();
    confirmacion.dispose();
    super.dispose();
  }

  Future<void> solicitar() async {
    if (trabajando ||
        (solicitudId == null && !formulario.currentState!.validate())) {
      return;
    }
    setState(() {
      trabajando = true;
      error = null;
    });
    try {
      final id = await context.read<Sesion>().solicitarRecuperacion(correo.text);
      if (!mounted) return;
      codigo.clear();
      setState(() {
        solicitudId = id;
        puedeReenviar = false;
      });
      esperaReenvio?.cancel();
      esperaReenvio = Timer(const Duration(seconds: 60), () {
        if (mounted) setState(() => puedeReenviar = true);
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => trabajando = false);
    }
  }

  Future<void> confirmar() async {
    if (trabajando || !formulario.currentState!.validate()) return;
    setState(() {
      trabajando = true;
      error = null;
    });
    try {
      await context.read<Sesion>().confirmarRecuperacion(
        correo: correo.text,
        solicitudId: solicitudId!,
        codigo: codigo.text,
        password: password.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => trabajando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final codigoSolicitado = solicitudId != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: formulario,
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    codigoSolicitado ? 'Revisa tu correo' : 'Recupera tu acceso',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  if (!codigoSolicitado) ...[
                    const Text(
                      'Escribe el correo de tu cuenta para pedir un código.',
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: correo,
                      enabled: !trabajando,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: (valor) => RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(valor!.trim())
                          ? null
                          : 'Escribe un correo válido.',
                      onFieldSubmitted: (_) => solicitar(),
                    ),
                  ] else ...[
                    Mensaje(
                      'Si el correo está registrado y puede recibir un código, '
                      'te llegará un mensaje a ${correo.text.trim()}. '
                      'El código dura 10 minutos.',
                      esError: false,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: codigo,
                      enabled: !trabajando,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Código de 6 dígitos',
                        prefixIcon: Icon(Icons.key_outlined),
                      ),
                      validator: (valor) => valor!.length == 6
                          ? null
                          : 'Escribe los 6 dígitos del código.',
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: password,
                      enabled: !trabajando,
                      obscureText: ocultar,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Nueva contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: ocultar ? 'Mostrar contraseña' : 'Ocultar contraseña',
                          onPressed: () => setState(() => ocultar = !ocultar),
                          icon: Icon(
                            ocultar
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (valor) {
                        final longitud = valor?.length ?? 0;
                        return longitud >= 12 && longitud <= 128
                            ? null
                            : 'Usa de 12 a 128 caracteres.';
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: confirmacion,
                      enabled: !trabajando,
                      obscureText: ocultar,
                      decoration: const InputDecoration(
                        labelText: 'Repite la nueva contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (valor) => valor == password.text
                          ? null
                          : 'Las contraseñas deben coincidir.',
                      onFieldSubmitted: (_) => confirmar(),
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Mensaje(error!),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: trabajando
                        ? null
                        : codigoSolicitado
                        ? confirmar
                        : solicitar,
                    child: Text(
                      trabajando
                          ? 'Espera un momento…'
                          : codigoSolicitado
                          ? 'Actualizar contraseña'
                          : 'Enviar código',
                    ),
                  ),
                  if (codigoSolicitado)
                    TextButton(
                      onPressed: puedeReenviar && !trabajando ? solicitar : null,
                      child: Text(
                        puedeReenviar
                            ? 'Reenviar código'
                            : 'Reenvío disponible en un minuto',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
