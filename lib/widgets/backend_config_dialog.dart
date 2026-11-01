import 'package:flutter/material.dart';
import 'package:polleria_movil/api/api.dart';
import 'package:polleria_movil/data/restaurant_store.dart';

Future<void> showBackendConfigDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogCtx) => const BackendConfigDialog(),
  );
}

class BackendConfigDialog extends StatefulWidget {
  const BackendConfigDialog({super.key});

  @override
  State<BackendConfigDialog> createState() => _BackendConfigDialogState();
}

class _BackendConfigDialogState extends State<BackendConfigDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isTesting = false;
  ({bool success, int? statusCode, String message})? _testResult;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ApiConfig.instance.baseUrl);
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_testResult != null) {
      setState(() => _testResult = null);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runConnectionTest() async {
    final rawUrl = _controller.text.trim();
    if (rawUrl.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final result = await ApiClient().testConnection(rawUrl);

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testResult = result;
      });
    }
  }

  void _applyPreset(String presetUrl) {
    setState(() {
      _controller.text = presetUrl;
      _testResult = null;
    });
  }

  void _saveAndClose() {
    if (!_formKey.currentState!.validate()) return;

    var newUrl = _controller.text.trim();
    if (!newUrl.startsWith('http://') && !newUrl.startsWith('https://')) {
      newUrl = 'http://$newUrl';
    }

    ApiConfig.instance.baseUrl = newUrl;
    RestaurantStore.instance.loadAllFromApi();

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Backend configurado: ${ApiConfig.instance.baseUrl}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.dialogTheme.backgroundColor ?? colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.dns_rounded,
                        color: colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ajustar Backend API',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Servidor ASP.NET / OpenAPI',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Current active URL badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF352D2B)
                        : colorScheme.primaryContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF453935)
                          : colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'URL actual: ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          ApiConfig.instance.baseUrl,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // URL Input Field
                TextFormField(
                  controller: _controller,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'URL Base del Servidor',
                    hintText: BackendUrlConstants.androidEmulator,
                    prefixIcon: Icon(
                      Icons.link_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _controller.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa una URL base';
                    }
                    final trimmed = value.trim();
                    if (!trimmed.contains('.') && !trimmed.contains('localhost')) {
                      return 'Ingresa una dirección IP o dominio válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Quick Presets
                Text(
                  'Atajos rápidos:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.phone_android, size: 16),
                      label: const Text('Emulador Android (10.0.2.2)'),
                      labelStyle: const TextStyle(fontSize: 12),
                      onPressed: () => _applyPreset(BackendUrlConstants.androidEmulator),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.computer, size: 16),
                      label: const Text('Localhost (5000)'),
                      labelStyle: const TextStyle(fontSize: 12),
                      onPressed: () => _applyPreset(BackendUrlConstants.localhost),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.restart_alt, size: 16),
                      label: const Text('Predeterminado'),
                      labelStyle: const TextStyle(fontSize: 12),
                      onPressed: () => _applyPreset(ApiConfig.defaultBaseUrl),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Test connection button
                OutlinedButton.icon(
                  onPressed: _isTesting ? null : _runConnectionTest,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  icon: _isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.network_check_rounded, size: 20),
                  label: Text(_isTesting ? 'Probando conexión...' : 'Probar conexión'),
                ),

                // Connection Test Feedback
                if (_testResult != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _testResult!.success
                          ? (isDark ? const Color(0xFF1B2E24) : const Color(0xFFE7F7ED))
                          : (isDark ? const Color(0xFF3E1F1F) : const Color(0xFFFFEBEE)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _testResult!.success
                            ? (isDark ? const Color(0xFF48B383) : const Color(0xFF168C5B))
                            : (isDark ? const Color(0xFFE57373) : const Color(0xFFD32F2F)),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _testResult!.success
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded,
                          color: _testResult!.success
                              ? (isDark ? const Color(0xFF48B383) : const Color(0xFF168C5B))
                              : (isDark ? const Color(0xFFE57373) : const Color(0xFFD32F2F)),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _testResult!.message,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _testResult!.success
                                  ? (isDark ? const Color(0xFF81C784) : const Color(0xFF1B5E20))
                                  : (isDark ? const Color(0xFFEF9A9A) : const Color(0xFFB71C1C)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Dialog Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _saveAndClose,
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Guardar'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
