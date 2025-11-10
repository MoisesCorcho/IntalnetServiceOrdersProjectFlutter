import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _deviceName;
  bool _isFetchingDeviceName = true;

  @override
  void initState() {
    super.initState();
    _resolveDeviceName();
  }

  Future<void> _resolveDeviceName() async {
    const fallback = 'flutter_app';
    final plugin = DeviceInfoPlugin();
    String? resolvedName;

    try {
      if (kIsWeb) {
        resolvedName = 'web_browser';
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            resolvedName = (await plugin.androidInfo).model;
            break;
          case TargetPlatform.iOS:
            final info = await plugin.iosInfo;
            resolvedName = info.name;
            break;
          case TargetPlatform.macOS:
            resolvedName = (await plugin.macOsInfo).computerName;
            break;
          case TargetPlatform.windows:
            resolvedName = (await plugin.windowsInfo).computerName;
            break;
          case TargetPlatform.linux:
            resolvedName = (await plugin.linuxInfo).name;
            break;
          case TargetPlatform.fuchsia:
            resolvedName = fallback;
            break;
        }
      }
    } catch (_) {
      resolvedName = fallback;
    }

    if (!mounted) return;

    setState(() {
      _deviceName =
          (resolvedName == null || resolvedName.trim().isEmpty) ? fallback : resolvedName.trim();
      _isFetchingDeviceName = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage &&
            current.errorMessage != null,
        listener: (context, state) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth > 520 ? 420.0 : double.infinity;
              final colorScheme = Theme.of(context).colorScheme;

              return Stack(
                children: [
                  Positioned(
                    left: -90,
                    top: -70,
                    child: _BlurredCircle(color: colorScheme.primary.withValues(alpha: 0.18)),
                  ),
                  Positioned(
                    right: -70,
                    bottom: -90,
                    child: _BlurredCircle(color: colorScheme.secondary.withValues(alpha: 0.14)),
                  ),
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AuthHeader(),
                            const SizedBox(height: 32),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: colorScheme.surface.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.shadow.withValues(alpha: 0.06),
                                    blurRadius: 24,
                                    offset: const Offset(0, 18),
                                  ),
                                ],
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(28),
                                child: _LoginForm(
                                  formKey: _formKey,
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  obscurePassword: _obscurePassword,
                                  onTogglePasswordVisibility: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  onSubmit: _onSubmit,
                                  deviceName: _deviceName,
                                  isFetchingDeviceName: _isFetchingDeviceName,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final deviceName = _deviceName ?? 'flutter_app';

    context.read<AuthBloc>().add(
      LoginSubmitted(email: email, password: password, deviceName: deviceName),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePasswordVisibility,
    required this.onSubmit,
    required this.deviceName,
    required this.isFetchingDeviceName,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onSubmit;
  final String? deviceName;
  final bool isFetchingDeviceName;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isSubmitting = state.status == AuthStatus.authenticating;
        final theme = Theme.of(context);

        InputDecoration baseDecoration(String label, {String? hint, Widget? suffixIcon}) {
          return InputDecoration(
            labelText: label,
            hintText: hint,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4), width: 1.4),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          );
        }

        return Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: emailController,
                decoration: baseDecoration('Correo electrónico', hint: 'tu@correo.com'),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa tu correo electrónico.';
                  }
                  final emailRegexp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                  if (!emailRegexp.hasMatch(value.trim())) {
                    return 'El formato del correo no es válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: baseDecoration(
                  'Contraseña',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: onTogglePasswordVisibility,
                  ),
                ),
                obscureText: obscurePassword,
                autofillHints: const [AutofillHints.password],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu contraseña.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: isFetchingDeviceName
                    ? Row(
                        key: const ValueKey('loading-device'),
                        children: [
                          SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Identificando dispositivo…',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Dispositivo detectado: ${deviceName ?? 'flutter_app'}',
                        key: const ValueKey('device-name'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: isSubmitting ? null : onSubmit,
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Iniciar sesión'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AuthHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Image.asset(
            'assets/images/intalnet_logo.png',
            height: 96,
            fit: BoxFit.contain,
            semanticLabel: 'Intalnet Telecomunicaciones',
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Iniciar sesión',
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresa tus credenciales para continuar.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BlurredCircle extends StatelessWidget {
  const _BlurredCircle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: 220,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
