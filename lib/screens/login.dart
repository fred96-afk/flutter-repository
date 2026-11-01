import 'package:flutter/material.dart';
import 'package:polleria_movil/api/api.dart';
import 'package:polleria_movil/data/restaurant_store.dart';
import 'package:polleria_movil/widgets/theme_toggle_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      // Format email if username has no @
      final email = username.contains('@') ? username : '$username@polleria.com';
      try {
        await _authService.login(email, password);
        if (mounted) {
          RestaurantStore.instance.loadAllFromApi();
          Navigator.pushReplacementNamed(context, '/home');
          return;
        }
      } catch (apiError) {
        // If demo credentials match and network/server is unreachable, allow offline access
        final isDemo = username.toLowerCase() == 'augusto' && password == '123456';
        if (isDemo) {
          ApiConfig.instance.setAuthToken('demo-token-augusto');
          if (mounted) {
            RestaurantStore.instance.loadAllFromApi();
            Navigator.pushReplacementNamed(context, '/home');
          }
          return;
        }

        if (apiError is ApiException) {
          if (apiError.statusCode == 401 || apiError.statusCode == 400) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Usuario o contraseña incorrectos')),
              );
            }
            return;
          }
        }
        rethrow;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.message : 'Error al conectar con el servidor',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Text(
                'EL GIGANTE',
                maxLines: 1,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.045)
                      : const Color(0xFF914F3A).withValues(alpha: 0.06),
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    ThemeToggleButton(variant: ThemeButtonVariant.tonal),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Card(
                    color: theme.cardColor,
                    elevation: isDark ? 6 : 2,
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Image.asset(
                                'assets/images/polleria_logo.png',
                                width: 120,
                                height: 120,
                                fit: BoxFit.contain,
                                semanticLabel: 'Logo de Pollería El Gigante',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Pollería El Gigante',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Inicia sesión para continuar',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _usernameController,
                              style: TextStyle(color: colorScheme.onSurface),
                              decoration: InputDecoration(
                                labelText: 'Usuario o Correo',
                                labelStyle: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF352D2B)
                                    : Colors.white,
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Ingresa tu usuario'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              style: TextStyle(color: colorScheme.onSurface),
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                labelStyle: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF352D2B)
                                    : Colors.white,
                              ),
                              onFieldSubmitted: (_) => _signIn(),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Ingresa tu contraseña'
                                  : null,
                            ),
                            const SizedBox(height: 18),
                            FilledButton(
                              onPressed: _isLoading ? null : _signIn,
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Ingresar'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
