import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final DatabaseReference dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
    'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();
  Map<String, dynamic>? order;
  bool isLoading = true;

  // Danh sách trạng thái đơn hàng
  final Map<String, String> orderStatuses = {
    "Pending": "Đang chờ xử lý",
    "Processing": "Xác nhận giao hàng",
    "Completed": "Hoàn thành",
    "Cancelled": "Đã hủy",
  };

  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    fetchOrderDetails();
  }

  Future<void> fetchOrderDetails() async {
    try {
      final snapshot = await dbRef.child('orders/${widget.orderId}').get();

      if (snapshot.exists) {
        setState(() {
          order = Map<String, dynamic>.from(snapshot.value as Map); // Chuyển đổi dữ liệu
          selectedStatus = order!['status']; // Lấy trạng thái hiện tại
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        showErrorDialog('Không tìm thấy đơn hàng với ID: ${widget.orderId}');
      }
    } catch (e) {
      debugPrint('Lỗi khi tải chi tiết đơn hàng: $e');
      setState(() {
        isLoading = false;
      });
      showErrorDialog('Đã xảy ra lỗi khi tải chi tiết đơn hàng.');
    }
  }

  Future<void> updateOrderStatus(String newStatus) async {
    try {
      await dbRef.child('orders/${widget.orderId}').update({
        'status': newStatus,
      });

      setState(() {
        selectedStatus = newStatus; // Cập nhật trạng thái trong UI
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text('Cập nhật trạng thái đơn hàng thành công: ${orderStatuses[newStatus]}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Lỗi khi cập nhật trạng thái đơn hàng: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật trạng thái đơn hàng thất bại!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat("#,##0", "en_US");

    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết đơn hàng #${widget.orderId}'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : order == null
          ? const Center(child: Text('Không tìm thấy chi tiết đơn hàng.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin khách hàng
            Text(
              'Thông tin khách hàng',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Tên: ${order!['customerName']}'),
            Text('Số điện thoại: ${order!['phone']}'),
            Text('Địa chỉ: ${order!['address']}'),
            const Divider(height: 32),

            // Danh sách sản phẩm
            Text(
              'Danh sách sản phẩm',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: (order!['items'] as List).length,
              itemBuilder: (context, index) {
                // Chuyển đổi từng phần tử của danh sách sản phẩm
                final item = Map<String, dynamic>.from(
                  (order!['items'] as List)[index] as Map,
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hình ảnh sản phẩm
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          item['image'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Thông tin sản phẩm
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Số lượng: ${item['quantity']}'),
                            const SizedBox(height: 4),
                            Text(
                              'Giá: ${currencyFormat.format(item['price'])} ₫',
                              style: const TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const Divider(height: 32),

            // Tổng tiền
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng tiền:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${currencyFormat.format(order!['total'])} ₫',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            // Cập nhật trạng thái
            Text(
              'Cập nhật trạng thái đơn hàng',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              items: orderStatuses.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value), // Hiển thị tiếng Việt
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  updateOrderStatus(value);
                }
              },
              decoration: InputDecoration(
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
