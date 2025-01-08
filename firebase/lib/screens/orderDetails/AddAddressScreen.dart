import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AddAddressScreen extends StatefulWidget {
  final String? currentName;
  final String? currentAddress;
  final String? currentPhone;

  const AddAddressScreen({
    super.key,
    this.currentName,
    this.currentAddress,
    this.currentPhone,

  });

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // Firebase database reference
  final DatabaseReference dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
    'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  @override
  void initState() {
    super.initState();
    // Set current values if available
    if (widget.currentName != null) nameController.text = widget.currentName!;
    if (widget.currentAddress != null)
      addressController.text = widget.currentAddress!;
    if (widget.currentPhone != null)
      phoneController.text = widget.currentPhone!;
  }

  Future<void> saveAddressToFirebase(String name, String address, String phone) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      try {
        // Tạo dữ liệu địa chỉ mới
        Map<String, dynamic> newAddress = {
          'name': name,
          'address': address,
          'phone': phone,
        };

        // Lưu vào Firebase Database dưới node 'users'
        final userRef = dbRef.child('users/$userId');
        await userRef.set({
          'name': name,
          'address': address,
          'phone': phone,
        });

        print("Địa chỉ đã được lưu vào Firebase.");

        // Sau khi lưu thành công, hiển thị thông báo
        if (mounted) {
          showSuccessDialog("Địa chỉ đã được lưu!");
        }

        Future.delayed(Duration(seconds: 2), () {
          Navigator.pop(context,true); // Quay lại màn hình trước sau 2 giây
        });

      } catch (e) {
        debugPrint("Lỗi khi lưu địa chỉ: $e");
        if (mounted) {
          showErrorDialog("Không thể lưu địa chỉ.");
        }
      }
    }
  }

  void showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text("Thành công"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text("Lỗi"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      // Đảm bảo rằng bàn phím không làm tràn giao diện
      appBar: AppBar(title: Text("Chỉnh sửa địa chỉ")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Tên người nhận"),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: "Địa chỉ"),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Số điện thoại"),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final newName = nameController.text.trim();
                  final newAddress = addressController.text.trim();
                  final newPhone = phoneController.text.trim();

                  if (newName.isNotEmpty && newAddress.isNotEmpty &&
                      newPhone.isNotEmpty) {
                    // Gọi hàm lưu vào Firebase
                    saveAddressToFirebase(newName, newAddress, newPhone);
                    //showSuccessDialog("Địa chỉ đã được lưu!");
                  } else {
                    // Hiển thị thông báo nếu không điền đủ thông tin
                    showDialog(
                      context: context,
                      builder: (context) =>
                          AlertDialog(
                            title: const Text("Lỗi"),
                            content: const Text(
                                "Tất cả các trường thông tin phải được điền đầy đủ!"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text("OK"),
                              ),
                            ],
                          ),
                    );
                  }
                },
                child: const Text("Lưu địa chỉ"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
