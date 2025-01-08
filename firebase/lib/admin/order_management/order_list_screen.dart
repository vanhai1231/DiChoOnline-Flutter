import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
    'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  bool isLoading = true;

  // Danh sách trạng thái và trạng thái được chọn
  final Map<String, String> orderStatuses = {
    "Tất cả": "all",
    "Đang chờ xử lý": "Pending",
    "Xác nhận giao hàng": "Processing",
    "Hoàn thành": "Completed",
    "Đã hủy": "Cancelled",
  };
  String selectedStatus = "all";

  @override
  void initState() {
    super.initState();
    fetchAllOrders();
  }

  Future<void> fetchAllOrders() async {
    try {
      final snapshot = await dbRef.child('orders').get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> orderList = [];
        data.forEach((key, value) {
          orderList.add({
            'id': key,
            ...value,
          });
        });

        setState(() {
          orders = orderList.reversed.toList();
          filteredOrders = orders; // Hiển thị tất cả đơn hàng ban đầu
        });
      }
    } catch (e) {
      debugPrint("Lỗi khi tải đơn hàng: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterOrders(String status) {
    setState(() {
      if (status == "all") {
        filteredOrders = orders; // Hiển thị tất cả
      } else {
        filteredOrders =
            orders.where((order) => order['status'] == status).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đơn hàng'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // Thanh lọc trạng thái
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: selectedStatus,
              items: orderStatuses.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.value,
                  child: Text(entry.key),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedStatus = value;
                  });
                  filterOrders(value);
                }
              },
              decoration: InputDecoration(
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                labelText: "Lọc theo trạng thái",
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredOrders.isEmpty
                ? const Center(
              child: Text(
                "Không có đơn hàng phù hợp!",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w500),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final order = filteredOrders[index];
                final formattedDate = DateFormat("yyyy-MM-dd HH:mm:ss")
                    .format(DateTime.parse(order['timestamp']));

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15.0),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/order-detail',
                        arguments: order['id'].toString(),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mã đơn hàng và trạng thái
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  "Mã đơn hàng: #${order['id']}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  order['status'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: _getStatusColor(
                                    order['status']),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Ngày đặt
                          Text(
                            "Ngày đặt: $formattedDate",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Thông tin khách hàng
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              Text(
                                "Khách hàng: ${order['customerName']}",
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                "Địa chỉ: ${order['address']}",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Tổng tiền
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Tổng cộng:",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${NumberFormat("#,##0", "en_US").format(order['total'])} ₫",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Hàm trả về màu sắc theo trạng thái đơn hàng
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
