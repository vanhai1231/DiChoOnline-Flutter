import 'dart:async';
import 'dart:convert';
import 'package:diacritic/diacritic.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../category/category_screen.dart';
import '../details/detail_screen.dart';
import 'package:firebase/screens/home/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late Timer _timer;
  final _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('products');
  final _promotionsRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('promotions');
  final _reviewsRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('reviews');

  Map<dynamic, dynamic> _promotions = {};
  Map<dynamic, dynamic> _reviews = {};
  List<Map<dynamic, dynamic>> _products = [];
  int _currentImageIndex = 0;

  //danh mục đề xuất
  List<Map<dynamic, dynamic>> _productsProposal = [];
  List<Map<dynamic, dynamic>> _productsRecommend = [];
  List<String> _categories = [];
  bool _isLoading = true;
  String _selectedCategory = '';
  String _userId = ''; // ID của người dùng

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _backgroundImages.length;
      });
    });
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _loadPromotions();
    _loadData();
    _loadReviews();
    _animationController.forward();
    _getUserIdAndFetchProducts(); // Lấy userId và tải sản phẩm từ API
  }

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
// Danh sách ảnh nền
  final List<String> _backgroundImages = [
    'https://images.unsplash.com/photo-1542838132-92c53300491e',
    'https://www.bigc.vn/files/banners/2023/jan/new-node-16-01-2023-10-09-06/i-ch-online-bigc.jpg',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTikySIEMgpkuKcU-eNSHlaJ0QJ-wkmXoQuLA&s',
  ];
  void _loadReviews() async {
    try {
      final snapshot = await _reviewsRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        print("Reviews data: $data"); // In dữ liệu để kiểm tra
        // Kiểm tra mounted trước khi gọi setState

        setState(() {
          _reviews = Map.fromEntries(data.entries);
        });
      }
    } catch (error) {
      print("Error loading reviews: $error");
    }
  }

  ///load đề xuất
  void _getUserIdAndFetchProducts() async {
    User? user = FirebaseAuth.instance
        .currentUser; // Lấy thông tin người dùng từ Firebase Authentication
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
      _fetchProducts(); // Gọi API để lấy danh sách sản phẩm
    }
  }

  ///load sp API
  void _fetchProducts() async {
    try {
      final response = await http
          .get(Uri.parse('http://172.20.10.4:8000/recommendations/$_userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // Lấy danh sách sản phẩm từ phản hồi API
          _productsProposal = List<Map<String, dynamic>>.from(data['products']);
          _isLoading = false; // Ngừng trạng thái tải
        });

        // Fetch products from Firebase and compare them
        _fetchProductsFromFirebase();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Error fetching products: $e')),
      // );
    }
  }

  ///lấy sp firebase rồi so sánh api =
  void _fetchProductsFromFirebase() async {
    try {
      // Fetch all products from Firebase Realtime Database
      final snapshot = await _database.get();
      if (snapshot.exists) {
        final firebaseProducts =
            Map<dynamic, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);

        // Filter products from Firebase based on the API product names
        List<Map<dynamic, dynamic>> matchedProducts = [];

        // Iterate over the API products
        for (var apiProduct in _productsProposal) {
          // Normalize the product name from API (no diacritics)
          final apiProductName = apiProduct['product_name'].toString();

          // Search for matching product names in Firebase
          final matchingFirebaseProduct = firebaseProducts.values.firstWhere(
            (firebaseProduct) {
              final firebaseProductName =
                  firebaseProduct['product_name'].toString();
              // Remove diacritics from the Firebase product name for comparison
              return removeDiacritics(firebaseProductName) == apiProductName;
            },
            orElse: () => null,
          );

          // If a matching product is found, add it to the matched list
          if (matchingFirebaseProduct != null) {
            matchedProducts.add(matchingFirebaseProduct);
          }
        }

        setState(() {
          // Update the UI with the matched products from Firebase
          _productsRecommend = matchedProducts;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Error fetching Firebase products: $e')),
      // );
    }
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _loadProducts();
    _loadCategories();
  }

  Future<void> _loadProducts() async {
    _database.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        setState(() {
          _products = data.entries
              .map((e) => e.value as Map<dynamic, dynamic>)
              .toList();
          _isLoading = false;
        });
      }
    });
  }

  void _loadCategories() {
    Set<String> categoriesSet = {};
    for (var product in _products) {
      categoriesSet.add(product['category'] ?? 'Unknown');
    }
    setState(() {
      _categories = categoriesSet.toList();
    });
  }

  final List<Map<String, String>> _categoriesData = [
    {"title": "Rau, củ, quả", "image": "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRV0bjBBQeHSZIr1NZKrDhI-jG3Vxf8dS85Qw&s"},
    {"title": "Thịt", "image": "https://cdn.tgdd.vn/2021/05/CookProduct/0-1200x676-2.jpg"},
    {"title": "Trứng", "image": "https://cdn-www.vinid.net/1e221266-shutterstock_113786020-1.jpg"},
    {"title": "Gạo và các loại hạt", "image": "https://cdn.tgdd.vn/Files/2017/10/24/1035469/phan-biet-gao-nep-va-gao-te-chung-duoc-dung-de-nau-mon-gi-202210182107021046.jpg"},
    {"title": "Mì, bún, phở khô", "image": "https://cdn.tgdd.vn/Files/2020/04/24/1251577/top-8-thuong-hieu-mi-an-lien-duoc-ua-chuong-nhat--12-760x367.jpg"},
    {"title": "Gia vị và đồ khô", "image": "https://muoibaclieu.com.vn/wp-content/uploads/2022/09/DKS09473-600x337.jpg"},
    {"title": "Đồ hộp", "image": "https://vissanmart.com/pub/media/catalog/product/cache/ee97423e9fa68a0b8b7aae16fe28a6ff/b/_/b_h_m_150g.jpg"},
    {"title": "Đồ ăn nhanh", "image": "https://cdn.tgdd.vn/Files/2020/10/10/1297715/chieu-dai-ca-nha-voi-mon-ga-quay-me-da-gion-thom-ngon-nuc-mui-202010101538080615.jpg"},
    {"title": "Thực phẩm đông lạnh", "image": "https://bizweb.dktcdn.net/100/021/951/products/nam-ba-chi-bo-uc-nhung-lau-6.jpg?v=1663148288753"},
    {"title": "Đồ ăn vặt", "image": "https://batos.vn/images/products/2023/07/25/20230508-bewbauzvdm-575.jpeg"},
    {"title": "Nước lọc và nước đóng chai", "image": "https://truongphatdat.com/wp-content/uploads/2017/07/350ml-2.jpg"},
    {"title": "Nước giải khát", "image": "https://images-na.ssl-images-amazon.com/images/I/912O+XX3+YL.jpg"},
    {"title": "Sữa và chế phẩm từ sữa", "image": "https://ingreda.vn/wp-content/uploads/2022/06/huong-sua-tuoi.jpg"},
    {"title": "Combo bữa ăn", "image": "https://i-giadinh.vnecdn.net/2024/03/07/7Honthinthnhphm1-1709800144-8583-1709800424.jpg"},
    {"title": "Combo tiết kiệm", "image": "https://aloha.com.vn/wp-content/uploads/2024/03/dung-bo-lo-combo-sieu-tiet-kiem-moi-chi-co-99-000-02.jpg"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            _buildSearchBar(),
            //_buildCategories(),
            _buildPromotionBanner(),
            _buildProducts(),
          ],
        ),
      ),
    );
  }

  ///hiển thị các sản phẩm dề xuất
  Widget _buildPromotionBanner() {
    if (_isLoading) {
      return SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_productsRecommend.isEmpty) {
      return SliverToBoxAdapter(
        child:
            Center(child: Text('Hiện không có sản phẩm nào phù hợp với bạn.')),
      );
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              "Sản phẩm đề xuất cho bạn",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _productsRecommend.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: _buildProductItemHorizontal(_productsRecommend[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Chợ Online',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        background: Stack(
          fit: StackFit.expand, // Đảm bảo Stack chiếm toàn bộ không gian
          children: [
            AnimatedSwitcher(
              duration: const Duration(seconds: 1),
              child: Image.network(
                _backgroundImages[_currentImageIndex],
                key: ValueKey<String>(_backgroundImages[_currentImageIndex]),
                fit: BoxFit.cover, // Đảm bảo ảnh được bao phủ toàn màn hình
                width: double.infinity, // Chiều ngang full màn hình
                height: double.infinity, // Chiều dọc full không gian của SliverAppBar
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.shopping_cart, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: GestureDetector(
        onTap: () {
          if (_isLoading || _products.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Dữ liệu sản phẩm đang tải, vui lòng thử lại sau!')),
            );
            return;
          }

          // Chuyển đổi danh sách từ dynamic -> String
          List<Map<String, dynamic>> convertedProducts = _products
              .map((product) =>
                  product.map((key, value) => MapEntry(key.toString(), value)))
              .toList();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchScreen(products: convertedProducts),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Tìm kiếm sản phẩm...',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerItem(String imageUrl, String title) {
    return Container(
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  int _hoveredIndex = -1;

  Widget _buildCategoryItem(String category, int index) {
    return GestureDetector(
      onTap: () {
        // Xử lý khi chọn loại
      },
      child: MouseRegion(
        onEnter: (_) => _onHover(index),
        onExit: (_) => _onHover(-1),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: 120,
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hoveredIndex == index ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: _hoveredIndex == index
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.15),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: _hoveredIndex == index
                  ? Colors.blue.shade200
                  : Colors.grey.shade100,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 70,
                width: 70,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 12),
              Text(
                category,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _hoveredIndex == index
                      ? Colors.blue.shade700
                      : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onHover(int index) {
    setState(() {
      _hoveredIndex = index;
    });
  }

  Widget _buildProducts() {
    if (_isLoading) {
      return SliverToBoxAdapter(child: _buildShimmerLoading());
    }

    // Lọc sản phẩm "Đồ ăn nhanh"
    final fastFoodProducts = _products.where((product) {
      return product['category'] == 'Đồ ăn nhanh';
    }).toList();

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Các mục sản phẩm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              "Các mục sản phẩm",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _categoriesData.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: _buildCategoryTile(_categoriesData[index]),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Sản phẩm "Đồ ăn nhanh" với thiết kế riêng
          if (fastFoodProducts.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Đồ ăn nhanh",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryScreen(categoryName: "Đồ ăn nhanh"),
                        ),
                      );
                    },
                    child: Text(
                      "Xem thêm →",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200, // Chiều cao cố định cho hàng ngang
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: fastFoodProducts.length,
                itemBuilder: (context, index) {
                  return _buildFastFoodProductCard(fastFoodProducts[index]);
                },
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Sản phẩm nổi bật
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              "Sản phẩm nổi bật",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: _buildProductItemHorizontal(_products[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildFastFoodProductCard(Map<dynamic, dynamic> product) {
    final String imageUrl = product['image'];
    final bool isValidUrl = Uri.tryParse(imageUrl)?.hasAbsolutePath ?? false;
// Original price
    int originalPrice = product['price'];
    int price = originalPrice;
    String discountPercentText = '';

    // Check if there is any promotion and calculate the discounted price
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
                (originalPrice *
                    discountPercent ~/
                    100); // Calculate discounted price
            discountPercentText = '$discountPercent%';
            break; // Exit the loop once a matching promotion is found
          }
        }
      }
    }
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailScreen(product: product),
        ),
      ),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: 150,
        height: 150,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade100, Colors.orange.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hình ảnh sản phẩm
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: isValidUrl
                  ? CachedNetworkImage(
                imageUrl: imageUrl,
                height: 100, // Chiều cao của ảnh
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.grey[300]),
                ),
              )
                  : Container(
                height: 100,
                width: double.infinity,
                color: Colors.grey,
                child: const Icon(Icons.broken_image, size: 50),
              ),
            ),

            // Thông tin sản phẩm
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product['product_name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: price == originalPrice
                          ? MainAxisAlignment.center // Căn giữa khi chỉ hiển thị giá gốc
                          : MainAxisAlignment.start, // Hiển thị bình thường khi có giá giảm
                      children: [
                        // Giá gốc với gạch ngang (chỉ hiển thị khi có giá giảm)
                        if (price != originalPrice) ...[
                          Text(
                            '${NumberFormat('#,###').format(originalPrice)} ₫',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey, // Màu giá gốc
                              decoration: TextDecoration.lineThrough, // Gạch ngang giá gốc
                            ),
                          ),
                          const SizedBox(width: 8), // Khoảng cách giữa giá gốc và giá giảm
                        ],
                        // Giá giảm hoặc giá gốc (nếu không có giảm giá)
                        Text(
                          '${NumberFormat('#,###').format(price)} ₫',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: price == originalPrice ? Colors.red : Colors.redAccent,
                            // Màu đen nếu không giảm giá, màu đỏ nếu có giảm giá
                          ),
                        ),
                      ],
                    )

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildProductItemHorizontal(Map<dynamic, dynamic> product) {
    final String imageUrl = product['image'];
    final bool isValidUrl = Uri.tryParse(imageUrl)?.hasAbsolutePath ?? false;

    // Original price
    int originalPrice = product['price'];
    int price = originalPrice;
    String discountPercentText = '';

    // Check if there is any promotion and calculate the discounted price
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
                (originalPrice *
                    discountPercent ~/
                    100); // Calculate discounted price
            discountPercentText = '$discountPercent%';
            break; // Exit the loop once a matching promotion is found
          }
        }
      }
    }
    // Retrieve the average rating and total reviews for the product
    int totalReviews = 0;
    double averageRating = 0.0;

    _reviews.forEach((reviewId, review) {
      if (review['productId']?.toString() == product['id'].toString()) {
        // If the productId in the review matches the current product
        totalReviews += 1;
        averageRating += (review['productRating']?.toDouble() ?? 0.0);
      }
    });

    if (totalReviews > 0) {
      averageRating /= totalReviews; // Calculate average rating
    }
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailScreen(product: product),
        ),
      ),
      child: Container(
        width: 150, // Fixed width for each product
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                  child: isValidUrl
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.grey[300]),
                          ),
                        )
                      : Container(
                          height: 140,
                          width: double.infinity,
                          color: Colors.grey,
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                ),
                // Discount badge on the top-right corner
                if (discountPercentText.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        discountPercentText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['product_name'],
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Original price with strikethrough, shown only if there's a discount
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
                      Text(
                        '${NumberFormat('#,###').format(price)} ₫',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent, // Discounted price color
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 14),
                      Text(
                        '${averageRating.toStringAsFixed(1)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (totalReviews > 0)
                        Text(
                          '($totalReviews đánh giá)',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      const Spacer(),
                      // Icon(Icons.favorite_border, color: Colors.grey, size: 14),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(Map<String, String> category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryScreen(categoryName: category["title"]!),
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle, // Hình tròn
              border: Border.all(color: Colors.grey.shade300, width: 2),
              image: DecorationImage(
                image: NetworkImage(category["image"]!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category["title"]!,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    dispose();
    _animationController.dispose();
    super.dispose();
  }
}
