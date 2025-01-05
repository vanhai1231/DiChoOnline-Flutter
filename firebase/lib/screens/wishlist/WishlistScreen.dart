import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

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

  @override
  void initState() {
    super.initState();
    fetchWishlistItems();
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
              "id": key,
              "title": product['product_name'],
              "price": product['price'],
              "image": product['image'],
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
          ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
            },
            child: const Text(
              "Mua sắm ngay",
              style: TextStyle(fontSize: 16, color: Colors.green),
            ),
          ),
        ],
      )
          : GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 0.8,
        ),
        itemCount: wishlistItems.length,
        itemBuilder: (context, index) {
          var product = wishlistItems[index];
          bool isFavorite = wishlistItems
              .any((item) => item['productId'] == product['productId']);

          return GestureDetector(
            onTap: () {
              // Điều hướng đến trang chi tiết sản phẩm
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 4.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12.0),
                    ),
                    child: Image.network(
                      product['image'] ?? 'https://via.placeholder.com/150',
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['title'] ?? 'Không có tên',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${currencyFormat.format(product['price'])} ₫",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons
                                    .favorite_border,
                                color: isFavorite ? Colors.red : Colors.grey,
                              ),
                              onPressed: () {
                                _toggleFavorite(product['productId']);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
