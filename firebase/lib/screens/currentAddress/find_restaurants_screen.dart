import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../components/buttons/secondery_button.dart';
import '../../components/welcome_text.dart';
import '../../constants.dart';
import '../../entry_point.dart';

class FindRestaurantsScreen extends StatefulWidget {
  const FindRestaurantsScreen({super.key});

  @override
  _FindRestaurantsScreenState createState() => _FindRestaurantsScreenState();
}

class _FindRestaurantsScreenState extends State<FindRestaurantsScreen> {
  final TextEditingController _addressController = TextEditingController();

  Future<void> _getCurrentLocationAndSave() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          throw Exception('Quyền truy cập vị trí bị từ chối vĩnh viễn.');
        } else if (permission == LocationPermission.denied) {
          throw Exception('Quyền truy cập vị trí bị từ chối.');
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        String currentAddress = '${placemarks[0].street}, ${placemarks[0].locality}, '
            '${placemarks[0].administrativeArea}, ${placemarks[0].country}';

        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          DatabaseReference dbRef = FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL:
            'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
          ).ref();

          await dbRef.child('users/$userId/currentAddress').set(currentAddress);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Địa chỉ hiện tại đã được lưu.')),
          );
        }
      } else {
        throw Exception('Không tìm thấy địa chỉ từ vị trí hiện tại.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _saveEnteredAddress() async {
    String enteredAddress = _addressController.text.trim();

    if (enteredAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập địa chỉ.')),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      DatabaseReference dbRef = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
        'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
      ).ref();

      await dbRef.child('users/$userId/address').set(enteredAddress);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Địa chỉ đã được lưu.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const EntryPoint()),
            );
          },
        ),
        title: const Text("Truy Cập Vị Trí"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WelcomeText(
                title: "Quyền truy cập vị trí",
                text:
                "Cho phép chúng tôi truy cập vị trí hiện tại của bạn hoặc điền thông tin vị trí nhận hàng của bạn.",
              ),
              SeconderyButton(
                press: _getCurrentLocationAndSave,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      "assets/icons/location.svg",
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        primaryColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text("Sử dụng vị trí hiện tại"),
                  ],
                ),
              ),
              const SizedBox(height: defaultPadding),
              Form(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _addressController,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(color: titleColor),
                      cursorColor: primaryColor,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SvgPicture.asset(
                            "assets/icons/marker.svg",
                            colorFilter: const ColorFilter.mode(
                                bodyTextColor, BlendMode.srcIn),
                          ),
                        ),
                        hintText: "Nhập địa chỉ mới",
                        contentPadding: kTextFieldPadding,
                      ),
                    ),
                    const SizedBox(height: defaultPadding),
                    ElevatedButton(
                      onPressed: _saveEnteredAddress,
                      child: const Text("Lưu địa chỉ"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
