// Vista de acceso. La validación visual ayuda antes de enviar el formulario.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controladores/sesion.dart';
import '../tema.dart';
import '../widgets/comunes.dart';
import 'recuperar_password.dart';

class Entrada extends StatefulWidget {
  const Entrada({super.key});
  @override
  State<Entrada> createState() => _EntradaState();
}

class _EntradaState extends State<Entrada> {
  final formulario = GlobalKey<FormState>();
  final correo = TextEditingController(),
      password = TextEditingController(),
      nombre = TextEditingController();
  bool registro = false, ocultar = true;

  @override
  void dispose() {
    correo.dispose();
    password.dispose();
    nombre.dispose();
    super.dispose();
  }

  Future<void> abrirRecuperacion() async {
    final actualizada = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RecuperarPassword(correoInicial: correo.text),
      ),
    );
    if (actualizada == true && mounted) {
      password.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada. Ya puedes iniciar sesión.')),
      );
    }
  }

  Widget bienvenida() => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/imagenes/naturaleza.webp', fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x33112F28), Color(0xDD112F28)],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(38),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Marca(clara: true),
              Spacer(),
              Text(
                'Hay historias\nque empiezan\ncon una escapada.',
                style: TextStyle(
                  fontFamily: 'Editorial',
                  color: Colors.white,
                  fontSize: 43,
                  height: 1.12,
                ),
              ),
              SizedBox(height: 22),
              Text(
                'Encuentra el viaje que se parece a ti.\nEl fin de semana te está esperando.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.7,
                ),
              ),
              SizedBox(height: 30),
              Row(
                children: [
                  Icon(Icons.place_outlined, color: Colors.white, size: 17),
                  SizedBox(width: 6),
                  Text(
                    'Hecho para descubrir México',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget campos(Sesion sesion) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: Form(
      key: formulario,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Marca(),
          const SizedBox(height: 38),
          Text(
            registro
                ? 'Tu próxima historia\nempieza aquí.'
                : 'Qué gusto\nverte por aquí.',
            style: const TextStyle(
              fontFamily: 'Editorial',
              fontSize: 36,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            registro
                ? 'Crea tu cuenta y encuentra una escapada a tu medida.'
                : 'Entra y cambia un fin de semana cualquiera por uno que recuerdes.',
            style: const TextStyle(color: gris, height: 1.7),
          ),
          const SizedBox(height: 24),
          if (registro) ...[
            TextFormField(
              controller: nombre,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Tu nombre',
                prefixIcon: Icon(Icons.person_outline),
              ),
              maxLength: 80,
              validator: (v) => v!.trim().isEmpty ? 'Escribe tu nombre.' : null,
            ),
            const SizedBox(height: 12),
          ],
          TextFormField(
            controller: correo,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.alternate_email),
            ),
            validator: (v) =>
                !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v!.trim())
                ? 'Escribe un correo válido.'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: password,
            obscureText: ocultar,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Contraseña',
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
            validator: (v) => v!.isEmpty
                ? 'Escribe tu contraseña.'
                : registro && (v.length < 12 || v.length > 128)
                ? 'Usa de 12 a 128 caracteres.'
                : null,
            onFieldSubmitted: (_) => enviar(sesion),
          ),
          const SizedBox(height: 18),
          if (sesion.error != null) ...[
            Mensaje(sesion.error!),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: sesion.trabajando ? null : () => enviar(sesion),
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              label: Text(
                sesion.trabajando
                    ? 'Preparando tu viaje…'
                    : registro
                    ? 'Crear mi cuenta'
                    : 'Entrar a mi escapada',
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (!registro)
            Center(
              child: TextButton(
                onPressed: sesion.trabajando ? null : abrirRecuperacion,
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
            ),
          Center(
            child: TextButton(
              onPressed: sesion.trabajando
                  ? null
                  : () => setState(() => registro = !registro),
              child: Text(
                registro
                    ? 'Ya tengo cuenta · Iniciar sesión'
                    : 'Soy nuevo · Crear una cuenta',
              ),
            ),
          ),
          if (sesion.demo && sesion.cuentasDemo != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(),
            ),
            const Text(
              'EXPLORA LA DEMOSTRACIÓN',
              style: TextStyle(fontSize: 10, letterSpacing: 1.6, color: gris),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: sesion.trabajando
                        ? null
                        : () => sesion.entrar(
                            sesion.cuentasDemo!['cliente'],
                            sesion.cuentasDemo!['password'],
                          ),
                    child: const Text('Soy viajero'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: sesion.trabajando
                        ? null
                        : () => sesion.entrar(
                            sesion.cuentasDemo!['admin'],
                            sesion.cuentasDemo!['password'],
                          ),
                    child: const Text('Administrar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );

  void enviar(Sesion sesion) {
    if (!sesion.trabajando && formulario.currentState!.validate()) {
      sesion.entrar(
        correo.text,
        password.text,
        nombre: registro ? nombre.text : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<Sesion>();
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final escritorio = constraints.maxWidth >= 960;
          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(escritorio ? 30 : 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1240),
                child: Row(
                  children: [
                    if (escritorio) ...[
                      Expanded(
                        child: SizedBox(height: 760, child: bienvenida()),
                      ),
                      const SizedBox(width: 70),
                    ],
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: escritorio ? 10 : 24,
                          ),
                          child: campos(sesion),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
