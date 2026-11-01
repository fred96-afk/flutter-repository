import 'package:flutter/material.dart';
import 'package:polleria_movil/theme/theme_controller.dart';

enum ThemeButtonVariant {
  /// Compact icon button for AppBars.
  compact,

  /// Styled tonal container pill for standalone headers and login screens.
  tonal,
}

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({
    super.key,
    this.variant = ThemeButtonVariant.compact,
  });

  final ThemeButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final isDark = ThemeController.instance.isDarkMode(context);
        final tooltip = isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro';

        final iconWidget = Icon(
          isDark ? Icons.light_mode : Icons.dark_mode_outlined,
          size: variant == ThemeButtonVariant.tonal ? 18 : 24,
          color: variant == ThemeButtonVariant.tonal
              ? (isDark ? const Color(0xFFFFB74D) : colorScheme.primary)
              : null,
        );

        if (variant == ThemeButtonVariant.compact) {
          return IconButton(
            tooltip: tooltip,
            icon: iconWidget,
            onPressed: () => ThemeController.instance.toggleTheme(context),
          );
        }

        // Tonal variant for Login and standalone headers
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
              onTap: () => ThemeController.instance.toggleTheme(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    iconWidget,
                    const SizedBox(width: 8),
                    Text(
                      isDark ? 'Modo claro' : 'Modo oscuro',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
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
