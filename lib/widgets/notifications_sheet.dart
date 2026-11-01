import 'package:flutter/material.dart';
import 'package:polleria_movil/models/app_notification.dart';
import 'package:polleria_movil/screens/order_detail.dart';
import 'package:polleria_movil/services/pusher_service.dart';

Future<void> showNotificationsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => const NotificationsSheet(),
  );
}

class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final pusher = PusherService.instance;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Indicador de arrastre
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Encabezado
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'Notificaciones',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          AnimatedBuilder(
                            animation: pusher,
                            builder: (context, _) {
                              final isLive = pusher.isConnected;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isLive
                                      ? const Color(0xFF168C5B).withValues(alpha: 0.15)
                                      : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isLive
                                        ? const Color(0xFF168C5B).withValues(alpha: 0.4)
                                        : colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isLive
                                            ? const Color(0xFF168C5B)
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isLive ? 'En vivo' : 'Pusher',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isLive
                                            ? const Color(0xFF168C5B)
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Botón marcar leídas
                    AnimatedBuilder(
                      animation: pusher,
                      builder: (context, _) {
                        if (pusher.unreadCount == 0) return const SizedBox.shrink();
                        return IconButton(
                          tooltip: 'Marcar todas como leídas',
                          icon: const Icon(Icons.done_all, size: 20),
                          onPressed: () => pusher.markAllAsRead(),
                        );
                      },
                    ),

                    // Botón limpiar
                    AnimatedBuilder(
                      animation: pusher,
                      builder: (context, _) {
                        if (pusher.notifications.isEmpty) return const SizedBox.shrink();
                        return IconButton(
                          tooltip: 'Borrar historial',
                          icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                          onPressed: () => pusher.clearAll(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Lista de notificaciones
              Expanded(
                child: AnimatedBuilder(
                  animation: pusher,
                  builder: (context, _) {
                    final list = pusher.notifications;

                    if (list.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications_none,
                                size: 56,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Sin notificaciones',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Los nuevos pedidos, cambios de estado y alertas de mesas aparecerán aquí en tiempo real.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        indent: 72,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final notification = list[index];
                        return _NotificationTile(notification: notification);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 45) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        PusherService.instance.markAsRead(notification.id);
        if (notification.tableNumber != null) {
          Navigator.pop(context);
          Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(
                tableNumber: notification.tableNumber!,
              ),
            ),
          );
        }
      },
      child: Container(
        color: notification.isRead
            ? Colors.transparent
            : notification.color.withValues(alpha: isDark ? 0.12 : 0.06),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono con fondo circular
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: notification.color.withValues(alpha: 0.18),
              ),
              child: Icon(
                notification.icon,
                color: notification.color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (!notification.isRead) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: notification.color,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(notification.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      if (notification.tableNumber != null)
                        InkWell(
                          onTap: () {
                            PusherService.instance.markAsRead(notification.id);
                            Navigator.pop(context);
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderDetailScreen(
                                  tableNumber: notification.tableNumber!,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Ver Mesa ${notification.tableNumber}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
