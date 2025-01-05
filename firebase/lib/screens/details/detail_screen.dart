import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:http/http.dart' as http;
import '../orderDetails/order_details_screen.dart';

class DetailScreen extends StatefulWidget {
  final Map<dynamic, dynamic> product; // Nhận dữ liệu sản phẩm
  const DetailScreen({super.key, required this.product});

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final GlobalKey productKey = GlobalKey();
  final GlobalKey cartKey = GlobalKey();
  int quantity = 1; // Số lượng mặc định là 1
  bool _isFavorite = false; // Biến để theo dõi trạng thái yêu thích
  int? maxQuantity; // Số lượng tối đa từ Firebase
  ///số lượng max
  Future<void> fetchMaxQuantity() async {
    try {
      final DatabaseReference proRef = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
      ).ref();

      // Truy cập đúng đường dẫn đến quantity của sản phẩm
      final snapshot =
          await proRef.child('products/${widget.product['id']}/quantity').get();

      if (snapshot.exists) {
        // Kiểm tra xem giá trị trả về có phải là một số nguyên không
        if (snapshot.value is int) {
          setState(() {
            maxQuantity =
                snapshot.value as int; // Lưu số lượng vào biến trạng thái
          });
          print("Max quantity fetched: $maxQuantity");
        } else {
          setState(() {
            maxQuantity = 1; // Nếu không phải kiểu int, đặt mặc định là 1
          });
          print("Quantity is not an integer, defaulting to 1");
        }
      } else {
        setState(() {
          maxQuantity = 1; // Mặc định nếu không có dữ liệu
        });
        debugPrint("No data for quantity, defaulting to 1");
      }
    } catch (e) {
      debugPrint("Error fetching quantity: $e");
      setState(() {
        maxQuantity = 1; // Mặc định nếu có lỗi
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchMaxQuantity(); // Gọi hàm lấy số lượng khi khởi tạo
    _checkIfFavorite(); // Kiểm tra trạng thái yêu thích khi trang được mở
    _setupAnimation();
  }
  void _setupAnimation() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  // Hàm tăng số lượng
  void increaseQuantity() {
    if (maxQuantity != null && quantity < maxQuantity!) {
      setState(() {
        quantity++;
      });
    } else {
      // Hiển thị thông báo lỗi nếu số lượng vượt quá maxQuantity
      _showErrorDialog("Số lượng vượt quá số lượng tối đa trong kho!");
    }
  }

  // Hàm giảm số lượng
  void decreaseQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  // Hàm hiển thị thông báo lỗi
  void _showErrorDialog(String message) {
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
  void addToCartWithAnimation(GlobalKey productKey, GlobalKey cartKey) async {
    animateShrinkAndFly(context, productKey, cartKey);
    await addToCart();
  }
  ///Thêm giỏ hàng ở đây
  Future<void> addToCart() async {
    // Lấy thông tin người dùng từ Firebase Authentication
    User? user = FirebaseAuth.instance.currentUser;

    // Kiểm tra xem người dùng có đăng nhập hay không
    if (user == null) {
      // Hiển thị một SnackBar thông báo người dùng cần đăng nhập để thêm vào giỏ hàng
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must log in to add to cart")),
      );
      return;
    }

    // Tham chiếu đến Firebase Realtime Database
    final DatabaseReference cartRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref('cart');

    // Tham chiếu đến bảng sản phẩm để lấy số lượng tối đa của sản phẩm
    final DatabaseReference productRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref('products/${widget.product['id']}/quantity');

    // Kiểm tra xem người dùng đã có hàng trong giỏ chưa bằng cách truy vấn theo userId
    final userCartRef = cartRef.orderByChild('userId').equalTo(user.uid);

    try {
      // Lấy số lượng tối đa của sản phẩm
      final productSnapshot = await productRef.get();
      if (!productSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product is not available")),
        );
        return;
      }

      final int maxQuantity = productSnapshot.value as int;

      // Lấy dữ liệu giỏ hàng của người dùng
      final snapshot = await userCartRef.get();
      if (snapshot.exists) {
        Map<dynamic, dynamic> cartItems =
            snapshot.value as Map<dynamic, dynamic>;
        bool productExists = false;
        String existingCartKey = '';

        // Duyệt qua từng sản phẩm trong giỏ để kiểm tra xem có sản phẩm trùng mã không
        cartItems.forEach((key, value) {
          if (value['productId'] == widget.product['productId'] ||
              value['productId'] == widget.product['id']) {
            productExists = true;
            existingCartKey = key; // Lưu key để cập nhật
          }
        });

        // Nếu sản phẩm đã có trong giỏ, kiểm tra số lượng và cập nhật
        if (productExists) {
          final existingProductRef = cartRef.child(existingCartKey);
          final existingQuantity = cartItems[existingCartKey]['quantity'];

          // Kiểm tra nếu số lượng mới không vượt quá số lượng tối đa
          if (existingQuantity + quantity <= maxQuantity) {
            await existingProductRef.update({
              "quantity": existingQuantity + quantity,
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    "${widget.product['product_name']} (x$quantity) updated in cart!"),
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Cannot add more than the available quantity!"),
              ),
            );
          }
        } else {
          // Nếu sản phẩm chưa có trong giỏ, thêm mới
          if (quantity <= maxQuantity) {
            await cartRef.push().set({
              "userId": user.uid,
              "productId": widget.product['productId'] ??
                  widget.product['id'] ??
                  'unknown',
              "quantity": quantity,
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    "${widget.product['product_name']} (x$quantity) added to cart!"),
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Cannot add more than the available quantity!"),
              ),
            );
          }
        }
      } else {
        // Nếu user chưa có giỏ hàng -> tạo mới một mục giỏ hàng
        if (quantity <= maxQuantity) {
          await cartRef.push().set({
            "userId": user.uid,
            "productId": widget.product['productId'] ??
                widget.product['id'] ??
                'unknown',
            "quantity": quantity,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "${widget.product['product_name']} (x$quantity) added to cart!"),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cannot add more than the available quantity!"),
            ),
          );
        }
      }
    } catch (e) {
      // Hiển thị lỗi nếu có
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add to cart: $e")),
      );
    }
  }

  //kiểm tra đã thêm danh sách yêu thích chưa
  Future<void> _checkIfFavorite() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return; // Nếu người dùng chưa đăng nhập, không cần kiểm tra
    }

    final DatabaseReference wishlistRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref('wishlist');

    try {
      final userWishlistRef =
          wishlistRef.orderByChild('userId').equalTo(user.uid);
      final snapshot = await userWishlistRef.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> wishlistItems =
            snapshot.value as Map<dynamic, dynamic>;

        // Kiểm tra nếu sản phẩm đã tồn tại trong wishlist
        bool isProductInWishlist = false;
        wishlistItems.forEach((key, value) {
          if (value['productId'] == widget.product['productId'] ||
              value['productId'] == widget.product['id']) {
            isProductInWishlist = true; // Sản phẩm đã có trong wishlist
          }
        });

        setState(() {
          _isFavorite = isProductInWishlist; // Cập nhật trạng thái trái tim
        });
      } else {
        setState(() {
          _isFavorite =
              false; // Nếu chưa có sản phẩm trong wishlist, trái tim màu xám
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to check wishlist: $e")),
      );
    }
  }

  /// Thêm vào hoặc xóa khỏi danh sách yêu thích (wishlist)
  Future<void> addToWishlist() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must log in to add to wishlist")),
      );
      return;
    }

    final DatabaseReference wishlistRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
      'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref('wishlist');
    try {
      final userWishlistRef = wishlistRef.orderByChild('userId').equalTo(user.uid);
      final snapshot = await userWishlistRef.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> wishlistItems = snapshot.value as Map<
            dynamic,
            dynamic>;
        String? existingWishlistKey;

        // Kiểm tra xem sản phẩm đã có trong wishlist chưa
        wishlistItems.forEach((key, value) {
          if (value['productId'] == widget.product['productId'] ||
              value['productId'] == widget.product['id']) {
            existingWishlistKey = key; // Lấy key của sản phẩm trong wishlist
          }
        });

        if (existingWishlistKey != null) {
          // Nếu có sản phẩm trong wishlist, xóa sản phẩm đó
          await wishlistRef.child(existingWishlistKey!).remove();
          setState(() {
            _isFavorite = false; // Cập nhật trạng thái trái tim
          });
          final String apiUrl = 'http://172.20.10.4:8000/favorites/${user
              .uid}/${widget.product['id']}';

          final response = await http.delete(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "${widget
                        .product['product_name']} removed from wishlist!")),
          );
        }
        else {
          // Nếu chưa có sản phẩm trong wishlist, thêm mới sản phẩm vào wishlist
          await wishlistRef.push().set({
            "userId": user.uid,
            "productId": widget.product['productId'] ??
                widget.product['id'] ??
                'unknown',
            "added_date": DateTime.now().toIso8601String(),
          });
          setState(() {
            _isFavorite = true; // Cập nhật trạng thái trái tim
          });
          // Gửi yêu cầu POST tới FastAPI server
          final String apiUrl ='http://172.20.10.4:8000/add_user/${user.uid}/${widget.product['id']}';

          final response = await http.post(
            Uri.parse(apiUrl),
          );

          if (response.statusCode == 200) {
            print("Successfully added to FastAPI server.");
          } else {
            print(
                "Error: Failed to update FastAPI server. Status code: ${response.statusCode}");
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "${widget.product['product_name']} added to wishlist!")),
          );
        }
      }
      else {
        // Nếu chưa có sản phẩm trong wishlist, thêm mới sản phẩm vào wishlist
        await wishlistRef.push().set({
          "userId": user.uid,
          "productId": widget.product['productId'] ??
              widget.product['id'] ??
              'unknown',
          "added_date": DateTime.now().toIso8601String(),
        });
        setState(() {
          _isFavorite = true; // Cập nhật trạng thái trái tim
        });
        // Gửi yêu cầu POST tới FastAPI server
        final String apiUrl ='http://172.20.10.4:8000/add_user/${user.uid}/${widget.product['id']}';

        final response = await http.post(
          Uri.parse(apiUrl),
        );

        if (response.statusCode == 200) {
          print("Successfully added to FastAPI server.");
        } else {
          print(
              "Error: Failed to update FastAPI server. Status code: ${response.statusCode}");
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "${widget.product['product_name']} added to wishlist!")),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update wishlist: $e")),
      );
    }
  }
  ///hinh anh
  void _openImageViewer(BuildContext context, List<String> imageUrls) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              PhotoViewGallery.builder(
                itemCount: imageUrls.length,
                builder: (context, index) => PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(imageUrls[index]),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2,
                ),
                scrollPhysics: const BouncingScrollPhysics(),
                backgroundDecoration: const BoxDecoration(color: Colors.black),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void animateShrinkAndFly(BuildContext context, GlobalKey widgetKey, GlobalKey cartKey) {
    if (widgetKey.currentContext == null || cartKey.currentContext == null) {
      debugPrint("Không thể tìm thấy vị trí widget. Vui lòng kiểm tra GlobalKey.");
      return;
    }

    final RenderBox renderBox = widgetKey.currentContext!.findRenderObject() as RenderBox;
    final Offset startOffset = renderBox.localToGlobal(Offset.zero);

    final RenderBox cartRenderBox = cartKey.currentContext!.findRenderObject() as RenderBox;
    final Offset endOffset = cartRenderBox.localToGlobal(Offset.zero);

    OverlayState overlayState = Overlay.of(context);
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => AnimatedPositioned(
        duration: Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        top: endOffset.dy,
        left: endOffset.dx,
        child: TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 700),
          tween: Tween<double>(begin: 1.0, end: 0.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(
                (startOffset.dx - endOffset.dx) * value,
                (startOffset.dy - endOffset.dy) * value,
              ),
              child: Transform.scale(
                scale: value,
                child: child,
              ),
            );
          },
          child: ClipOval(
            child: Container(
              width: 50,
              height: 50,
              color: Colors.blue,
              child: const Icon(Icons.shopping_cart, color: Colors.white),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    Future.delayed(Duration(milliseconds: 700), () {
      overlayEntry.remove();
    });
  }

  /// số lượng
  void showQuantityPicker(BuildContext context, int initialQuantity, int maxQuantity, Function(int) onQuantityChanged) {
    // Hàm hiển thị một modal bottom sheet để người dùng chọn số lượng
    // context: ngữ cảnh hiện tại
    // initialQuantity: số lượng mặc định được chọn ban đầu
    // maxQuantity: số lượng tối đa có thể chọn
    // onQuantityChanged: hàm callback để xử lý khi người dùng xác nhận số lượng đã chọn

    int selectedQuantity = initialQuantity;
    // Lưu số lượng được chọn hiện tại, khởi tạo bằng giá trị mặc định

    final scrollController = FixedExtentScrollController(initialItem: initialQuantity - 1);
    // Tạo controller cho ListWheelScrollView để điều khiển vị trí cuộn, mục đầu tiên được chọn là (initialQuantity - 1)

    showModalBottomSheet(
      context: context, // Ngữ cảnh hiển thị modal
      isScrollControlled: true, // Cho phép modal có kích thước điều chỉnh theo nội dung
      builder: (context) => StatefulBuilder(
        // Sử dụng StatefulBuilder để cho phép cập nhật trạng thái trong modal
        builder: (context, setState) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.35,
          // Đặt chiều cao của modal bằng 35% chiều cao màn hình
          child: Column(
            // Dùng cột để sắp xếp các thành phần theo chiều dọc
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                // Thêm khoảng cách xung quanh hàng điều khiển
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  // Sắp xếp các widget trong hàng, nằm hai bên của hàng
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      // Đóng modal khi nhấn nút "Hủy"
                      child: const Text('Hủy'), // Nút hủy
                    ),
                    const Text(
                      'Chọn số lượng',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      // Tiêu đề của modal
                    ),
                    TextButton(
                      onPressed: () {
                        onQuantityChanged(selectedQuantity);
                        // Gọi hàm callback khi xác nhận số lượng
                        Navigator.pop(context);
                        // Đóng modal sau khi chọn
                      },
                      child: const Text('Chọn'), // Nút xác nhận
                    ),
                  ],
                ),
              ),
              Expanded(
                // Phần còn lại của modal dành cho danh sách cuộn
                child: Stack(
                  // Dùng Stack để xếp chồng các phần tử
                  children: [
                    Positioned.fill(
                      // Phần tử chiếm toàn bộ không gian của stack
                      child: Center(
                        // Hiển thị khung màu làm nổi bật mục được chọn
                        child: Container(
                          height: 30, // Chiều cao khung nổi bật
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1), // Màu xanh nhạt với độ mờ
                            border: Border(
                              top: BorderSide(color: Colors.grey.shade300), // Đường viền trên
                              bottom: BorderSide(color: Colors.grey.shade300), // Đường viền dưới
                            ),
                          ),
                        ),
                      ),
                    ),
                    ListWheelScrollView(
                      controller: scrollController, // Gắn controller cho danh sách cuộn
                      itemExtent: 23, // Chiều cao mỗi mục trong danh sách
                      physics: const FixedExtentScrollPhysics(),
                      // Dùng vật lý cuộn cố định để cuộn từng mục một
                      perspective: 0.005, // Hiệu ứng phối cảnh nhỏ
                      diameterRatio: 1.5, // Tỉ lệ đường kính cuộn
                      onSelectedItemChanged: (index) {
                        setState(() {
                          selectedQuantity = index + 1;
                          // Cập nhật số lượng khi người dùng cuộn đến mục mới
                        });
                      },
                      children: List.generate(
                        maxQuantity,
                        // Tạo danh sách các mục từ 1 đến maxQuantity
                            (index) => GestureDetector(
                          onTap: () {
                            scrollController.jumpToItem(index);
                            // Khi nhấn vào mục, cuộn tới mục đó mà không thay đổi ngay số lượng
                          },
                          child: Center(
                            child: Text(
                              '${index + 1}', // Hiển thị số lượng
                              style: TextStyle(
                                fontSize: 17,
                                color: selectedQuantity == index + 1
                                    ? Colors.blue
                                    : Colors.black, // Đổi màu cho mục được chọn
                                fontWeight: selectedQuantity == index + 1
                                    ? FontWeight.bold
                                    : FontWeight.normal, // Đổi độ đậm cho mục được chọn
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    String formattedPrice = NumberFormat("#,###", "vi_VN").format(widget.product['price']);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProductInfo(formattedPrice),
                _buildDescription(),
                _buildDeliveryInfo(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'product-${widget.product['id']}',
              child: CarouselSlider(
                options: CarouselOptions(
                  height: double.infinity,
                  viewportFraction: 1.0,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 5),
                ),
                items: [
                  widget.product['image'],
                  if (widget.product['image1'] != null) widget.product['image1'],
                ].map((url) {
                  return GestureDetector(
                    onTap: () => _openImageViewer(context, [url]),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: SizedBox(height: 80),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red : Colors.white,
          ),
          onPressed: () {
            addToWishlist();
            _controller.forward().then((_) => _controller.reverse());
          },
        ),
        IconButton(
          key: cartKey, // Thêm key vào đây
          icon: const Icon(Icons.shopping_cart, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderDetailsScreen()),
          ),
        ),
      ],


    );
  }

  Widget _buildProductInfo(String formattedPrice) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.product['product_name'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.product['category'],
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const Text(
                " 4.5",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                " (128)",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "$formattedPrice₫",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "-20%",
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                "Mô tả sản phẩm",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.product['description'] ?? 'Không có mô tả',
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.local_shipping_outlined,
            "Miễn phí vận chuyển",
            "Áp dụng cho đơn hàng từ 200k",
          ),
          const Divider(height: 24),
          _buildInfoRow(
            Icons.access_time,
            "Thời gian giao hàng",
            "2-3 ngày làm việc",
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue, size: 24),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildQuantityButton(
                    icon: Icons.remove,
                    onPressed: decreaseQuantity,
                  ),
                  GestureDetector(
                    onTap: () => showQuantityPicker(
                      context,
                      quantity,
                      maxQuantity!,
                          (value) => setState(() => quantity = value),
                    ),
                    child: SizedBox(  // Sử dụng Container để chỉnh chiều rộng
                      width: 40,  // Đặt chiều rộng cho Container
                      child: Text(
                        '$quantity',
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,  // Căn giữa văn bản
                      ),
                    ),
                  ),

                  _buildQuantityButton(
                    icon: Icons.add,
                    onPressed: increaseQuantity,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  animateShrinkAndFly(context, productKey, cartKey);
                  Future.delayed(Duration(milliseconds: 700), () {
                    addToCart();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Đã thêm ${widget.product['product_name']} vào giỏ hàng",
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  });
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Thêm vào giỏ",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 48,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.blue),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
