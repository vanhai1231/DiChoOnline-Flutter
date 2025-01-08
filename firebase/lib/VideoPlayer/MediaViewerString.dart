
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';

class MediaViewerString extends StatefulWidget {
  final List<String> images; // Expect image URLs
  final String? video; // Expect video URL
  final int initialIndex;
  final bool isVideo;

  const MediaViewerString({
    Key? key,
    required this.images,
    this.video,
    required this.initialIndex,
    required this.isVideo,
  }) : super(key: key);

  @override
  State<MediaViewerString> createState() => _MediaViewerStringState();
}

// class _MediaViewerStringState extends State<MediaViewerString> {
//   late PageController _pageController;
//   int _currentIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _currentIndex = widget.initialIndex;
//     _pageController = PageController(initialPage: widget.initialIndex);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final totalItems = widget.images.length + (widget.video != null ? 1 : 0);
//
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         iconTheme: IconThemeData(color: Colors.white),
//         title: Text(
//           '${_currentIndex + 1}/$totalItems',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//       body: widget.isVideo
//           ? _buildVideoPlayer()
//           : PhotoViewGallery.builder(
//         pageController: _pageController,
//         itemCount: totalItems,
//         builder: (context, index) {
//           if (index < widget.images.length) {
//             return PhotoViewGalleryPageOptions(
//               imageProvider: NetworkImage(widget.images[index]),
//               minScale: PhotoViewComputedScale.contained,
//               maxScale: PhotoViewComputedScale.covered * 2,
//             );
//           } else {
//             return PhotoViewGalleryPageOptions.customChild(
//               child: _buildVideoPlayer(),
//               childSize: Size(MediaQuery.of(context).size.width,
//                   MediaQuery.of(context).size.height),
//             );
//           }
//         },
//         onPageChanged: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//       ),
//     );
//   }
//
//   Widget _buildVideoPlayer() {
//     return Center(
//       child: VideoPlayerWidget(videoUrl: widget.video!),
//     );
//   }
// }
class _MediaViewerStringState extends State<MediaViewerString> {
  late PageController _pageController;
  int _currentIndex = 0;
  late List<String> allMedia;

  @override
  void initState() {
    super.initState();
    allMedia = [];
    if (widget.video != null) allMedia.add(widget.video!);
    allMedia.addAll(widget.images);
    _currentIndex = widget.isVideo ? 0 : widget.initialIndex + (widget.video != null ? 1 : 0);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1}/${allMedia.length}', // Shows e.g. "4/4"
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: allMedia.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final isVideoItem = widget.video != null && index == 0;

          if (isVideoItem) {
            return Center(
              child: VideoPlayerWidget(videoUrl: widget.video!),
            );
          } else {
            return PhotoView(
              imageProvider: NetworkImage(allMedia[index]),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              backgroundDecoration: BoxDecoration(color: Colors.black),
            );
          }
        },
      ),
    );
  }
}
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}
class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _videoController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Error: $errorMessage"),
                ElevatedButton(
                  onPressed: _retryInitialization,
                  child: Text("Retry"),
                ),
              ],
            ),
          );
        },
      );

      if (mounted) setState(() {});
    } catch (error) {
      print("Video initialization failed: $error");
      if (mounted) setState(() => _isError = true);
    }
  }

  Future<void> _retryInitialization() async {
    setState(() => _isError = false);
    await _initializeVideo();
  }

  @override
  Widget build(BuildContext context) {
    if (_isError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Failed to load video"),
            ElevatedButton(
              onPressed: _retryInitialization,
              child: Text("Retry"),
            ),
          ],
        ),
      );
    }

    return _chewieController != null
        ? Chewie(controller: _chewieController!)
        : Center(child: CircularProgressIndicator());
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}
// class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
//   late VideoPlayerController _videoController;
//   late ChewieController _chewieController;
//
//   @override
//   void initState() {
//     super.initState();
//     _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
//     _videoController.addListener(() {
//       if (_videoController.value.hasError) {
//         // Handle video load error
//         print('Video player error: ${_videoController.value.errorDescription}');
//       }
//     });
//
//     _videoController.initialize().then((_) {
//       setState(() {});
//     }).catchError((error) {
//       // Handle error when initializing the video player
//       print("Video initialization failed: $error");
//     });
//
//     _chewieController = ChewieController(
//       videoPlayerController: _videoController,
//       autoPlay: true,  // Set to true to autoplay
//       looping: false,  // Adjust based on your requirements
//       errorBuilder: (context, errorMessage) {
//         // Custom error message handling
//         return Center(child: Text("Error: $errorMessage"));
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return _videoController.value.isInitialized
//         ? Chewie(controller: _chewieController)
//         : Center(child: CircularProgressIndicator());
//   }
//
//   @override
//   void dispose() {
//     _chewieController.dispose();
//     _videoController.dispose();
//     super.dispose();
//   }
// }
