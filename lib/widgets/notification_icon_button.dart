import 'package:flutter/material.dart';
import 'package:polleria_movil/services/pusher_service.dart';
import 'package:polleria_movil/widgets/notifications_sheet.dart';

class NotificationIconButton extends StatelessWidget {
  const NotificationIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PusherService.instance,
      builder: (context, _) {
        final unread = PusherService.instance.unreadCount;
        return IconButton(
          tooltip: 'Notificaciones',
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(
              unread > 99 ? '99+' : '$unread',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            child: const Icon(Icons.notifications_outlined),
          ),
          onPressed: () => showNotificationsSheet(context),
        );
      },
    );
  }
}
