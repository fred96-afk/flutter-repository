import 'package:flutter/material.dart';
import 'package:polleria_movil/api/api.dart';
import 'package:polleria_movil/widgets/backend_config_dialog.dart';

enum BackendButtonVariant {
  /// Compact icon button for AppBars.
  compact,

  /// Styled tonal container pill for standalone headers and login screens.
  tonal,
}

class BackendConfigButton extends StatelessWidget {
  const BackendConfigButton({
    super.key,
    this.variant = BackendButtonVariant.compact,
  });

  final BackendButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: ApiConfig.instance,
      builder: (context, _) {
        final currentUrl = ApiConfig.instance.baseUrl;
        final tooltip = 'Ajustar backend ($currentUrl)';

        if (variant == BackendButtonVariant.compact) {
          return IconButton(
            tooltip: tooltip,
            icon: const Icon(Icons.dns_outlined),
            onPressed: () => showBackendConfigDialog(context),
          );
        }

        // Tonal variant for Login and headers
        final uri = Uri.tryParse(currentUrl);
        final host = uri?.host.isNotEmpty == true ? uri!.host : currentUrl;
        final port = uri != null && uri.hasPort ? ':${uri.port}' : '';
        final displayHost = '$host$port';

        return Tooltip(
          message: tooltip,
          child: Material(
            color: isDark ? const Color(0xFF352D2B) : Colors.white,
            elevation: isDark ? 3 : 1,
            shadowColor: Colors.black.withValues(alpha: 0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark
                    ? const Color(0xFF453935)
                    : const Color(0xFFE5C9BE),
                width: 1,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => showBackendConfigDialog(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.dns_outlined,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: Text(
                        displayHost.isNotEmpty ? displayHost : 'Backend',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
