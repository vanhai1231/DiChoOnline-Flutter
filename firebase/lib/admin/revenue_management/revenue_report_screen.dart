import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';

class RevenueReportScreen extends StatefulWidget {
  const RevenueReportScreen({super.key});

  @override
  State<RevenueReportScreen> createState() => _RevenueReportScreenState();
}

class _RevenueReportScreenState extends State<RevenueReportScreen> {
  final dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
    'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  List<Map<String, dynamic>> completedOrders = [];
  bool isLoading = true;

  DateTime? selectedDate;
  DateTime? selectedMonth;

  double totalRevenueByDay = 0;
  double totalRevenueByMonth = 0;

  @override
  void initState() {
    super.initState();
    fetchCompletedOrders();
  }

  Future<void> fetchCompletedOrders() async {
    try {
      final snapshot = await dbRef.child('orders').get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> orders = [];
        data.forEach((key, value) {
          if (value['status'] == "Completed") {
            orders.add({
              'id': key,
              ...value,
            });
          }
        });

        setState(() {
          completedOrders = orders;
        });
      }
    } catch (e) {
      debugPrint("Lỗi khi tải dữ liệu đơn hàng: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void calculateRevenueByDay(DateTime date) {
    setState(() {
      selectedDate = date;
      final filteredOrders = completedOrders.where((order) {
        final orderDate = DateTime.parse(order['timestamp']);
        return orderDate.year == date.year &&
            orderDate.month == date.month &&
            orderDate.day == date.day;
      }).toList();

      debugPrint(
          "Đơn hàng trong ngày ${DateFormat('yyyy-MM-dd').format(date)}: $filteredOrders");

      totalRevenueByDay = filteredOrders
          .map((order) => (order['total'] as num).toDouble())
          .fold(0, (sum, item) => sum + item);
    });
  }

  void calculateRevenueByMonth(DateTime date) {
    setState(() {
      selectedMonth = date;
      final filteredOrders = completedOrders.where((order) {
        final orderDate = DateTime.parse(order['timestamp']);
        return orderDate.year == date.year && orderDate.month == date.month;
      }).toList();

      debugPrint(
          "Đơn hàng trong tháng ${DateFormat('yyyy-MM').format(date)}: $filteredOrders");

      totalRevenueByMonth = filteredOrders
          .map((order) => (order['total'] as num).toDouble())
          .fold(0, (sum, item) => sum + item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat("#,##0", "en_US");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo doanh thu'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : completedOrders.isEmpty
          ? const Center(
        child: Text(
          "Không có đơn hàng hoàn thành.",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Doanh thu theo ngày",
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        calculateRevenueByDay(pickedDate);
                      }
                    },
                    child: const Text("Chọn ngày"),
                  ),
                ),
              ],
            ),
            selectedDate != null
                ? Text(
              "Ngày đã chọn: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}",
              style: const TextStyle(
                  fontSize: 14, color: Colors.grey),
            )
                : const SizedBox(),
            const SizedBox(height: 8),
            Text(
              totalRevenueByDay > 0
                  ? "Doanh thu: ${currencyFormat.format(totalRevenueByDay)} ₫"
                  : "Không có doanh thu trong ngày đã chọn.",
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 32),
            const Text(
              "Doanh thu theo tháng",
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null) {
                        calculateRevenueByMonth(DateTime(
                            pickedDate.year, pickedDate.month));
                      }
                    },
                    child: const Text("Chọn tháng"),
                  ),
                ),
              ],
            ),
            selectedMonth != null
                ? Text(
              "Tháng đã chọn: ${DateFormat('yyyy-MM').format(selectedMonth!)}",
              style: const TextStyle(
                  fontSize: 14, color: Colors.grey),
            )
                : const SizedBox(),
            const SizedBox(height: 8),
            Text(
              totalRevenueByMonth > 0
                  ? "Doanh thu: ${currencyFormat.format(totalRevenueByMonth)} ₫"
                  : "Không có doanh thu trong tháng đã chọn.",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const Divider(height: 32),
            const Text(
              "Danh sách đơn hàng hoàn thành",
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: completedOrders.length,
              itemBuilder: (context, index) {
                final order = completedOrders[index];
                final formattedDate = DateFormat("yyyy-MM-dd HH:mm:ss")
                    .format(DateTime.parse(order['timestamp']));

                return Card(
                  margin:
                  const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 4,
                  child: ListTile(
                    title: Text("Mã đơn hàng: ${order['id']}"),
                    subtitle: Text("Ngày đặt: $formattedDate"),
                    trailing: Text(
                      "${currencyFormat.format(order['total'])} ₫",
                      style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
