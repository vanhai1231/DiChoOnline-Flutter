import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
    'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('orders');
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final snapshot = await _database.orderByChild('userId').equalTo(user!.uid).get();

      setState(() {
        notifications = [];  // Reset list trước khi thêm dữ liệu mới

        if (snapshot.exists && snapshot.value != null) {
          final data = snapshot.value;
          if (data is Map) {
            data.forEach((key, value) {
              if (value is Map) {
                notifications.add({
                  "id": key,
                  ...Map<String, dynamic>.from(value),
                });
              }
            });
            notifications = notifications.reversed.toList();
          }
        }

        isLoading = false;
      });

    } catch (e) {
      debugPrint("Lỗi khi tải thông báo: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? const Center(
        child: Text(
          'Không có thông báo nào!',
          style: TextStyle(fontSize: 16.0, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return NotificationCard(
            timestamp: notification['timestamp'],
            status: notification['status'],
            total: notification['total'],
            address: notification['address'],
            items: notification['items'],
          );
        },
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String timestamp;
  final String status;
  final int total;
  final String address;
  final List<dynamic> items;

  const NotificationCard({
    super.key,
    required this.timestamp,
    required this.status,
    required this.total,
    required this.address,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    // Format ngày giờ
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm')
        .format(DateTime.parse(timestamp)); // Chuyển timestamp thành ngày giờ

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thời gian và trạng thái
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12.0,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: status == 'Pending' ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            // Tổng tiền
            Text(
              "Tổng tiền: ${NumberFormat("#,##0", "vi_VN").format(total)} VNĐ",
              style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8.0),
            // Địa chỉ
            Text(
              "Địa chỉ: $address",
              style: const TextStyle(
                fontSize: 12.0,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8.0),
            // Danh sách sản phẩm
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) {
                return Text(
                  "- ${item['title']} x${item['quantity']}",
                  style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
