import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:animate_do/animate_do.dart';

class ProfileDetailsScreen extends StatefulWidget {
  @override
  _ProfileDetailsScreenState createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final user = FirebaseAuth.instance.currentUser;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool isGoogleUser = false;

  @override
  void initState() {
    super.initState();
    isGoogleUser = user?.providerData.any((provider) => provider.providerId == 'google.com') ?? false;
    _initializeUserData();
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _phoneController = TextEditingController();
    _emailController = TextEditingController(text: user?.email ?? '');
    _loadUserData();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeUserData() async {
    if (isGoogleUser) {
      _nameController.text = user?.displayName ?? '';
      _emailController.text = user?.email ?? '';
      _phoneController.text = '';
    } else {
      await _loadUserData();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final snapshot = await FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref().child('users').child(user!.uid).get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone']?.toString() ?? '';
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        if (isGoogleUser) {
          await user?.updateDisplayName(_nameController.text);
        }

        if (user != null) {
          final userRef = FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL: 'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
          ).ref().child('users').child(user!.uid);

          await userRef.update({
            'name': _nameController.text,
            'phone': _phoneController.text,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cập nhật thành công'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Đảm bảo nội dung được điều chỉnh khi bàn phím xuất hiện
      body: GestureDetector(
        onTap: () {
          // Dismiss the keyboard when tapping outside
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white, // Nền trắng
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView( // Thêm để nội dung cuộn được
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    FadeInDown(
                      child: Text(
                        'Thông tin cá nhân',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    FadeInDown(
                      delay: Duration(milliseconds: 200),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.grey.shade200,
                            child: CircleAvatar(
                              radius: 65,
                              backgroundImage: NetworkImage(
                                user?.photoURL ?? 'https://via.placeholder.com/150',
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 24,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildTextField("Họ và tên", _nameController, Icons.person),
                            _buildTextField("Số điện thoại", _phoneController, Icons.phone),
                            _buildTextField("Email", _emailController, Icons.email, enabled: false),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    FadeInUp(
                      child: GestureDetector(
                        onTapDown: (_) => _animationController.forward(),
                        onTapUp: (_) {
                          _animationController.reverse();
                          _updateProfile();
                        },
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Center(
                              child: Text(
                                'Cập nhật thông tin',
                                style: TextStyle(
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
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool enabled = true}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Vui lòng nhập $label';
          }
          return null;
        },
      ),
    );
  }
}

