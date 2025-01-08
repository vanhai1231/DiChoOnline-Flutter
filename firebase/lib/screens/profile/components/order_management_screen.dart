
import 'package:animate_do/animate_do.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../../reviews/ProductReviewScreen.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
    'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('orders');

  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final ordersSnapshot =
      await _database.orderByChild('userId').equalTo(user!.uid).get();

      if (ordersSnapshot.exists) {
        final Map<dynamic, dynamic> ordersData =
        ordersSnapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> fetchedOrders = ordersData.entries
            .map((entry) => {
          "id": entry.key as String,
          ...Map<String, dynamic>.from(entry.value as Map)
        })
            .toList();

        setState(() {
          orders = fetchedOrders;
        });
      } else {
        setState(() {
          orders = [];
        });
      }
    } catch (e) {
      print("Lỗi khi tải danh sách đơn hàng: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  String getOrderStatus(String status) {
    switch (status) {
      case 'Pending':
        return 'Đang chờ xử lý';
      case 'Processing':
        return 'Xác nhận giao hàng';
      case 'Completed':
        return 'Hoàn thành';
      case 'Cancelled':
        return 'Đã hủy';
      default:
        return status; // Giữ nguyên nếu trạng thái không nằm trong danh sách
    }
  }

  Color getOrderStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orangeAccent;
      case 'Processing':
        return Colors.blueAccent;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey; // Màu mặc định nếu trạng thái không nằm trong danh sách
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý đơn hàng"),
        backgroundColor: Colors.greenAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? _buildEmptyOrders()
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return FadeInUp(
            duration: Duration(milliseconds: 200 * (index + 1)),
            child: Card(
              margin: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: 5.0,
              child: ListTile(
                contentPadding: const EdgeInsets.all(12.0),
                leading: CircleAvatar(
                  backgroundColor: Colors.greenAccent.shade100,
                  radius: 30,
                  child: Icon(
                    Icons.shopping_cart,
                    color: Colors.greenAccent.shade700,
                  ),
                ),
                title: Text(
                  "Đơn hàng #${order['id']}",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Text(
                      "Tổng tiền: ${NumberFormat("#,##0", "vi_VN").format(order['total'])} VNĐ",
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 5),
                    Chip(
                      label: Text(
                        getOrderStatus(order['status']),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: getOrderStatusColor(order['status']),
                    ),

                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          OrderDetailsScreen(order: order),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyOrders() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 100,
            color: Colors.greenAccent,
          ),
          const SizedBox(height: 20),
          const Text(
            "Bạn chưa có đơn hàng nào!",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Hãy đặt hàng và quản lý đơn hàng của bạn\nngay tại đây.",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              "Quay lại mua sắm",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}
class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool hasReview = false;  // Declare it as a mutable variable

  Future<Map<String, dynamic>?> _getProductReview(String orderId, String productId) async {
    try {
      final reviewsRef = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
      ).ref('reviews');
      final snapshot = await reviewsRef.orderByChild('orderId').equalTo(orderId).get();

      if (snapshot.exists) {
        final reviews = Map<String, dynamic>.from(snapshot.value as Map);
        for (final review in reviews.values) {
          final reviewMap = Map<String, dynamic>.from(review as Map);
          if (reviewMap['productId'] == productId && reviewMap['orderId'] == orderId) {
            return reviewMap;
          }
        }
      }
    } catch (e) {
      print('Error fetching review: $e');
    }
    return null;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Chi tiết đơn hàng #${widget.order['id']}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.greenAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeIn(
                duration: const Duration(milliseconds: 500),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.greenAccent),
                            const SizedBox(width: 10),
                            const Text(
                              "Tên khách hàng:",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.order['customerName'] ?? 'Chưa có thông tin',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Colors.redAccent),
                            const SizedBox(width: 10),
                            const Text(
                              "Địa chỉ:",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.order['address'] ?? 'Chưa có thông tin',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.phone, color: Colors.blueAccent),
                            const SizedBox(width: 10),
                            const Text(
                              "Số điện thoại:",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.order['phone'] ?? 'Chưa có thông tin',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeIn(
                duration: const Duration(milliseconds: 600),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Danh sách sản phẩm",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Divider(thickness: 1, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        ListView.separated(
                          itemCount: (widget.order['items'] as List).length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final item = (widget.order['items'] as List)[index];
                            return FutureBuilder<Map<String, dynamic>?>(
                              future: _getProductReview(widget.order['id'], item['productId']),
                              builder: (context, snapshot) {
                                var hasReview = snapshot.hasData && snapshot.data != null;

                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          item['image'],
                                          height: 60,
                                          width: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              height: 60,
                                              width: 60,
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.image_not_supported),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['title'],
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Số lượng: ${item['quantity']}",
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            Text(
                                              "${NumberFormat("#,##0", "vi_VN").format(item['price'])} VNĐ",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.blueAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 100,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: hasReview ? Colors.blue : Colors.greenAccent,
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                          ),
                                          onPressed: () {
                                            if (hasReview) {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: Row(
                                                    children: [
                                                      const Icon(Icons.star, color: Colors.amber),
                                                      const SizedBox(width: 8),
                                                      const Text('Chi tiết đánh giá'),
                                                    ],
                                                  ),
                                                  content: SingleChildScrollView(
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        _buildRatingRow('Sản phẩm', snapshot.data!['productRating']),
                                                        _buildRatingRow('Dịch vụ', snapshot.data!['sellerServiceRating']),
                                                        _buildRatingRow('Giao hàng', snapshot.data!['deliveryRating']),
                                                        const Divider(),
                                                        Text(
                                                          'Nhận xét:',
                                                          style: TextStyle(fontWeight: FontWeight.bold),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(snapshot.data!['review']),

                                                      ],
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      child: const Text('Đóng'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            } else {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ProductReviewScreen(
                                                    orderId: widget.order['id'],
                                                    productId: item['productId'],
                                                    title: item['title'],
                                                    price: item['price'].toDouble(),
                                                    quantity: item['quantity'],
                                                    image: item['image'],
                                                  ),
                                                ),
                                              ).then((_) {
                                                // After review submission, fetch the updated review status
                                                setState(() {
                                                  hasReview = true; // Update the status of hasReview
                                                });
                                              });
                                            }
                                          },
                                          child: Text(
                                            hasReview ? 'Xem đánh giá' : 'Đánh giá',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeIn(
                duration: const Duration(milliseconds: 700),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tổng thanh toán:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Tổng tiền:",
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              "${NumberFormat("#,##0", "vi_VN").format(widget.order['total'])} VNĐ",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Phương thức thanh toán:",
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              widget.order['paymentMethod'] ?? 'Chưa rõ',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildRatingRow(String label, dynamic rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: List.generate(
              5,
                  (index) => Icon(
                index < (rating ?? 0) ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 20,
              ),
            ),
          ),
          Text(' ${rating ?? 0}/5'),
        ],
      ),
    );
  }
}


