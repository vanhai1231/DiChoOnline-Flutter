import 'package:firebase/screens/profile/components/profile_details_screen.dart';
import 'package:firebase/screens/profile/components/shipping_address_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../constants.dart';
import '../../auth/sign_in_screen.dart';
import '../../wishlist/WishlistScreen.dart';
import 'package:firebase/screens/profile/components/order_management_screen.dart';
import 'package:firebase_database/firebase_database.dart';

import 'change_password_screen.dart'; // Import for Firebase Database

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  String customerName = "Loading...";
  String address = "Loading...";
  String phone = "Loading...";

  final user = FirebaseAuth.instance.currentUser;

  // Firebase Realtime Database reference
  final DatabaseReference dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Fetch user data from Firebase
  Future<void> _loadUserData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      try {
        final userRef = dbRef.child('users/$userId');
        final snapshot = await userRef.get();

        if (snapshot.exists) {
          final data = snapshot.value as Map?;
          setState(() {
            customerName = data?['name'] ?? "No name";
            address = data?['address'] ?? "No address";
            phone = data?['phone'] ?? "No phone";
          });
        } else {
          setState(() {
            customerName = "User data not found";
            address = "User data not found";
            phone = "User data not found";
          });
        }
      } catch (e) {
        setState(() {
          customerName = "Error loading data";
          address = "Error loading data";
          phone = "Error loading data";
        });
      }
    }
  }

  // Logout function
  Future<void> signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: defaultPadding),
              Text(
                "Cài đặt tài khoản",
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    fontWeight: FontWeight.bold, color: Colors.greenAccent),
              ),
              Text(
                "Cập nhật các cài đặt như thông báo, thanh toán, chỉnh sửa hồ sơ, v.v.",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Colors.black.withOpacity(0.7), fontSize: 16),
              ),
              const SizedBox(height: 16),

              // Profile Menu Card
              ProfileMenuCard(
                svgSrc: "assets/icons/profile.svg",
                title: "Thông tin hồ sơ",
                subTitle: "Thay đổi thông tin tài khoản",
                press: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileDetailsScreen()),
                  );
                },
              ),
              ProfileMenuCard(
                svgSrc: "assets/icons/lock.svg",
                title: "Đổi mật khẩu",
                subTitle: "Đổi mật khẩu của bạn",
                press: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ModernChangePasswordScreen()),
                  );
                },
              ),
              ProfileMenuCard(
                svgSrc: "assets/icons/order.svg", // Thêm icon tương ứng
                title: "Quản lý đơn hàng",
                subTitle: "Xem và theo dõi đơn hàng của bạn",
                press: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OrderManagementScreen()),
                  );
                },
              ),

              ProfileMenuCard(
                svgSrc: "assets/icons/marker.svg",
                title: "Địa chỉ giao hàng",
                subTitle: "Thêm hoặc xóa địa chỉ giao hàng",
                press: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShippingAddressScreen(
                        initialName: customerName,  // Pass the name
                        initialAddress: address,    // Pass the address
                        initialPhone: phone,        // Pass the phone number
                      ),
                    ),
                  );
                },
              ),


              // Mục Danh sách yêu thích
              ProfileMenuCard(
                pngSrc: "assets/icons/heart.png", // Sử dụng pngSrc thay vì svgSrc
                title: "Danh sách yêu thích",
                subTitle: "Xem và quản lý các mặt hàng yêu thích của bạn",
                press: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WishlistDetailsScreen()),
                  );
                },
              ),

              // Mục Đăng xuất
              ProfileMenuCard(
                svgSrc: "assets/icons/logout.svg",
                title: "Đăng xuất",
                subTitle: "Thoát khỏi tài khoản của bạn",
                press: () => signOut(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class ProfileMenuCard extends StatelessWidget {
  const ProfileMenuCard({
    super.key,
    this.title,
    this.subTitle,
    this.svgSrc,
    this.pngSrc,
    this.press,
  });

  final String? title, subTitle, svgSrc, pngSrc;
  final VoidCallback? press;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: defaultPadding / 2),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        onTap: press,
        child: Card(
          elevation: 5, // Thêm bóng đổ nhẹ
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Góc bo tròn
          ),
          color: Colors.white.withOpacity(0.9), // Màu nền nhẹ
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            child: Row(
              children: [
                // Kiểm tra xem có svgSrc hay pngSrc để hiển thị đúng loại hình ảnh
                svgSrc != null
                    ? SvgPicture.asset(
                  svgSrc!,
                  height: 28,
                  width: 28,
                  colorFilter: ColorFilter.mode(
                    Colors.greenAccent.withOpacity(0.8),
                    BlendMode.srcIn,
                  ),
                )
                    : Image.asset(
                  pngSrc!,
                  height: 28,
                  width: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subTitle!,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.arrow_forward_ios_outlined,
                  size: 20,
                  color: Colors.greenAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
