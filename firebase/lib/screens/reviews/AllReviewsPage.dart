import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../../VideoPlayer/MediaViewerString.dart';
import '../orderDetails/order_details_screen.dart';
import 'package:http/http.dart' as http;

class AllReviewsPage extends StatefulWidget {
  final List<MapEntry<String, dynamic>> reviews;
  final Map<dynamic, dynamic> product; // Nhận dữ liệu sản phẩm
  const AllReviewsPage({Key? key, required this.reviews, required this.product})
      : super(key: key);

  @override
  _AllReviewsPageState createState() => _AllReviewsPageState();
}

class _AllReviewsPageState extends State<AllReviewsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final GlobalKey cartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }
  final user = FirebaseAuth.instance.currentUser;
  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        title: Text('Tất cả đánh giá'),
        actions: [
          IconButton(
            key: cartKey, // Thêm key vào đây
            icon: const Icon(Icons.shopping_cart, color: Colors.grey),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OrderDetailsScreen()),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.reviews.length,
        itemBuilder: (context, index) {
          final review = widget.reviews[index].value;
          return _buildReviewItem(context, review);
        },
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, Map<dynamic, dynamic> review) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(
                  user?.photoURL ?? 'https://via.placeholder.com/150',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['username'] ?? '',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            Icons.star,
                            color: i < (review['productRating'] ?? 0)
                                ? Colors.amber
                                : Colors.grey[300],
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy').format(
                            DateTime.fromMillisecondsSinceEpoch(
                              review['timestamp'] as int,
                            ),
                          ),
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review['review']?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(review['review']),
            ),
          if (review['imageReview'] != null || review['videoReview'] != null)
            Container(
              height: 120,
              margin: const EdgeInsets.only(top: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _buildMediaItems(context, review),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildMediaItems(
      BuildContext context, Map<dynamic, dynamic> review) {
    List<Widget> items = [];
    List<String> reviewImages = [];

    // Add video if exists
    if (review['videoReview'] != null) {
      final videoUrl = review['videoReview'];
      items.add(_buildVideoItem(context, videoUrl, reviewImages));
    }

    // Collect all images
    for (var key in ['imageReview', 'imageReview1', 'imageReview2']) {
      if (review[key] != null) {
        reviewImages.add(review[key]);
        items.add(_buildImageItem(
            context, review[key], reviewImages, review['videoReview']));
      }
    }

    return items;
  }

  Widget _buildImageItem(BuildContext context, String url,
      List<String> allImages, String? videoUrl) {
    return GestureDetector(
      onTap: () => _viewMedia(
          context, allImages.indexOf(url), allImages, videoUrl,
          isVideo: false),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: NetworkImage(url),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoItem(
      BuildContext context, String url, List<String> reviewImages) {
    return GestureDetector(
      onTap: () => _viewMedia(context, 0, reviewImages, url, isVideo: true),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        child: FutureBuilder<VideoPlayerController>(
          future: _initializeVideoController(url),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Icon(Icons.error, color: Colors.red));
            } else if (snapshot.hasData) {
              final controller = snapshot.data!;
              return Stack(
                children: [
                  AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                  Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ],
              );
            } else {
              return Container();
            }
          },
        ),
      ),
    );
  }

  void _viewMedia(
      BuildContext context, int index, List<String> images, String? video,
      {required bool isVideo}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaViewerString(
          images: images,
          video: video,
          initialIndex: index,
          isVideo: isVideo,
        ),
      ),
    );
  }

  Future<VideoPlayerController> _initializeVideoController(String url) async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await controller.initialize();
    return controller;
  }
}
