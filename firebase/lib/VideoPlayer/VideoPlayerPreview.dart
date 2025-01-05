import 'dart:io';

import 'package:flutter/material.dart';

import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';

import 'package:chewie/chewie.dart';

class MediaViewer extends StatefulWidget {
  final List<File> images;
  final File? video;
  final int initialIndex;

  const MediaViewer({
    super.key,
    required this.images,
    this.video,
    required this.initialIndex,
  });

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  late PageController _pageController;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    if (widget.video != null) {
      _videoController = VideoPlayerController.file(widget.video!);
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        placeholder: Center(child: CircularProgressIndicator()),
      );

      setState(() {});
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = widget.images.length + (widget.video != null ? 1 : 0);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1}/$totalItems',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: PhotoViewGallery.builder(
        pageController: _pageController,
        itemCount: totalItems,
        builder: (context, index) {
          if (index < widget.images.length) {
            return PhotoViewGalleryPageOptions(
              imageProvider: FileImage(widget.images[index]),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            );
          } else {
            return PhotoViewGalleryPageOptions.customChild(
              child: _buildVideoPlayer(),
              childSize: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
            );
          }
        },
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_chewieController != null) {
      return Center(
        child: Chewie(controller: _chewieController!),
      );
    }
    return Center(child: CircularProgressIndicator());
  }
}
