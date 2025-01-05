import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';

class ShippingAddressScreen extends StatefulWidget {
  final String initialName;
  final String initialAddress;
  final String initialPhone;

  const ShippingAddressScreen({
    super.key,
    required this.initialName,
    required this.initialAddress,
    required this.initialPhone,
  });
  @override
  _ShippingAddressScreenState createState() => _ShippingAddressScreenState();

}

class _ShippingAddressScreenState extends State<ShippingAddressScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _fetchUserData();
  }
  // Fetch the user's current data from Firebase
  Future<void> _fetchUserData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        final snapshot = await _dbRef.child('users/$userId').get();
        if (snapshot.exists) {
          final data = snapshot.value as Map?;
          if (data != null) {
            _nameController.text = data['name'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _addressController.text = data['address'] ?? '';
            // If you also have a "city" field, you can load it here as well
            _cityController.text = data['city'] ?? '';
          }
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    }
  }
  // void _saveAddress() {
  //   // TODO: Implement address saving logic
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('Địa chỉ đã được lưu thành công'),
  //       backgroundColor: Colors.green,
  //       behavior: SnackBarBehavior.floating,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(10),
  //       ),
  //     ),
  //   );
  // }
  // Save the updated address to Firebase
  Future<void> _saveAddress() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      if (_formKey.currentState?.validate() ?? false) {
        try {
          final name = _nameController.text.trim();
          final phone = _phoneController.text.trim();
          final address = _addressController.text.trim();


          // Save the data to Firebase
          await _dbRef.child('users/$userId').set({
            'name': name,
            'phone': phone,
            'address': address,

          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Địa chỉ đã được lưu thành công'), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Optionally pop the screen back after saving
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể lưu địa chỉ'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'Địa chỉ giao hàng',
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                  FadeInLeft(
                    delay: Duration(milliseconds: 200),
                    child: _buildInputField(
                      controller: _nameController,
                      label: 'Tên người nhận',
                      icon: Icons.person_outline,
                      hint: 'Nhập tên người nhận',
                    ),
                  ),
                  SizedBox(height: 20),
                  FadeInRight(
                    delay: Duration(milliseconds: 300),
                    child: _buildInputField(
                      controller: _phoneController,
                      label: 'Số điện thoại',
                      icon: Icons.phone_outlined,
                      hint: 'Nhập số điện thoại',
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  SizedBox(height: 20),
                  FadeInLeft(
                    delay: Duration(milliseconds: 400),
                    child: _buildInputField(
                      controller: _addressController,
                      label: 'Địa chỉ chi tiết',
                      icon: Icons.location_on_outlined,
                      hint: 'Số nhà, đường, phường/xã',
                      maxLines: 3,
                    ),
                  ),
                  // SizedBox(height: 20),
                  // FadeInRight(
                  //   delay: Duration(milliseconds: 500),
                  //   child: _buildInputField(
                  //     controller: _cityController,
                  //     label: 'Thành phố',
                  //     icon: Icons.location_city_outlined,
                  //     hint: 'Chọn thành phố',
                  //   ),
                  // ),
                  SizedBox(height: 40),
                  FadeInUp(
                    delay: Duration(milliseconds: 600),
                    child: GestureDetector(
                      onTapDown: (_) => _controller.forward(),
                      onTapUp: (_) {
                        _controller.reverse();
                        if (_formKey.currentState!.validate()) {
                          _saveAddress();
                        }
                      },
                      onTapCancel: () => _controller.reverse(),
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: double.infinity,
                          height: 55,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[700]!, Colors.blue[400]!],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Lưu địa chỉ',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 20, top: 10),
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(icon, color: Colors.blue[400]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập $label';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }



  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}