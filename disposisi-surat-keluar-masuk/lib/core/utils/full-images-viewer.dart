import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ta_mobile_disposisi_surat/core/constants/session.dart';

class FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final Map<int, Uint8List> _imageCache = {};
  final Map<int, bool> _loadingMap = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _preloadImages();
  }

  void _preloadImages() {
    for (int i = 0; i < widget.imageUrls.length; i++) {
      _loadImage(i);
    }
  }

  Future<void> _loadImage(int index) async {
    if (_imageCache.containsKey(index) || _loadingMap[index] == true) return;
    
    setState(() => _loadingMap[index] = true);
    
    try {
      final url = widget.imageUrls[index];
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${Session.token ?? ''}',
        },
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _imageCache[index] = response.bodyBytes;
          _loadingMap[index] = false;
        });
      } else {
        setState(() => _loadingMap[index] = false);
      }
    } catch (e) {
      setState(() => _loadingMap[index] = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          _loadImage(index);
        },
        itemCount: widget.imageUrls.length,
        itemBuilder: (context, index) {
          final cached = _imageCache[index];
          final isLoading = _loadingMap[index] ?? false;
          
          if (cached != null) {
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.memory(
                  cached,
                  fit: BoxFit.contain,
                ),
              ),
            );
          }
          
          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, color: Colors.white, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Gagal memuat gambar',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _loadImage(index),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}