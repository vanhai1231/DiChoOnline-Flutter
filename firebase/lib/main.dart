import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'admin/dashboard_screen.dart';
import 'admin/order_management/order_detail_screen.dart';
import 'admin/order_management/order_list_screen.dart';
import 'admin/product_management/add_edit_product_screen.dart';
import 'admin/product_management/product_list_screen.dart';
import 'admin/user_management/user_detail_screen.dart';
import 'admin/user_management/user_list_screen.dart';
import 'admin/revenue_management/revenue_report_screen.dart';
import 'constants.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_scrreen.dart';
import 'promotions/DiscountPage.dart';

// Khởi tạo plugin thông báo cục bộ
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp();

  // Cài đặt thông báo cục bộ cho Android
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chợ Online',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: bodyTextColor),
          bodySmall: TextStyle(color: bodyTextColor),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          contentPadding: EdgeInsets.all(defaultPadding),
          hintStyle: TextStyle(color: bodyTextColor),
        ),
      ),
      initialRoute: '/', // Route mặc định
      routes: {
        '/': (context) => const AuthChecker(), // Kiểm tra trạng thái đăng nhập
        '/login': (context) => const SignInScreen(), // Màn hình đăng nhập
        '/dashboard': (context) => const AdminDashboardScreen(), // Dashboard admin
        '/onboarding': (context) => const OnboardingScreen(), // Onboarding

        '/product-management': (context) => const ProductListScreen(), // Quản lý sản phẩm
        '/product-edit': (context) => AddEditProductScreen(), // Thêm/sửa sản phẩm
        '/order-management': (context) => const OrderListScreen(), // Quản lý đơn hàng
        '/order-detail': (context) => OrderDetailScreen(
          orderId: ModalRoute.of(context)!.settings.arguments as String,
        ), // Chi tiết đơn hàng
        '/user-management': (context) => const UserListScreen(), // Quản lý người dùng
        '/user-detail': (context) => UserDetailScreen(
          userId: ModalRoute.of(context)!.settings.arguments as String,
        ), // Chi tiết người dùng
        '/revenue-report': (context) => const RevenueReportScreen(), // Báo cáo doanh thu
        '/discount-page': (context) =>  DiscountPage(), // Trang khuyến mãi
      },
    );
  }
}

class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          final userEmail = snapshot.data!.email;

          // Nếu email là admin, chuyển đến dashboard
          if (userEmail == "vanhai11203@gmail.com") {
            return const AdminDashboardScreen();
          } else {
            // Nếu là người dùng thường, chuyển đến Onboarding
            return const OnboardingScreen();
          }
        } else {
          // Nếu chưa đăng nhập, chuyển đến màn hình đăng nhập
          return const SignInScreen(); // Route tương ứng với '/login'
        }
      },
    );
  }
}
