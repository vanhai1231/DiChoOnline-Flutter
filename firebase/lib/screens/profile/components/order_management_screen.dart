import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
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
      print("Không tìm thấy người dùng hiện tại.");
      return;
    }

    try {
      print("Đang tải đơn hàng cho userId: ${user!.uid}");

      // Kiểm tra toàn bộ dữ liệu trong nhánh orders
      final snapshot = await _database.get();
      if (snapshot.exists) {
        print("Dữ liệu toàn bộ orders: ${snapshot.value}");
      } else {
        print("Không có dữ liệu trong nhánh orders.");
      }

      // Truy vấn danh sách đơn hàng theo userId
      final ordersSnapshot = await _database
          .orderByChild('userId')
          .equalTo(user!.uid)
          .get();

      if (ordersSnapshot.exists) {
        print("Dữ liệu đơn hàng từ Firebase: ${ordersSnapshot.value}");

        // Chuyển đổi dữ liệu Firebase thành danh sách
        final Map<dynamic, dynamic> ordersData =
        ordersSnapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> fetchedOrders = ordersData.entries
            .map((entry) =>
        {"id": entry.key as String, ...Map<String, dynamic>.from(entry.value as Map)})
            .toList();

        setState(() {
          orders = fetchedOrders;
        });
      } else {
        print("Không tìm thấy đơn hàng.");
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
          ? Center(
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
      )
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 4.0,
            child: ListTile(
              title: Text("Đơn hàng #${order['id']}"),
              subtitle: Text(
                "Tổng tiền: ${NumberFormat("#,##0", "vi_VN").format(order['total'])} VNĐ\n"
                    "Phương thức: ${order['paymentMethod']}\n"
                    "Trạng thái: ${order['status']}",
              ),
              isThreeLine: true,
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
          );
        },
      ),
    );
  }
}

class OrderDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chi tiết đơn hàng #${order['id']}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tên khách hàng: ${order['customerName']}",
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Địa chỉ: ${order['address']}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Số điện thoại: ${order['phone']}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              "Danh sách sản phẩm:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: (order['items'] as List).length,
                itemBuilder: (context, index) {
                  final item = (order['items'] as List)[index];
                  return ListTile(
                    title: Text(item['title']),
                    subtitle: Text(
                      "Số lượng: ${item['quantity']} - Giá: ${NumberFormat("#,##0", "vi_VN").format(item['price'])} VNĐ",
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Tổng tiền: ${NumberFormat("#,##0", "vi_VN").format(order['total'])} VNĐ",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
