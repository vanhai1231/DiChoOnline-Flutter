import 'package:flutter/material.dart';

class NotificationBadgeProvider extends InheritedWidget {
  final bool showNotificationBadge;
  final void Function(bool) updateBadge;

  const NotificationBadgeProvider({
    required this.showNotificationBadge,
    required this.updateBadge,
    required Widget child,
  }) : super(child: child);

  @override
  bool updateShouldNotify(covariant NotificationBadgeProvider oldWidget) {
    return oldWidget.showNotificationBadge != showNotificationBadge;
  }

  static NotificationBadgeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NotificationBadgeProvider>();
  }
}
