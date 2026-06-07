import 'package:flutter/material.dart';
import 'package:ta_mobile_disposisi_surat/core/utils/full-images-viewer.dart';

/// Widget untuk menampilkan daftar lampiran surat.
/// Mendukung tampilan thumbnail dan tap untuk fullscreen.
class LampiranViewer extends StatelessWidget {
  final List<String> urls;
  final Color accentColor;

  const LampiranViewer({
    super.key,
    required this.urls,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file_rounded, size: 18, color: accentColor),
            const SizedBox(width: 6),
            Text(
              'Lampiran (${urls.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: urls.asMap().entries.map((entry) {
            final index = entry.key;
            final url = entry.value;
            final isImage = _isImage(url);

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImageViewer(
                    imageUrls: urls,
                    initialIndex: index,
                  ),
                ),
              ),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: accentColor.withValues(alpha: 0.25)),
                ),
                child: isImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fileIcon(index),
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                                  ? child
                                  : Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: accentColor,
                                      ),
                                    ),
                        ),
                      )
                    : _fileIcon(index),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        Text(
          'Ketuk untuk melihat lampiran',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  bool _isImage(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  Widget _fileIcon(int index) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file_outlined,
              size: 28, color: accentColor),
          const SizedBox(height: 4),
          Text(
            'File ${index + 1}',
            style: TextStyle(fontSize: 10, color: accentColor),
          ),
        ],
      ),
    );
  }
}
