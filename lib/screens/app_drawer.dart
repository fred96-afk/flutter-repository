import 'package:flutter/material.dart';
import 'package:polleria_movil/api/api.dart';
import 'package:polleria_movil/data/app_storage.dart';
import 'package:polleria_movil/theme/theme_controller.dart';
import 'package:polleria_movil/services/pusher_service.dart';
import 'package:polleria_movil/widgets/notifications_sheet.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.selectedRoute});

  final String selectedRoute;

  void _openRoute(BuildContext context, String route) {
    Navigator.pop(context);
    if (route != selectedRoute) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final userData = AppStorage.getUserData();
    final userName = userData?['name']?.toString() ?? 'Pollería El Gigante';
    final userRole = userData?['role']?.toString();
    final userEmail = userData?['email']?.toString() ?? 'Gestión del restaurante';
    final subtitle = userRole != null ? '$userEmail • $userRole' : userEmail;

    return Drawer(
      backgroundColor: theme.drawerTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      UserAccountsDrawerHeader(
                        margin: EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF38231D) : const Color(0xFF914F3A),
                        ),
                        accountName: Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        accountEmail: Text(
                          subtitle,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        currentAccountPicture: CircleAvatar(
                          radius: 36,
                          backgroundColor: isDark
                              ? const Color(0xFF5C2C1F)
                              : const Color(0xFFFFE2D8),
                          child: const CircleAvatar(
                            radius: 31,
                            backgroundColor: Color(0xFF211F20),
                            backgroundImage: AssetImage(
                              'assets/images/polleria_logo.png',
                            ),
                          ),
                        ),
                      ),
                      _DrawerItem(
                        icon: Icons.table_restaurant,
                        label: 'Mesas',
                        selected: selectedRoute == '/home',
                        onTap: () => _openRoute(context, '/home'),
                      ),
                      _DrawerItem(
                        icon: Icons.pending_actions,
                        label: 'Pedidos pendientes',
                        selected: selectedRoute == '/orders/pending',
                        onTap: () => _openRoute(context, '/orders/pending'),
                      ),
                      _DrawerItem(
                        icon: Icons.task_alt,
                        label: 'Pedidos atendidos',
                        selected: selectedRoute == '/orders/attended',
                        onTap: () => _openRoute(context, '/orders/attended'),
                      ),
                      AnimatedBuilder(
                        animation: PusherService.instance,
                        builder: (context, _) {
                          final unread = PusherService.instance.unreadCount;
                          return ListTile(
                            leading: Icon(
                              Icons.notifications_outlined,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            title: Text(
                              'Notificaciones',
                              style: TextStyle(color: colorScheme.onSurface),
                            ),
                            trailing: unread > 0
                                ? Badge.count(
                                    count: unread,
                                    backgroundColor: colorScheme.error,
                                  )
                                : null,
                            onTap: () {
                              Navigator.pop(context);
                              showNotificationsSheet(context);
                            },
                          );
                        },
                      ),
                      const Spacer(),
                      const Divider(),
                      AnimatedBuilder(
                        animation: ThemeController.instance,
                        builder: (context, _) {
                          final isDarkModeActive = ThemeController.instance.isDarkMode(context);
                          return SwitchListTile(
                            secondary: Icon(
                              isDarkModeActive ? Icons.dark_mode : Icons.light_mode,
                              color: colorScheme.primary,
                            ),
                            title: Text(
                              'Modo oscuro',
                              style: TextStyle(color: colorScheme.onSurface),
                            ),
                            subtitle: Text(
                              isDarkModeActive ? 'Activado' : 'Desactivado',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            value: isDarkModeActive,
                            onChanged: (_) => ThemeController.instance.toggleTheme(context),
                          );
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(
                          Icons.logout,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          'Cerrar sesión',
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                        onTap: () {
                          ApiConfig.instance.clearAuth();
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ListTile(
      selected: selected,
      selectedTileColor: colorScheme.primaryContainer,
      selectedColor: colorScheme.primary,
      iconColor: selected
          ? colorScheme.primary
          : colorScheme.onSurfaceVariant,
      textColor: colorScheme.onSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      leading: Icon(icon),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }
}
