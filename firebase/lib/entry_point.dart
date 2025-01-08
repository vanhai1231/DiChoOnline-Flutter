import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'notifications/NotificationBadgeProvider.dart';
import 'notifications/notifications_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/orderDetails/order_details_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  int _selectedIndex = 0;
  bool _showNotificationBadge = false;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  void _updateBadge(bool show) {
    setState(() {
      _showNotificationBadge = show;
    });
  }
  final List<Map<String, dynamic>> _navitems = [
    {"icon": "assets/icons/home.svg", "title": "Trang chủ"},
    {"icon": "assets/icons/bell.svg", "title": "Thông báo"},
    {"icon": "assets/icons/order.svg", "title": "Đơn hàng"},
    {"icon": "assets/icons/profile.svg", "title": "Tài khoản"},
  ];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _setupNotificationListener();
  }
// Phương thức công khai để cập nhật giá trị _showNotificationBadge
  void updateNotificationBadge(bool show) {
    setState(() {
      _showNotificationBadge = show;
    });
  }
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        setState(() {
          _showNotificationBadge = true;
        });
      },
    );
  }

  void _setupNotificationListener() {
    flutterLocalNotificationsPlugin.getActiveNotifications().then((notifications) {
      setState(() {
        _showNotificationBadge = notifications.isNotEmpty;
      });
    });
  }

  // Các màn hình
  final List<Widget> _screens = [
    const HomeScreen(),
    const NotificationsScreen(),
    const OrderDetailsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return NotificationBadgeProvider(
        showNotificationBadge: _showNotificationBadge,
        updateBadge: _updateBadge,

      child: Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 3,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: CupertinoTabBar(
          onTap: (value) {
            setState(() {
              _selectedIndex = value;
              if (value == 1) {
                _showNotificationBadge = false;
                // Clear notifications when user taps the notification tab
                flutterLocalNotificationsPlugin.cancelAll();
              }
            });
          },
          currentIndex: _selectedIndex,
          activeColor: Colors.deepOrange,
          inactiveColor: Colors.grey,
          backgroundColor: Colors.white,
          items: List.generate(
            _navitems.length,
                (index) => BottomNavigationBarItem(
              icon: Stack(
                children: [
                  SvgPicture.asset(
                    _navitems[index]["icon"],
                    height: 30,
                    width: 30,
                    colorFilter: ColorFilter.mode(
                      index == _selectedIndex ? Colors.deepOrange : Colors.grey,
                      BlendMode.srcIn,
                    ),
                  ),
                  if (index == 1 && _showNotificationBadge)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              label: _navitems[index]["title"],
            ),
          ),
        ),
      ),
    )
    );
  }
}