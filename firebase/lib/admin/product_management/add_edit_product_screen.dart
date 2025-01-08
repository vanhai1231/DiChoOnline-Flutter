import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class AddEditProductScreen extends StatefulWidget {
  final Map<dynamic, dynamic>? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('products');

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _imageController;
  late TextEditingController _categoryController;
  late String? _productId;
  String _selectedCategory = 'Chọn loại sản phẩm';
  bool _isCustomCategory = false;

  final List<String> _categories = [
    'Chọn loại sản phẩm',
    'Rau, củ, quả',
    'Thịt',
    'Đồ ăn nhanh',
    'Gia vị và đồ khô',
    'Thực phẩm đông lạnh',
  ];

  @override
  void initState() {
    super.initState();
    _productId = widget.product?['id'];
    _nameController = TextEditingController(text: widget.product?['product_name'] ?? '');
    _priceController = TextEditingController(text: widget.product?['price']?.toString() ?? '');
    _imageController = TextEditingController(text: widget.product?['image'] ?? '');
    _categoryController = TextEditingController(
      text: widget.product?['category'] ?? '', // Nếu có category thì load vào
    );
    _selectedCategory = widget.product?['category'] ?? 'Chọn loại sản phẩm';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final category = _isCustomCategory ? _categoryController.text : _selectedCategory;
      if (category.isEmpty || category == 'Chọn loại sản phẩm') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn hoặc nhập loại sản phẩm.')),
        );
        return;
      }

      final product = {
        'id': _productId ?? _database.push().key,
        'product_name': _nameController.text,
        'price': int.parse(_priceController.text),
        'image': _imageController.text,
        'category': category,
      };

      if (_productId == null) {
        // Thêm mới sản phẩm
        await _database.child(product['id'] as String).set(product);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm sản phẩm mới thành công.')),
        );
      } else {
        // Cập nhật sản phẩm
        await _database.child(_productId!).update(product);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật sản phẩm thành công.')),
        );
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Thêm sản phẩm' : 'Chỉnh sửa sản phẩm'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên sản phẩm';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Giá sản phẩm'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập giá sản phẩm';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Vui lòng nhập số hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(labelText: 'URL hình ảnh'),
              ),
              const SizedBox(height: 16),
              // Dropdown chọn danh mục
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                    _isCustomCategory = value == 'Khác'; // Nếu chọn "Khác", bật ô nhập tùy chỉnh
                    if (!_isCustomCategory) {
                      _categoryController.text = '';
                    }
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Loại sản phẩm',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Ô nhập danh mục tùy chỉnh
              if (_isCustomCategory)
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Nhập danh mục tùy chỉnh'),
                  validator: (value) {
                    if (_isCustomCategory && (value == null || value.isEmpty)) {
                      return 'Vui lòng nhập loại sản phẩm';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveProduct,
                child: Text(widget.product == null ? 'Thêm sản phẩm' : 'Cập nhật sản phẩm'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
