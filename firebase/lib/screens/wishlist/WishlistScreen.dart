import 'package:firebase/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../../entry_point.dart';
import '../details/detail_screen.dart';

class WishlistDetailsScreen extends StatefulWidget {
  const WishlistDetailsScreen({super.key});

  @override
  State<WishlistDetailsScreen> createState() => _WishlistDetailsScreenState();
}

class _WishlistDetailsScreenState extends State<WishlistDetailsScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final NumberFormat currencyFormat = NumberFormat("#,##0", "vi_VN");
  final DatabaseReference dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  List<Map<String, dynamic>> wishlistItems = [];
  bool isLoading = true;
  final _promotionsRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
    'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('promotions');
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
  @override
  void initState() {
    super.initState();
    fetchWishlistItems();
    _loadPromotions();
  }

  Future<void> fetchWishlistItems() async {
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final wishlistSnapshot =
      await dbRef.child('wishlist').orderByChild('userId')
          .equalTo(user!.uid)
          .get();
      final productSnapshot = await dbRef.child('products').get();

      if (wishlistSnapshot.exists && productSnapshot.exists) {
        Map wishlistData = wishlistSnapshot.value as Map;
        Map productData = productSnapshot.value as Map;

        List<Map<String, dynamic>> items = [];
        wishlistData.forEach((key, value) {
          if (productData.containsKey(value['productId'])) {
            final product = productData[value['productId']];
            items.add({
              "id": value['productId'], // Changed to match product ID
              "product_name": product['product_name'] ?? 'Không có tên',
              "price": product['price'] ?? 0,
              "image": product['image'] ?? 'https://via.placeholder.com/150',
              "image1": product['image1'],
              "category": product['category'] ?? 'Không có danh mục',
              "description": product['description'] ?? 'Không có mô tả',
              "quantity": product['quantity'] ?? 0,
              "productId": value['productId'],
            });
          }
        });

        setState(() {
          wishlistItems = items;
        });
      }
    } catch (e) {
      debugPrint("Lỗi khi lấy danh sách yêu thích: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(String productId) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Bạn cần đăng nhập để sử dụng danh sách yêu thích.")),
      );
      return;
    }

    final wishlistRef = dbRef.child('wishlist');
    final userWishlistRef = wishlistRef.orderByChild('userId').equalTo(
        user!.uid);
    final snapshot = await userWishlistRef.get();

    if (snapshot.exists) {
      Map<dynamic, dynamic> wishlistData = snapshot.value as Map<
          dynamic,
          dynamic>;

      bool productExists = false;
      String? existingWishlistKey;
      wishlistData.forEach((key, value) {
        if (value['productId'] == productId) {
          productExists = true;
          existingWishlistKey = key;
        }
      });

      if (productExists) {
        await wishlistRef.child(existingWishlistKey!).remove();

        setState(() {
          wishlistItems = wishlistItems
              .where((item) => item['productId'] != productId)
              .toList();
        });
        final String apiUrl = 'http://172.20.10.4:8000/favorites/${user
            ?.uid}/$productId';

        final response = await http.delete(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Đã xóa sản phẩm khỏi danh sách yêu thích!")),
        );

        fetchWishlistItems();
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh sách yêu thích"),
        backgroundColor: Colors.greenAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : wishlistItems.isEmpty
          ? Center(  // Ensure this is centered properly
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,  // Center horizontally as well
          children: [
            Icon(Icons.favorite_border, size: 100, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              "Danh sách yêu thích của bạn trống.",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                // Điều hướng sang màn hình mua sắm
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EntryPoint(),
                  ),
                );
              },
              child: const Text(
                "Mua sắm ngay",
                style: TextStyle(fontSize: 16, color: Colors.green),
              ),
            ),
          ],
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 0.75,
        ),
        itemCount: wishlistItems.length,
        itemBuilder: (context, index) {
          var product = wishlistItems[index];
          bool isFavorite = wishlistItems
              .any((item) => item['productId'] == product['productId']);
          int originalPrice = product['price'];
          int price = originalPrice;
          String discountPercentText = '';
          if (_promotions.isNotEmpty) {
            // Loop through each promotion
            for (var promoEntry in _promotions.entries) {
              final promotion = promoEntry.value;

              // Ensure the products list exists and is not null
              final products = promotion['products'];
              if (products != null &&
                  products is List &&
                  products.contains(product['id'].toString())) {
                // Check if the current product ID (as string) is in the promotion's 'products' list
                if (DateTime.now().isAfter(DateTime.parse(promotion['startDate'])) &&
                    DateTime.now().isBefore(DateTime.parse(promotion['endDate']))) {
                  final int discountPercent = promotion['discountPercent'];
                  price = originalPrice -
                      (originalPrice * discountPercent ~/ 100); // Calculate discounted price
                  discountPercentText = '$discountPercent%';
                  break; // Exit the loop once a matching promotion is found
                }
              }
            }
          }
          return GestureDetector(
            onTap: () {
              // Điều hướng đến trang chi tiết sản phẩm
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailScreen(product: product),
                ),
              );
            },
            child: Container(
              height: 500, // Set your desired height here
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
                ),
                elevation: 2.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'product-${product['productId']}',
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15.0),
                          ),
                          child: Image.network(
                            product['image'] ?? 'https://via.placeholder.com/150',
                            width: double.infinity, // Ensure image covers 100% width
                            height: 140, // Set fixed height for the image (doesn't affect the card height)
                            fit: BoxFit.cover, // Ensures the image covers the space
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['product_name'] ?? 'Không có tên',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (price != originalPrice) ...[
                                  Text(
                                    '${NumberFormat('#,###').format(originalPrice)} ₫',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey, // Original price color
                                      decoration:
                                      TextDecoration.lineThrough, // Strikethrough
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Space between original and discounted prices
                                ],
                                // Discounted price
                                Flexible(
                                  child: Text(
                                    '${NumberFormat('#,###').format(price)} ₫',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent, // Discounted price color
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (Widget child, Animation<double> animation) {
                                    return ScaleTransition(scale: animation, child: child);
                                  },
                                  child: IconButton(
                                    key: ValueKey<bool>(isFavorite),
                                    icon: Icon(
                                      isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: isFavorite ? Colors.red : Colors.grey,
                                    ),
                                    onPressed: () => _toggleFavorite(product['productId']),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}



