import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';

import '../../GoogleDriveApi/DriveService.dart';
import '../../VideoPlayer/VideoPlayerPreview.dart';

class ProductReviewScreen extends StatefulWidget {
  final String orderId;
  final String productId;
  final String title;
  final double price;
  final int quantity;
  final String image;

  const ProductReviewScreen({
    super.key,
    required this.orderId,
    required this.productId,
    required this.title,
    required this.price,
    required this.quantity,
    required this.image,
  });

  @override
  State<ProductReviewScreen> createState() => _ProductReviewScreenState();
}

class _ProductReviewScreenState extends State<ProductReviewScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://fir-23ae1-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('reviews');

  final _storage = FirebaseStorage.instance;
  final _reviewController = TextEditingController();
  final _driveService = DriveService();

  int _productRating = 5;
  int _sellerServiceRating = 5;
  int _deliveryRating = 5;
  final List<File> _imageFiles = [];
  File? _videoFile;
  final bool _showUsername = true;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty && _imageFiles.length < 3) {
      setState(() {
        for (var file in pickedFiles) {
          if (_imageFiles.length < 3) {
            _imageFiles.add(File(file.path));
          }
        }
      });
    }
  }

  Future<void> _pickVideo() async {
    if (_videoFile != null) return;

    final pickedFile =
        await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _videoFile = File(pickedFile.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  void _removeVideo() {
    setState(() {
      _videoFile = null;
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.isEmpty || user == null) return;

    try {
      Map<String, String> imagePaths = {};

      String? videoPath;

      // Upload images to Google Drive with specific keys
      for (int i = 0; i < _imageFiles.length; i++) {
        final imageFileName =
            '${DateTime.now().millisecondsSinceEpoch}_image$i.jpg';
        final imageFileId =
            await _driveService.uploadFile(imageFileName, _imageFiles[i].path);
        if (imageFileId != null) {
          final imageUrl = 'https://drive.google.com/uc?id=$imageFileId';
          imagePaths['imageReview${i > 0 ? i : ''}'] = imageUrl;
        } else {
          _showSnackbar('Có lỗi xảy ra khi tải hình ảnh lên Google Drive');
          return;
        }
      }

      // Upload video to Google Drive if exists
      if (_videoFile != null) {
        final videoFileName =
            '${DateTime.now().millisecondsSinceEpoch}_video.mp4';
        final videoFileId =
            await _driveService.uploadFile(videoFileName, _videoFile!.path);
        if (videoFileId != null) {
          videoPath = 'https://drive.google.com/uc?id=$videoFileId';
        } else {
          _showSnackbar('Có lỗi xảy ra khi tải video lên Google Drive');
          return;
        }
      }

      await _database.push().set({
        'orderId': widget.orderId,
        'productId': widget.productId,
        'userId': user!.uid,
        'username': _showUsername ? user!.displayName : null,
        'quantity': widget.quantity,
        'price': widget.price,
        'title': widget.title,
        'review': _reviewController.text,
        'imageReview': imagePaths['imageReview'],
        'imageReview1': imagePaths['imageReview1'],
        'imageReview2': imagePaths['imageReview2'],
        'videoReview': videoPath,
        'productRating': _productRating,
        'sellerServiceRating': _sellerServiceRating,
        'deliveryRating': _deliveryRating,
        'timestamp': ServerValue.timestamp,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đánh giá đã được gửi thành công')),
        );
      }
    } catch (e) {
      print('Error submitting review: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra khi gửi đánh giá')),
        );
      }
    }
  }

  Widget _buildRatingStars(int rating, Function(int) onRatingChanged) {
    return Row(
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
          onPressed: () => onRatingChanged(index + 1),
        );
      }),
    );
  }


  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       leading: IconButton(
  //         icon: const Icon(Icons.arrow_back),
  //         onPressed: () => Navigator.pop(context),
  //       ),
  //       title: const Text('Đánh giá sản phẩm'),
  //       actions: [
  //         TextButton(
  //           onPressed: _submitReview,
  //           child: const Text(
  //             'Gửi',
  //             style: TextStyle(fontSize: 16),
  //           ),
  //         ),
  //       ],
  //     ),
  //     body: SingleChildScrollView(
  //
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Container(
  //             height: 80,
  //             child: Row(
  //               children: [
  //                 SizedBox(
  //                   width: 80,
  //                   height: 80,
  //                   child: ClipRRect(
  //                     borderRadius: BorderRadius.circular(8),
  //                     child: Image.network(
  //                       widget.image,
  //                       fit: BoxFit.cover,
  //                       errorBuilder: (context, error, stackTrace) =>
  //                           Icon(Icons.image),
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(width: 16),
  //                 Expanded(
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     mainAxisAlignment: MainAxisAlignment.center,
  //                     children: [
  //                       Text(
  //                         widget.title,
  //                         style: const TextStyle(fontSize: 16),
  //                         maxLines: 2,
  //                         overflow: TextOverflow.ellipsis,
  //                       ),
  //                       Text(
  //                         'Phân loại: #${widget.productId}',
  //                         style: const TextStyle(color: Colors.grey),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           const Divider(),
  //           Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               const Text(
  //                 'Chất lượng sản phẩm',
  //                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //               ),
  //               _buildRatingStars(
  //                 _productRating,
  //                 (rating) => setState(() => _productRating = rating),
  //               ),
  //               const Text(
  //                 'Dịch vụ của người bán',
  //                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //               ),
  //               _buildRatingStars(
  //                 _sellerServiceRating,
  //                 (rating) => setState(() => _sellerServiceRating = rating),
  //               ),
  //               const Text(
  //                 'Tốc độ giao hàng',
  //                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //               ),
  //               _buildRatingStars(
  //                 _deliveryRating,
  //                 (rating) => setState(() => _deliveryRating = rating),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 16),
  //           TextField(
  //             controller: _reviewController,
  //             maxLines: 5,
  //             maxLength: 2000,
  //             decoration: const InputDecoration(
  //               hintText: 'Hãy chia sẻ nhận xét cho sản phẩm này bạn nhé!',
  //               border: OutlineInputBorder(),
  //             ),
  //           ),
  //           Row(
  //             children: [
  //               Expanded(
  //                 child: OutlinedButton.icon(
  //                   onPressed: _imageFiles.length < 3 ? _pickImages : null,
  //                   icon: const Icon(Icons.camera_alt),
  //                   label: Text('Thêm Hình ảnh (${_imageFiles.length}/3)'),
  //                 ),
  //               ),
  //               const SizedBox(width: 16),
  //               Expanded(
  //                 child: OutlinedButton.icon(
  //                   onPressed: _videoFile == null ? _pickVideo : null,
  //                   icon: const Icon(Icons.videocam),
  //                   label: const Text('Thêm Video'),
  //                 ),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 16),
  //           _buildMediaPreview(),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Tắt bàn phím khi nhấn ra ngoài TextField
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Đánh giá sản phẩm'),
          actions: [
            TextButton(
              onPressed: _submitReview,
              child: const Text(
                'Gửi',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 80,
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.image),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Phân loại: #${widget.productId}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chất lượng sản phẩm',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  _buildRatingStars(
                    _productRating,
                        (rating) => setState(() => _productRating = rating),
                  ),
                  const Text(
                    'Dịch vụ của người bán',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  _buildRatingStars(
                    _sellerServiceRating,
                        (rating) => setState(() => _sellerServiceRating = rating),
                  ),
                  const Text(
                    'Tốc độ giao hàng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  _buildRatingStars(
                    _deliveryRating,
                        (rating) => setState(() => _deliveryRating = rating),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reviewController,
                maxLines: 5,
                maxLength: 2000,
                decoration: const InputDecoration(
                  hintText: 'Hãy chia sẻ nhận xét cho sản phẩm này bạn nhé!',
                  border: OutlineInputBorder(),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _imageFiles.length < 3 ? _pickImages : null,
                      icon: const Icon(Icons.camera_alt),
                      label: Text('Thêm Hình ảnh (${_imageFiles.length}/3)'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _videoFile == null ? _pickVideo : null,
                      icon: const Icon(Icons.videocam),
                      label: const Text('Thêm Video'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMediaPreview(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildMediaPreview() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _imageFiles.length + (_videoFile != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _imageFiles.length) {
            // Hiển thị hình ảnh
            return Stack(
              children: [
                GestureDetector(
                  onTap: () => _viewMedia(index, isVideo: false),
                  child: Container(
                    width: 120,
                    height: 120,
                    margin: EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _imageFiles[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _removeImage(index),
                  ),
                ),
              ],
            );
          } else if (_videoFile != null) {
            // Hiển thị video thumbnail
            return FutureBuilder<VideoPlayerController>(
              future: _initializeVideoController(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    width: 120,
                    height: 120,
                    color: Colors.black12,
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return Container(
                    width: 120,
                    height: 120,
                    color: Colors.black12,
                    child: Center(child: Icon(Icons.error, color: Colors.red)),
                  );
                } else {
                  final controller = snapshot.data!;
                  return GestureDetector(
                    onTap: () => _viewMedia(index, isVideo: true),
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          margin: EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AspectRatio(
                              aspectRatio: controller.value.aspectRatio,
                              child: VideoPlayer(controller),
                            ),
                          ),
                        ),
                        Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: _removeVideo,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            );
          }

          return Container();
        },
      ),
    );
  }




// Function to open media (either image or video) in the full-screen viewer
  void _viewMedia(int index, {required bool isVideo}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaViewer(
          images: _imageFiles,
          video: _videoFile,
          initialIndex: index,
        ),
      ),
    );
  }

  Future<VideoPlayerController> _initializeVideoController() async {
    final controller = VideoPlayerController.file(_videoFile!);
    await controller.initialize(); // Khởi tạo bộ điều khiển video
    return controller;
  }

  @override
  void dispose() {
    _reviewController.dispose();

    super.dispose();
  }
}
// Future<void> _pickImage() async {
//   final pickedFile =
//       await ImagePicker().pickImage(source: ImageSource.gallery);
//   if (pickedFile != null) {
//     setState(() {
//       _imageFile = File(pickedFile.path);
//     });
//     final file = File(pickedFile.path);
//     final fileName = path.basename(file.path);
//
//     // Tải lên Google Drive
//     final fileId = await _driveService.uploadFile(fileName, file.path);
//
//     if (fileId != null) {
//       _showSnackbar('Hình ảnh đã được tải lên Google Drive với ID: $fileId');
//     } else {
//       _showSnackbar('Có lỗi xảy ra khi tải lên Google Drive');
//     }
//   } else {
//     _showSnackbar('Không có hình ảnh nào được chọn');
//   }
// }
//// if (_imageFile != null) {
//       //   final imageFileName =
//       //       '${DateTime.now().millisecondsSinceEpoch}_image.jpg';
//       //   imagePath = await _uploadFile(_imageFile!, imageFileName);
//       // }
//       //
//       // // Upload video if exists
//       // if (_videoFile != null) {
//       //   final videoFileName =
//       //       '${DateTime.now().millisecondsSinceEpoch}_video.mp4';
//       //   videoPath = await _uploadFile(_videoFile!, videoFileName);
//       // }
//
// Future<void> _pickVideo() async {
//   final pickedFile =
//       await ImagePicker().pickVideo(source: ImageSource.gallery);
//   if (pickedFile != null) {
//     setState(() {
//       _videoFile = File(pickedFile.path);
//     });
//     final file = File(pickedFile.path);
//     final fileName = path.basename(file.path);
//
//     // Tải lên Google Drive
//     final fileId = await _driveService.uploadFile(fileName, file.path);
//
//     if (fileId != null) {
//       _showSnackbar('Video đã được tải lên Google Drive với ID: $fileId');
//     } else {
//       _showSnackbar('Có lỗi xảy ra khi tải lên Google Drive');
//     }
//   } else {
//     _showSnackbar('Không có video nào được chọn');
//   }
// }

// Future<String?> _uploadFile(File file, String path) async {
//   try {
//     final ref = _storage.ref().child(path);
//     final uploadTask = ref.putFile(file);
//     final snapshot = await uploadTask;
//     return await snapshot.ref.getDownloadURL();
//   } catch (e) {
//     print('Error uploading file: $e');
//     return null;
//   }
// }
