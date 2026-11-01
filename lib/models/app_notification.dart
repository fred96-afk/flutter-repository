import 'package:flutter/material.dart';

enum NotificationType {
  newOrder,
  statusUpdated,
  paymentUpdated,
  orderAccepted,
  callWaiter,
  requestBill,
  tableAlert,
  reportReady,
  reportFailed,
  general;

  static NotificationType fromEventName(String eventName) {
    switch (eventName.toLowerCase().trim()) {
      case 'new-order':
      case 'order-created':
        return NotificationType.newOrder;
      case 'status-updated':
        return NotificationType.statusUpdated;
      case 'payment-updated':
        return NotificationType.paymentUpdated;
      case 'order-accepted':
        return NotificationType.orderAccepted;
      case 'call-waiter':
        return NotificationType.callWaiter;
      case 'request-bill':
        return NotificationType.requestBill;
      case 'table-alert':
        return NotificationType.tableAlert;
      case 'report-ready':
      case 'report-completed':
        return NotificationType.reportReady;
      case 'report-failed':
        return NotificationType.reportFailed;
      default:
        return NotificationType.general;
    }
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.orderId,
    this.tableNumber,
    this.amount,
    this.customerName,
    this.status,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final int? orderId;
  final int? tableNumber;
  final double? amount;
  final String? customerName;
  final String? status;
  final bool isRead;

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationType? type,
    int? orderId,
    int? tableNumber,
    double? amount,
    String? customerName,
    String? status,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      orderId: orderId ?? this.orderId,
      tableNumber: tableNumber ?? this.tableNumber,
      amount: amount ?? this.amount,
      customerName: customerName ?? this.customerName,
      status: status ?? this.status,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'orderId': orderId,
      'tableNumber': tableNumber,
      'amount': amount,
      'customerName': customerName,
      'status': status,
      'isRead': isRead,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      type: NotificationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NotificationType.general,
      ),
      orderId: json['orderId'] is int
          ? json['orderId'] as int
          : int.tryParse(json['orderId']?.toString() ?? ''),
      tableNumber: json['tableNumber'] is int
          ? json['tableNumber'] as int
          : int.tryParse(json['tableNumber']?.toString() ?? ''),
      amount: json['amount'] is num
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? ''),
      customerName: json['customerName']?.toString(),
      status: json['status']?.toString(),
      isRead: json['isRead'] == true,
    );
  }

  IconData get icon {
    switch (type) {
      case NotificationType.newOrder:
        return Icons.restaurant;
      case NotificationType.statusUpdated:
        return Icons.update;
      case NotificationType.paymentUpdated:
        return Icons.payments_outlined;
      case NotificationType.orderAccepted:
        return Icons.delivery_dining;
      case NotificationType.callWaiter:
        return Icons.notifications_active;
      case NotificationType.requestBill:
        return Icons.receipt_long;
      case NotificationType.tableAlert:
        return Icons.warning_amber_rounded;
      case NotificationType.reportReady:
        return Icons.description;
      case NotificationType.reportFailed:
        return Icons.error_outline;
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.newOrder:
        return const Color(0xFF168C5B); // Emerald
      case NotificationType.statusUpdated:
        return const Color(0xFF1976D2); // Blue
      case NotificationType.paymentUpdated:
        return const Color(0xFF00796B); // Teal
      case NotificationType.orderAccepted:
        return const Color(0xFF5E35B1); // Purple
      case NotificationType.callWaiter:
        return const Color(0xFF8E24AA); // Purple Alert
      case NotificationType.requestBill:
        return const Color(0xFFD84315); // Deep Orange
      case NotificationType.tableAlert:
        return const Color(0xFFC2185B); // Crimson
      case NotificationType.reportReady:
        return const Color(0xFF0288D1); // Light Blue
      case NotificationType.reportFailed:
        return const Color(0xFFD32F2F); // Red
      case NotificationType.general:
        return const Color(0xFF546E7A); // Slate
    }
  }
}
