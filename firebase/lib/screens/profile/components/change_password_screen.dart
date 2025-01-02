import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModernChangePasswordScreen extends StatefulWidget {
  const ModernChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ModernChangePasswordScreen> createState() => _ModernChangePasswordScreenState();
}

class _ModernChangePasswordScreenState extends State<ModernChangePasswordScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  double _passwordStrength = 0.0;
  String _passwordStrengthText = 'Yếu';
  Color _passwordStrengthColor = Colors.red;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    _newPasswordController.addListener(_checkPasswordStrength);
  }

  void _checkPasswordStrength() {
    String password = _newPasswordController.text;
    double strength = 0;

    if (password.length >= 8) strength += 0.2;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;

    setState(() {
      _passwordStrength = strength;
      if (strength <= 0.2) {
        _passwordStrengthText = 'Yếu';
        _passwordStrengthColor = Colors.red;
      } else if (strength <= 0.4) {
        _passwordStrengthText = 'Trung bình';
        _passwordStrengthColor = Colors.orange;
      } else if (strength <= 0.6) {
        _passwordStrengthText = 'Khá';
        _passwordStrengthColor = Colors.yellow;
      } else if (strength <= 0.8) {
        _passwordStrengthText = 'Mạnh';
        _passwordStrengthColor = Colors.lightGreen;
      } else {
        _passwordStrengthText = 'Rất mạnh';
        _passwordStrengthColor = Colors.green;
      }
    });
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool showPassword,
    required Function() toggleVisibility,
    required String? Function(String?) validator,
    String? helperText,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: !showPassword,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          helperMaxLines: 2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
            onPressed: toggleVisibility,
          ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
        validator: validator,
        onChanged: (value) {
          if (controller == _newPasswordController) {
            _checkPasswordStrength();
          }
        },
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Độ mạnh mật khẩu: $_passwordStrengthText',
              style: TextStyle(color: _passwordStrengthColor),
            ),
            Text('${(_passwordStrength * 100).toInt()}%'),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _passwordStrength,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Mật khẩu nên chứa: chữ hoa, chữ thường, số và ký tự đặc biệt',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> _handleChangePassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Show success dialog
      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog();
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Thành công'),
          ],
        ),
        content: const Text('Mật khẩu đã được thay đổi thành công!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.1),
                Theme.of(context).scaffoldBackgroundColor,
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_outline, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Tạo mật khẩu mới',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildPasswordField(
                    label: 'Mật khẩu hiện tại',
                    controller: _currentPasswordController,
                    showPassword: _showCurrentPassword,
                    toggleVisibility: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Vui lòng nhập mật khẩu hiện tại';
                      }
                      return null;
                    },
                  ),
                  _buildPasswordField(
                    label: 'Mật khẩu mới',
                    controller: _newPasswordController,
                    showPassword: _showNewPassword,
                    toggleVisibility: () => setState(() => _showNewPassword = !_showNewPassword),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Vui lòng nhập mật khẩu mới';
                      }
                      if ((value?.length ?? 0) < 8) {
                        return 'Mật khẩu phải có ít nhất 8 ký tự';
                      }
                      if (_passwordStrength < 0.6) {
                        return 'Mật khẩu chưa đủ mạnh';
                      }
                      return null;
                    },
                  ),
                  _buildPasswordStrengthIndicator(),
                  _buildPasswordField(
                    label: 'Xác nhận mật khẩu mới',
                    controller: _confirmPasswordController,
                    showPassword: _showConfirmPassword,
                    toggleVisibility: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Vui lòng xác nhận mật khẩu mới';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Mật khẩu xác nhận không khớp';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleChangePassword,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text(
                        'Đổi mật khẩu',
                        style: TextStyle(fontSize: 16),
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

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}