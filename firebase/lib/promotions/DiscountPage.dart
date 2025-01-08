
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class DiscountPage extends StatefulWidget {
  @override
  _DiscountPageState createState() => _DiscountPageState();
}

class _DiscountPageState extends State<DiscountPage> {
  final _percentageController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('products');

  List<Map<dynamic, dynamic>> _products = [];
  List<String> selectedProducts = [];

  // Map to store grouped products by category
  Map<String, List<Map<dynamic, dynamic>>> _groupedProducts = {};

  // Load products and group them by category (with optimization)
  Future<void> _loadProducts() async {
    _database.orderByChild('category') // Order products by category

        .once() // Get data once
        .then((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _products = data.entries.map((e) => e.value as Map<dynamic, dynamic>).toList();

          // Group products by category
          _groupedProducts.clear();
          for (var product in _products) {
            String category = product['category'] ?? 'Uncategorized';
            if (_groupedProducts.containsKey(category)) {
              _groupedProducts[category]!.add(product);
            } else {
              _groupedProducts[category] = [product];
            }
          }
        });
      }
    }).catchError((error) {
      print("Error loading products: $error");
    });
  }

  @override
  void initState() {
    super.initState();
    // Load products data from Firebase on init
    _loadProducts();
  }

  // Method to check if all products in a category are selected
  bool _isAllSelectedInCategory(String category) {
    final productsInCategory = _groupedProducts[category] ?? [];
    return productsInCategory.every((product) => selectedProducts.contains(product['id']));
  }

  // Method to toggle selection of all products in a category
  void _toggleSelectAllInCategory(String category) {
    final productsInCategory = _groupedProducts[category] ?? [];
    setState(() {
      if (_isAllSelectedInCategory(category)) {
        // Deselect all products in the category
        for (var product in productsInCategory) {
          selectedProducts.remove(product['id']);
        }
      } else {
        // Select all products in the category
        for (var product in productsInCategory) {
          if (!selectedProducts.contains(product['id'])) {
            selectedProducts.add(product['id']);
          }
        }
      }
    });
  }

  // Method to show date picker for start and end dates
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (selectedDate != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(selectedDate);
    }
  }

  // Method to handle the "Save" button action
  // void _saveDiscountData() async {
  //   // Validate the inputs first
  //   if (_percentageController.text.isEmpty || _startDateController.text.isEmpty || _endDateController.text.isEmpty || selectedProducts.isEmpty) {
  //     // Show an error message if any field is empty or no products are selected
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Please fill in all fields and select products')),
  //     );
  //     return;
  //   }
  //
  //   // Create the promotion data
  //   final discountPercentage = int.tryParse(_percentageController.text) ?? 0;
  //   final startDate = _startDateController.text;
  //   final endDate = _endDateController.text;
  //
  //   // Generate a new promotion ID using Firebase's push() method
  //   final promotionRef = FirebaseDatabase.instanceFor(
  //     app: Firebase.app(),
  //     databaseURL: 'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
  //   ).ref('promotions').push();
  //
  //   // Create the promotion object
  //   final promotionData = {
  //     'discountPercent': discountPercentage,
  //     'startDate': startDate,
  //     'endDate': endDate,
  //     'products': selectedProducts,
  //   };
  //
  //   // Save the promotion data to the database
  //   promotionRef.set(promotionData).then((_) {
  //     // Success! Show a success message
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Discount promotion saved successfully!')),
  //     );
  //
  //     // Clear the input fields and selected products after saving
  //     setState(() {
  //       _percentageController.clear();
  //       _startDateController.clear();
  //       _endDateController.clear();
  //       selectedProducts.clear();
  //     });
  //   }).catchError((error) {
  //     // Error saving the promotion
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error saving promotion: $error')),
  //     );
  //   });
  // }

  void _saveDiscountData() async {
    // Kiểm tra các trường nhập liệu, nếu có trường nào trống hoặc chưa chọn sản phẩm thì hiển thị thông báo lỗi
    if (_percentageController.text.isEmpty || _startDateController.text.isEmpty || _endDateController.text.isEmpty || selectedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng điền đầy đủ thông tin và chọn sản phẩm')),
      );
      return;
    }

    // Lấy giá trị giảm giá, ngày bắt đầu và ngày kết thúc từ các trường nhập liệu
    final discountPercentage = int.tryParse(_percentageController.text) ?? 0;
    final startDate = _startDateController.text;
    final endDate = _endDateController.text;

    // Lấy tham chiếu đến Firebase Realtime Database
    final promotionRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref('promotions');

    // Kiểm tra xem đã có chương trình khuyến mãi nào cho các sản phẩm đã chọn hay chưa
    final snapshot = await promotionRef.get();

    bool isUpdated = false; // Biến để theo dõi xem có cập nhật chương trình khuyến mãi hay không

    // Kiểm tra từng chương trình khuyến mãi đã có trong cơ sở dữ liệu
    for (var promoEntry in snapshot.children) {
      final existingPromotion = promoEntry.value as Map<dynamic, dynamic>;
      final products = existingPromotion['products'];

      if (products != null && products is List<dynamic>) {
        // Tiến hành xử lý khi 'products' có giá trị và đúng kiểu List
        for (var productId in selectedProducts) {
          if (products.contains(productId)) {
            // Cập nhật chương trình khuyến mãi
            promotionRef.child(promoEntry.key!).update({
              'discountPercent': discountPercentage,
              'startDate': startDate,
              'endDate': endDate,
              'products': selectedProducts,
            }).then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(
                    'Cập nhật chương trình khuyến mãi thành công!')),
              );
              setState(() {
                _percentageController.clear();
                _startDateController.clear();
                _endDateController.clear();
                selectedProducts.clear();
              });
            }).catchError((error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(
                    'Lỗi khi cập nhật chương trình khuyến mãi: $error')),
              );
            });
            isUpdated = true;
            break;
          }
        }
      }
    }

    // Nếu không tìm thấy chương trình khuyến mãi cũ thì tạo chương trình khuyến mãi mới
    if (!isUpdated) {
      final newPromotionRef = promotionRef.push();  // Tạo khóa mới cho chương trình khuyến mãi
      final promotionData = {
        'discountPercent': discountPercentage,  // Tỷ lệ giảm giá
        'startDate': startDate,  // Ngày bắt đầu
        'endDate': endDate,  // Ngày kết thúc
        'products': selectedProducts,  // Danh sách sản phẩm tham gia chương trình khuyến mãi
      };

      // Lưu chương trình khuyến mãi mới vào cơ sở dữ liệu
      newPromotionRef.set(promotionData).then((_) {
        // Thông báo thành công khi lưu dữ liệu mới
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chương trình khuyến mãi đã được lưu thành công!')),
        );

        // Xóa dữ liệu sau khi lưu thành công
        setState(() {
          _percentageController.clear();
          _startDateController.clear();
          _endDateController.clear();
          selectedProducts.clear();
        });
      }).catchError((error) {
        // Hiển thị lỗi nếu việc lưu dữ liệu không thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu chương trình khuyến mãi: $error')),
        );
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Discount Page'),
        actions: [
          // "Save" button on the right side of the AppBar
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveDiscountData,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Discount percentage input
            TextField(
              controller: _percentageController,
              decoration: InputDecoration(
                labelText: 'Discount Percentage (%)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),

            // Start date input
            TextField(
              controller: _startDateController,
              decoration: InputDecoration(
                labelText: 'Start Date',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context, _startDateController),
                ),
              ),
            ),
            SizedBox(height: 16),

            // End date input
            TextField(
              controller: _endDateController,
              decoration: InputDecoration(
                labelText: 'End Date',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context, _endDateController),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Display products and allow selection
            Expanded(
              child: _products.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : ListView(
                children: _groupedProducts.keys.map((category) {
                  return ExpansionTile(
                    title: Row(
                      children: [
                        Text(category),
                        Spacer(),
                        IconButton(
                          icon: Icon(
                            _isAllSelectedInCategory(category)
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                          ),
                          onPressed: () {
                            _toggleSelectAllInCategory(category);
                          },
                        ),
                      ],
                    ),
                    children: _groupedProducts[category]!.map((product) {
                      return ListTile(
                        title: Text(product['product_name'] ?? 'No Name'),
                        subtitle: Text(
                          'Price: ${product['price']} | Category: ${product['category']}',
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            selectedProducts.contains(product['id'])
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                          ),
                          onPressed: () {
                            setState(() {
                              if (selectedProducts.contains(product['id'])) {
                                selectedProducts.remove(product['id']);
                              } else {
                                selectedProducts.add(product['id']);
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
