import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'constants.dart';
import 'screens/home/home_screen.dart';
import 'screens/orderDetails/order_details_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/search/search_screen.dart';

class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  // Chỉ mục được chọn mặc định
  int _selectedIndex = 0;

  // Danh sách các mục điều hướng
  final List<Map<String, dynamic>> _navitems = [
    {"icon": "assets/icons/home.svg", "title": "Trang chủ"},
    {"icon": "assets/icons/search.svg", "title": "Tìm kiếm"},
    {"icon": "assets/icons/order.svg", "title": "Đơn hàng"},
    {"icon": "assets/icons/profile.svg", "title": "Tài khoản"},
  ];

  // Các màn hình
  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const OrderDetailsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              offset: const Offset(0, -3), // Di chuyển bóng lên trên
            ),
          ],
        ),
        child: CupertinoTabBar(
          onTap: (value) {
            setState(() {
              _selectedIndex = value;
            });
          },
          currentIndex: _selectedIndex,
          activeColor: Colors.deepOrange, // Màu khi chọn
          inactiveColor: Colors.grey, // Màu khi không chọn
          backgroundColor: Colors.white, // Màu nền thanh điều hướng
          items: List.generate(
            _navitems.length,
                (index) => BottomNavigationBarItem(
              icon: SvgPicture.asset(
                _navitems[index]["icon"],
                height: 30,
                width: 30,
                colorFilter: ColorFilter.mode(
                  index == _selectedIndex ? Colors.deepOrange : Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              label: _navitems[index]["title"],
            ),
          ),
        ),
      ),
    );
  }
}
