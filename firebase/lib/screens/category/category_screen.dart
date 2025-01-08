import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

// import 'package:googleapis/sheets/v4.dart';
import '../details/detail_screen.dart';
import 'package:intl/intl.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryName;

  const CategoryScreen({Key? key, required this.categoryName})
      : super(key: key);

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Map<String, dynamic>> _products = []; // Dữ liệu sản phẩm theo danh mục
  bool _isLoading = true;
  final _promotionsRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('promotions');

  final _reviewsRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('reviews');
  Map<dynamic, dynamic> _reviews = {};

  @override
  void initState() {
    super.initState();
    _loadCategoryProducts();
    _loadPromotions();
    _loadReviews();
  }

  void _loadReviews() async {
    try {
      final snapshot = await _reviewsRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        print("Reviews data: $data"); // In dữ liệu để kiểm tra
        // Kiểm tra mounted trước khi gọi setState

        setState(() {
          _reviews = Map.fromEntries(data.entries);
        });
      }
    } catch (error) {
      print("Error loading reviews: $error");
    }
  }

  Map<dynamic, dynamic> _promotions = {};

  void _loadPromotions() async {
    try {
      final snapshot = await _promotionsRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        // Print the data to the console for inspection
        print("Promotions Data: $data");

        setState(() {
          // Convert Map values to List<Map<dynamic, dynamic> and update the UI
          _promotions =
              Map.fromEntries(data.entries); // Keep _promotions as Map
        });
      }
    } catch (error) {
      print("Error loading promotions: $error");
    }
  }

  Future<void> _loadCategoryProducts() async {
    final databaseRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref('products');

    try {
      // Lấy dữ liệu sản phẩm
      final snapshot = await databaseRef.get();
      // Lấy dữ liệu chương trình khuyến mãi
      final promotionsSnapshot = await _promotionsRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> loadedProducts = [];
        // Lấy dữ liệu khuyến mãi
        final promotionsData = promotionsSnapshot.exists
            ? promotionsSnapshot.value as Map<dynamic, dynamic>
            : {};
        data.forEach((key, value) {
          final product = value as Map<dynamic, dynamic>;

          if (product["category"] == widget.categoryName) {
            double price = product['price'] is String
                ? double.tryParse(product['price']) ?? 0.0
                : (product['price'] is int
                ? (product['price'] as int).toDouble()
                : (product['price'] is double ? product['price'] : 0.0));
            double originalPrice = price;
            double discountPercent = 0.0; // Biến để lưu phần trăm giảm giá
            // Kiểm tra nếu có chương trình khuyến mãi cho sản phẩm này
            if (promotionsData.isNotEmpty) {
              promotionsData.forEach((promoKey, promoValue) {
                final promotion = promoValue as Map<dynamic, dynamic>;
                final products = promotion['products'] as List<dynamic>?;
                // Lấy discountPercent từ chương trình khuyến mãi và chuyển đổi từ String nếu cần
                double currentDiscountPercent =
                    promotion['discountPercent'] is String
                        ? double.tryParse(promotion['discountPercent']) ?? 0.0
                        : (promotion['discountPercent'] is int
                            ? (promotion['discountPercent'] as int).toDouble()
                            : promotion['discountPercent'] ?? 0.0);

                if (products != null && products.contains(product["id"])) {
                  // Kiểm tra nếu chương trình khuyến mãi còn hiệu lực
                  if (DateTime.now()
                          .isAfter(DateTime.parse(promotion['startDate'])) &&
                      DateTime.now()
                          .isBefore(DateTime.parse(promotion['endDate']))) {
                    discountPercent = currentDiscountPercent;
                    price = originalPrice -
                        (originalPrice *
                            discountPercent /
                            100); // Áp dụng giảm giá
                  }
                }
              });
            }
            loadedProducts.add({
              "id": product["id"] ?? "",
              "image": product["image"] ?? "",
              "product_name": product["product_name"] ?? "Không có tên",
              "price": originalPrice,
              "discountPercent": discountPercent, // Lưu phần trăm giảm giá
              "originalPrice": price, // Store the original price
              "category": product["category"] ?? "",
            });
          }
        });

        setState(() {
          _products = loadedProducts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _products = [];
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
      );
      print('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
      ),
      body: Column(
        children: [
          _buildFilterBar(), // Thanh công cụ lọc
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(
                        child: Text(
                          "Không có sản phẩm nào trong danh mục này.",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          return _buildProductCard(_products[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      color: Colors.grey[100],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () {
              // Xử lý lọc
            },
            icon: const Icon(Icons.filter_list),
            label: const Text("Lọc theo"),
          ),
          TextButton.icon(
            onPressed: () {
              // Xử lý loại hàng
            },
            icon: const Icon(Icons.category),
            label: const Text("Loại hàng"),
          ),
          TextButton.icon(
            onPressed: () {
              // Xử lý tự đến lấy
            },
            icon: const Icon(Icons.store),
            label: const Text("Tự đến lấy"),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    // Lấy giá gốc và giá sale
    double originalPrice = (product["originalPrice"] != null)
        ? (product["originalPrice"] as double)
        : 0.0;
    double price = product['price'];
    String formattedDiscountPercent = product['discountPercent'] is double
        ? (product['discountPercent'] == product['discountPercent'].toInt()
            ? product['discountPercent']
                .toInt()
                .toString() // Show as integer if it's a whole number
            : product['discountPercent']
                .toString()) // Otherwise, show as a decimal
        : product['discountPercent'].toString();

    // Sử dụng NumberFormat để hiển thị giá với dấu phân cách hàng nghìn
    String formattedOriginalPrice =
        NumberFormat('#,###', 'vi_VN').format(originalPrice);
    String formattedSalePrice = NumberFormat('#,###', 'vi_VN').format(price);

    // Retrieve the average rating and total reviews for the product
    int totalReviews = 0;
    double averageRating = 0.0;

    _reviews.forEach((reviewId, review) {
      if (review['productId']?.toString() == product['id'].toString()) {
        // If the productId in the review matches the current product
        totalReviews += 1;
        averageRating += (review['productRating']?.toDouble() ?? 0.0);
      }
    });

    if (totalReviews > 0) {
      averageRating /= totalReviews; // Calculate average rating
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            product['image'],
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[200],
              width: 80,
              height: 80,
              child: const Icon(Icons.broken_image, size: 50),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product['product_name'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

              child: (product['discountPercent'] != null &&
                      product['discountPercent'] is num &&
                      (product['discountPercent'] as num) > 0)
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${(product['discountPercent'] as num).toStringAsFixed(0)}%',
                        // Display percentage as integer
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Container(), // If discountPercent is null or less than 0, show nothing
            ), // If discountPercent is null or less than 0, show nothing

            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 14),
                Text(
                  '${averageRating.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (totalReviews > 0)
                  Text(
                    '($totalReviews đánh giá)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                const Spacer(),
                // Icon(Icons.favorite_border, color: Colors.grey, size: 14),
              ],
            ),
            const SizedBox(height: 4),

            Row(
              children: [
                // Hiển thị giá gốc với gạch chéo
                if (originalPrice != price) ...[
                  Text(
                    "$formattedSalePrice₫",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey, // Màu xám cho giá gốc
                      decoration: TextDecoration.lineThrough, // Gạch chéo
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Khoảng cách giữa giá gốc và giá sale
                ],
                // Hiển thị giá sale
                Text(
                  "$formattedOriginalPrice₫",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red, // Màu đỏ cho giá sale
                  ),
                ),
              ],
            ),
          ],
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.delivery_dining, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            const Text(
              "15 phút",
              // Thời gian giao hàng giả định (có thể thay đổi theo dữ liệu)
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text(
                "Giảm 50K", // Tag khuyến mãi giả định
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text(
                "Free ship", // Tag miễn phí giao hàng
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          // Trước khi truyền sản phẩm sang DetailScreen, chuyển giá trị price sang int

          // Trước khi truyền sản phẩm sang DetailScreen, chuyển giá trị price sang int
          if (product['price'] is double) {
            // Nếu price là double, chuyển thành int
            product['price'] = (product['price'] as double).toInt();
          } else if (product['price'] is int) {
            // Nếu price đã là int, không cần chuyển đổi
            product['price'] = product['price'] as int;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailScreen(product: product),
            ),
          );
        },
      ),
    );
  }
}
