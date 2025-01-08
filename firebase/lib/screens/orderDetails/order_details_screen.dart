import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../MoMoPaymentScreen.dart';
import '../../PaypalPaymentScreen.dart';
import '../../PaypalPaymentScreen.dart';
import '../../notifications/NotificationBadgeProvider.dart';
import '../profile/components/shipping_address_screen.dart';
import 'AddAddressScreen.dart';


class OrderDetailsScreen extends StatefulWidget {

  const OrderDetailsScreen({super.key});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  // lấy id ngươif dùng hiênj tại
  final user = FirebaseAuth.instance.currentUser;

  // định dạng tiền
  final NumberFormat currencyFormat = NumberFormat("#,##0", "en_US");

  // gọi database firebase realtime
  final DatabaseReference dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();
  String address = "Loading...";
  String phone = "Loading...";
  String customerName = "Loading...";

  bool isEditing = false;

  final _promotionsRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
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
          _promotions = Map.fromEntries(data.entries); // Keep _promotions as Map
        });
      }
    } catch (error) {
      print("Error loading promotions: $error");
    }
  }



// danh sách lưu các sản phẩm trong giỏ hàng
  List<Map<String, dynamic>> cartItems = [];

  //kiểm tra trạng thái load dữ liệu
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // lấy danh sách sản phẩm trong giỏ hàng khi màn hình được khởi tạo
    fetchCartItems();
    _loadUserData();
    _loadPromotions();
  }


  // Hàm tải dữ liệu người dùng từ Firebase
  Future<void> _loadUserData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      try {
        // Lấy dữ liệu người dùng từ Firebase
        final userRef =
            dbRef.child('users/$userId'); // Truy cập theo ID người dùng
        final snapshot = await userRef.get();

        if (snapshot.exists) {
          final data = snapshot.value as Map; // Lấy dữ liệu dạng Map

          setState(() {
            // Truy cập các giá trị trong Map
            customerName = data['name'] ??
                "Không có tên"; // Nếu không có giá trị thì lấy "Không có tên"
            address = data['address'] ?? "Không có địa chỉ";
            phone = data['phone'] ?? "Không có số điện thoại";
          });
        } else {
          // Nếu không có dữ liệu
          setState(() {
            customerName = "Không tìm thấy dữ liệu";
            address = "Không tìm thấy địa chỉ";
            phone = "Không tìm thấy số điện thoại";
          });
        }
      } catch (e) {
        debugPrint("Lỗi khi lấy dữ liệu: $e");
        setState(() {
          customerName = "Lỗi khi tải dữ liệu";
          address = "Lỗi khi tải dữ liệu";
          phone = "Lỗi khi tải dữ liệu";
        });
      }
    }
  }
  void _onSaveAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShippingAddressScreen(
          initialName: customerName,  // Pass current name
          initialAddress: address,    // Pass current address
          initialPhone: phone,        // Pass current phone number
        ),
      ),
    );

    // Kiểm tra xem người dùng có thay đổi địa chỉ không
    if (result == null) {
      // Gọi lại để làm mới dữ liệu người dùng
      _loadUserData();
    }
  }
  //giá góc
  Map<String, double> originalPrices = {};
  /// Lấy danh sách sản phẩm trong giỏ hàng từ Firebase Realtime Database.
  Future<void> fetchCartItems() async {
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      // Lấy dữ liệu giỏ hàng dựa trên userId của người dùng hiện tại
      final cartSnapshot = await dbRef
          .child('cart')
          .orderByChild('userId')
          .equalTo(user!.uid)
          .get();
      // Lấy thông tin tất cả sản phẩm từ cơ sở dữ liệu
      final productSnapshot = await dbRef.child('products').get();
      // Lấy thông tin chương trình khuyến mãi (nếu có)
      final promotionsSnapshot = await dbRef.child('promotions').get();

      // nếu giỏ hàng và sản phẩm tồn tại
      if (cartSnapshot.exists && productSnapshot.exists) {
        Map cartData = cartSnapshot.value as Map;
        Map productData = productSnapshot.value as Map;
        Map promotionsData = promotionsSnapshot.exists ? promotionsSnapshot.value as Map : {};

        /// Tạo danh sách sản phẩm trong giỏ hàng bằng cách kết hợp dữ liệu giỏ hàng và sản phẩm
        List<Map<String, dynamic>> items = [];
        cartData.forEach((key, value) {
          if (productData.containsKey(value['productId'])) {
            final product = productData[value['productId']];
            double price = product['price'].toDouble(); // Lấy giá gốc
            double originalPrice = price; // Save the original price

            // Store the original price in the global variable
            originalPrices[value['productId']] = originalPrice;

            // Kiểm tra nếu có chương trình khuyến mãi
            if (promotionsData.isNotEmpty) {
              for (var promoEntry in promotionsData.entries) {
                final promotion = promoEntry.value;
                final products = promotion['products'];

                if (products != null &&
                    products is List &&
                    products.contains(value['productId'].toString())) {
                  if (DateTime.now().isAfter(DateTime.parse(promotion['startDate'])) &&
                      DateTime.now().isBefore(DateTime.parse(promotion['endDate']))) {
                    final discountPercent = promotion['discountPercent'];
                    price -= (price * discountPercent / 100.0); // Áp dụng giảm giá
                    break;
                  }
                }
              }
            }

            // Thêm sản phẩm vào danh sách giỏ hàng
            items.add({
              "id": key,
              "originalPrice": originalPrice, // Store the original price
              "title": product['product_name'],
              "price": price, // Cập nhật giá với giá đã giảm
              "image": product['image'],
              "quantity": value['quantity'],
              "productId": value['productId'],

            });
          }
        });

        // Cập nhật trạng thái với danh sách sản phẩm đã lấy
        setState(() {
          cartItems = items;
        });
      }
    } catch (e) {
      debugPrint("Lỗi khi lấy danh sách sản phẩm trong giỏ hàng: $e");
    } finally {
      // Ngừng trạng thái tải dữ liệu bất kể thành công hay thất bại
      setState(() {
        isLoading = false;
      });
    }
  }


  /// update số lượng
  Future<void> updateQuantity(String itemId, int newQuantity) async {
    if (newQuantity < 1) return;

    try {
      // Lấy productId từ cart item để lấy số lượng tối đa từ bảng 'products'
      final productId =
          cartItems.firstWhere((item) => item['id'] == itemId)['productId'];

      // Lấy số lượng tối đa từ Firebase (products)
      final snapshot = await dbRef.child('products/$productId/quantity').get();
      if (snapshot.exists) {
        final int maxQuantity = snapshot.value as int;

        if (newQuantity > maxQuantity) {
          // Nếu số lượng mới lớn hơn số lượng tối đa, hiển thị thông báo lỗi
          showErrorDialog("Số lượng vượt quá số lượng có sẵn trong kho!");
          return;
        }

        // Cập nhật số lượng trong Firebase Realtime Database
        await dbRef.child('cart/$itemId').update({'quantity': newQuantity});

        // Cập nhật trạng thái để hiển thị số lượng mới trên giao diện
        setState(() {
          cartItems = cartItems.map((item) {
            if (item['id'] == itemId) {
              return {...item, 'quantity': newQuantity};
            }
            return item;
          }).toList();
        });
      } else {
        showErrorDialog("Không tìm thấy sản phẩm!");
      }
    } catch (e) {
      debugPrint("Lỗi khi cập nhật số lượng: $e");
    }
  }

  /// Hàm hiển thị thông báo lỗi
  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Lỗi"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  /// xóa sản phẩm khỏi giỏ hàng
  Future<void> removeItem(String itemId) async {
    try {
      // Xóa sản phẩm khỏi Firebase Realtime Database
      await dbRef.child('cart/$itemId').remove();
      //cập nhật trạng thái
      setState(() {
        cartItems = cartItems.where((item) => item['id'] != itemId).toList();
      });
    } catch (e) {
      debugPrint("Lỗi khi xóa sản phẩm: $e");
    }
  }

  /// hiển thị thông báo muốn xóa khi < 1
  void showDeleteConfirmationDialog(String itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa sản phẩm"),
        content:
            const Text("Bạn có muốn xóa sản phẩm này khỏi giỏ hàng không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Gọi hàm xóa sản phẩm
              removeItem(itemId);
            },
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }
  ///tinh tong tien
  double calculateTotal() {
    double total = 0;
    for (var item in cartItems) {
      total += item['price'] * item['quantity'];
    }
    return total;
  }



  Future<void> updateProductQuantities(List<Map<String, dynamic>> orderItems) async {
    try {
      // Tạo map để lưu các cập nhật
      Map<String, dynamic> updates = {};

      // Lấy thông tin hiện tại của sản phẩm
      for (var item in orderItems) {
        final productId = item['productId'];
        final orderedQuantity = item['quantity'];

        final snapshot = await dbRef.child('products/$productId/quantity').get();

        if (snapshot.exists) {
          final currentQuantity = snapshot.value as int;
          final newQuantity = currentQuantity - orderedQuantity;

          if (newQuantity < 0) {
            throw Exception('Số lượng sản phẩm ${item['title']} không đủ');
          }

          updates['products/$productId/quantity'] = newQuantity;
        }
      }

      // Thực hiện cập nhật một lần
      if (updates.isNotEmpty) {
        await dbRef.update(updates);
      }
    } catch (e) {
      debugPrint("Lỗi khi cập nhật số lượng sản phẩm: $e");
      rethrow;
    }
  }
  //clear cart
  Future<void> clearCart() async {
    if (user == null) return;

    try {
      // Get all cart item IDs for the current user
      final cartSnapshot = await dbRef
          .child('cart')
          .orderByChild('userId')
          .equalTo(user!.uid)
          .get();

      if (cartSnapshot.exists) {
        final cartData = cartSnapshot.value as Map;

        // Loop through each cart item and remove it
        cartData.forEach((key, value) async {
          await dbRef.child('cart/$key').remove();
        });

        // Optionally, update the UI to reflect the cart is cleared
        setState(() {
          cartItems.clear(); // Clear the cartItems list
        });
      }
    } catch (e) {
      debugPrint("Lỗi khi xóa sản phẩm trong giỏ hàng: $e");
    }
  }


  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  Future<void> _showOrderNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'order_success_channel',
      'Order Success',
      channelDescription: 'Thông báo khi đặt hàng thành công',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0, // ID của thông báo
      'Đặt hàng thành công!', // Tiêu đề
      'Đơn hàng của bạn đang trên đường!', // Nội dung
      notificationDetails,
    );
  }


  ///hàm lưu vào database và xóa cart
  Future<void> saveOrderToFirebase(double total, String method) async {
    if (user == null) {
      print("User is null, cannot place order");
      return;
    }

    try {
      // Danh sách các sản phẩm trong đơn hàng
      List<Map<String, dynamic>> orderItems = [];

      for (var item in cartItems) {
        // Trích xuất thông tin từ bảng sản phẩm nếu cần
        final productSnapshot = await dbRef.child('products/${item['productId']}').get();
        if (productSnapshot.exists) {
          final productData = productSnapshot.value as Map;



          orderItems.add({
            "productId": item['productId'],
            "title": productData['product_name'],
            "price": total,
            "image": productData['image'],
            "quantity": item['quantity'],
          });
        } else {
          print("Không tìm thấy sản phẩm với ID: ${item['productId']}");
        }
      }



      // Cập nhật số lượng sản phẩm trước
      await updateProductQuantities(cartItems);

      // Tạo đơn hàng mới trong Firebase
      final ordersRef = dbRef.child('orders').push();
      await ordersRef.set({
        'userId': user!.uid,
        'customerName': customerName,
        'address': address,
        'phone': phone,
        'items': orderItems, // Lưu danh sách sản phẩm đầy đủ
        'total': total,
        'paymentMethod': method, // Lưu phương thức thanh toán
        'status': 'Pending', // Trạng thái đơn hàng
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Xóa giỏ hàng sau khi đặt hàng thành công
      await clearCart();
      // Hiển thị thông báo trong ứng dụng
      await _showOrderNotification();
      // Cập nhật trạng thái đốm đỏ
      final badgeProvider = NotificationBadgeProvider.of(context);
      if (badgeProvider != null) {
        badgeProvider.updateBadge(true);
      }
      // Hiển thị thông báo đặt hàng thành công
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Đặt hàng thành công"),
          content: const Text("Đơn hàng của bạn đã được đặt thành công!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Đóng"),
            ),
          ],
        ),
      );
    } catch (e) {
      print("Lỗi khi lưu đơn hàng: $e");
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Lỗi khi đặt hàng"),
          content: Text("Đã xảy ra lỗi: $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Đóng"),
            ),
          ],
        ),
      );
    }
  }



  /// chon phuong thuc thanhtoan
  void initiatePaymentMethodSelection(BuildContext context1) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context1) {
        return Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Chọn phương thức thanh toán",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance, color: Colors.blue),
              title: const Text("Thanh toán qua Ngân hàng"),
              onTap: () {
                Navigator.pop(context1);
                handlePaymentMethod(context1, "Ngân hàng");
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: Colors.green),
              title: const Text("Thanh toán qua Momo"),
              onTap: () {
                Navigator.pop(context1);
                initiatePaymentMoMo(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.blueAccent),
              title: const Text("Thanh toán qua Zalo Pay"),
              onTap: () {
                Navigator.pop(context1);
                handlePaymentMethod(context1, "Zalo Pay");
              },
            ),
            /// Paypal
            ListTile(
              leading: const Icon(Icons.paypal_sharp, color: Colors.blueAccent),
              title: const Text("Thanh toán PayPal"),
              onTap: () async {
                // Đóng ModalBottomSheet trước khi thực hiện thanh toán
                Navigator.pop(context1); // Đóng ModalBottomSheet ngay lập tức
                // Sau khi modal đóng xong, gọi initiatePayment
                initiatePayment(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping, color: Colors.orange),
              title: const Text("Thanh toán khi nhận hàng (COD)"),
              onTap: () {
                Navigator.pop(context1);
                handlePaymentMethod(context1, "COD");
              },
            ),

          ],
        );
      },
    );
  }
  ///xu ly khi chon pttt
  void handlePaymentMethod(BuildContext context, String method) {
    switch (method) {
      case "Ngân hàng":
      // Gọi hàm xử lý thanh toán qua Ngân hàng
        print("Thanh toán qua Ngân hàng");
        saveOrderToFirebase(calculateTotal(), method);
        break;
      case "Momo":
      // Gọi hàm xử lý thanh toán qua Momo
        print("Thanh toán qua Momo");
        saveOrderToFirebase(calculateTotal(), method);
        break;
      case "Zalo Pay":
      // Gọi hàm xử lý thanh toán qua Zalo Pay
        print("Thanh toán qua Zalo Pay");
        saveOrderToFirebase(calculateTotal(), method);
        break;
      case "COD":
      // Xử lý thanh toán khi nhận hàng (COD)
        print("Thanh toán khi nhận hàng (COD)");
        saveOrderToFirebase(calculateTotal(), method);
        break;
      default:
        print("Phương thức thanh toán không xác định");
    }
  }

  ///hàm kết nối với server.js để gọi thanh toán paypal
  void initiatePayment(BuildContext context) async {
    try {
      // Tính tổng tiền từ giỏ hàng
      double total = calculateTotal();


      // Chuyển đổi tiền Việt sang USD nếu cần
      // Giả sử tỷ giá là 1 USD = 24,000 VND (tùy chỉnh tỷ giá này)
      double exchangeRate = 24000;
      double amountInUSD = total / exchangeRate;
      final response = await http.post(
        Uri.parse('http://172.20.10.4:3000/create-payment-Paypal'),
        body: json.encode({'amount': amountInUSD.toStringAsFixed(2)}), // Truyền số tiền đã chuyển đổi
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final paymentUrl = data['approval_url'];

        if (paymentUrl != null) {
          // Chuyển hướng người dùng tới PayPal để thanh toán
          final paymentSuccess = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaypalPaymentScreen(paymentUrl: paymentUrl),
            ),
          );
          // Only save the order if payment was successful
          if (paymentSuccess == true) {
            double total = calculateTotal(); // Calculate the total from cartItems
            saveOrderToFirebase(total,"PayPal");  // Save the order to Firebase
          } else {
            print("Payment was canceled.");
          }
        } else {
          print("Không có URL thanh toán trong response.");
        }
      } else {
        print('Lỗi khi tạo thanh toán: ${response.body}');
      }
    } catch (e) {
      print("Lỗi kết nối API: $e");
    }
  }
  ///hàm kết nối với server.js để gọi thanh toán MoMo
  void initiatePaymentMoMo(BuildContext context) async {
    try {
      // Tính tổng tiền từ giỏ hàng
      double total = calculateTotal();
      final response = await http.post(
        Uri.parse('http://192.168.1.61:3000/create-payment-momo'), // Update with server URL
        body: json.encode({'amount': total}), // Số tiền cần thanh toán
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final paymentUrl = data['payUrl'];

        if (paymentUrl != null) {
          final paymentSuccess = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MoMoPaymentScreen(paymentUrl: paymentUrl),
            ),
          );

          if (paymentSuccess == true) {

            saveOrderToFirebase(total,"MoMo");  // Save the order to Firebase
            print("Thanh toán thành công!");
          } else {
            print("Thanh toán bị hủy.");
          }
        } else {
          print("Không có URL thanh toán.");
        }
      } else {
        print("Lỗi tạo thanh toán: ${response.body}");
      }
    } catch (e) {
      print("Lỗi kết nối API: $e");
    }
  }


  /// số lượng
  void showQuantitySelector(BuildContext context, Map<String, dynamic> item, Function(int) onQuantityChanged) {
    // Khởi tạo controller cho ListWheelScrollView để kiểm soát vị trí cuộn ban đầu
    final FixedExtentScrollController scrollController = FixedExtentScrollController(
      initialItem: item['quantity'] - 1, // Đặt vị trí cuộn ban đầu dựa trên số lượng hiện tại
    );
    int selectedQuantity = item['quantity']; // Lưu trữ số lượng được chọn ban đầu

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Cho phép nội dung của BottomSheet cuộn
      builder: (context) {
        return StatefulBuilder( // Sử dụng StatefulBuilder để cập nhật UI khi thay đổi số lượng
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.35, // Chiều cao của BottomSheet là 35% chiều cao màn hình
              padding: const EdgeInsets.all(1.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context), // Đóng BottomSheet khi nhấn "Hủy"
                        child: const Text('Hủy'),
                      ),
                      const Text(
                        'Chọn số lượng',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Tiêu đề của BottomSheet
                      ),
                      TextButton(
                        onPressed: () {
                          onQuantityChanged(selectedQuantity); // Xác nhận số lượng đã chọn
                          Navigator.pop(context); // Đóng BottomSheet sau khi xác nhận
                        },
                        child: const Text('Chọn'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        // Tạo khung trang trí cho vùng giữa danh sách
                        Positioned.fill(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 30, // Chiều cao của đường viền trang trí
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  border: Border(
                                    top: BorderSide(color: Colors.grey.shade300),
                                    bottom: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Sử dụng FutureBuilder để lấy dữ liệu số lượng sản phẩm từ Firebase
                        FutureBuilder<DataSnapshot>(
                          future: dbRef.child('products/${item['productId']}/quantity').get(), // Lấy số lượng từ Firebase
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final int maxQuantity = snapshot.data!.value as int; // Số lượng tối đa từ cơ sở dữ liệu

                              return ListWheelScrollView.useDelegate(
                                controller: scrollController, // Điều khiển vị trí cuộn
                                itemExtent: 23, // Chiều cao của mỗi mục trong danh sách
                                perspective: 0.005, // Hiệu ứng phối cảnh 3D
                                diameterRatio: 1.5, // Tỷ lệ đường kính cho hiệu ứng 3D
                                physics: const FixedExtentScrollPhysics(), // Cố định vị trí khi cuộn
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    selectedQuantity = index + 1; // Cập nhật số lượng được chọn
                                  });
                                },
                                childDelegate: ListWheelChildBuilderDelegate(
                                  childCount: maxQuantity, // Số lượng mục trong danh sách dựa trên maxQuantity
                                  builder: (context, index) {
                                    final quantity = index + 1;
                                    final isSelected = selectedQuantity == quantity; // Kiểm tra xem mục có được chọn không

                                    return GestureDetector(
                                      onTap: () {
                                        scrollController.jumpToItem(index); // Cuộn tới mục được nhấn
                                      },
                                      child: Center(
                                        child: Text(
                                          '$quantity',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, // Bôi đậm mục được chọn
                                            color: isSelected ? Colors.blue : Colors.black, // Đổi màu mục được chọn
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }
                            return const Center(child: Text("Sản phẩm không tồn tại")); // Hiển thị thông báo nếu sản phẩm không tồn tại
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget build(BuildContext context1) {


    return Scaffold(
      appBar: AppBar(
        title: const Text("Giỏ hàng của bạn"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hình minh họa
            Image.asset(
              'assets/images/empty-cart-removebg-preview.png', // Đường dẫn tới hình minh họa
              height: 200,
              width: 200,
            ),
            const SizedBox(height: 20),

            // Tiêu đề
            const Text(
              "Giỏ hàng của bạn đang trống!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Mô tả
            const Text(
              "Hãy thêm những sản phẩm yêu thích vào giỏ hàng\nvà bắt đầu mua sắm ngay hôm nay.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

          ],
        ),
      )
          : Column(
        children: [
          // Phần thông tin khách hàng
          buildAddressAndPhoneSection(),
          const Divider(),

          // Danh sách sản phẩm
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Dismissible(
                  key: Key(item['id']),
                  direction: DismissDirection.endToStart, // Vuốt từ phải sang trái
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    color: Colors.red,
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 30.0,
                    ),
                  ),
                  onDismissed: (direction) {
                    // Xóa sản phẩm khỏi danh sách
                    removeItem(item['id']);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("${item['title']} đã được xóa khỏi giỏ hàng"),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            // Hình ảnh sản phẩm
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                item['image'],
                                width: 80,
                                height: 80,
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
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  // Show the original price with strike-through if there is a discount
                                  if (item['originalPrice'] != item['price'])
                                    Text(
                                      "${currencyFormat.format(item['originalPrice'] as double)} VNĐ",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        decoration: TextDecoration.lineThrough, // Strike-through for original price
                                      ),
                                    ),
                                  SizedBox(width: 8),
                                  // Always show the price, but with a special style if it's a discounted price
                                  Text(
                                    "${currencyFormat.format(item['price'] as double)} VNĐ",
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),


                            // Điều chỉnh số lượng
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    if (item['quantity'] > 1) {
                                      updateQuantity(item['id'], item['quantity'] - 1);
                                    } else {
                                      showDeleteConfirmationDialog(item['id']);
                                    }
                                  },
                                ),
                                // Số lượng, hiển thị trong một hộp
                                GestureDetector(
                                  onTap: () => showQuantitySelector(
                                    context,
                                    item,
                                        (value) => updateQuantity(item['id'], value),
                                  ),
                                  child: Text(
                                    "${item['quantity']}",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    updateQuantity(item['id'], item['quantity'] + 1);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Tổng tiền
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Tổng cộng:",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "${currencyFormat.format(calculateTotal())} VNĐ",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (customerName == "Loading..." || customerName == "" ||
                  address == "Loading..." || address == "" ||
                  phone == "Loading..." || phone == ""){
                showErrorDialog(
                    "Vui lòng cập nhật đầy đủ thông tin trước khi thanh toán!");
              } else {
                initiatePaymentMethodSelection(context1);
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text(
              "Thanh toán",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }


  Widget buildAddressAndPhoneSection() {
    return Padding(
      padding: const EdgeInsets.all(0.5),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 18, color: Colors.black),
                    children: <TextSpan>[
                      TextSpan(
                        text: "$customerName ",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      TextSpan(
                        text: "(+84) $phone",
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text("Địa chỉ: $address", style: TextStyle(fontSize: 12)),
              ],
            ),
            trailing: const Icon(Icons.edit),
            onTap: _onSaveAddress,
          ),
        ),
      ),
    );
  }
}
