import 'package:flutter/material.dart';
import 'package:pin_tag_client/services/api_service.dart';
import 'package:pin_tag_client/widgets/in_app_video_player.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/content_type.dart';
import '../models/item.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  final int userId;
  final VoidCallback onTap;
  final VoidCallback onRemoveTap;
  final VoidCallback onMoveTap;

  const ItemCard({
    Key? key,
    required this.item,
    required this.userId,
    required this.onTap,
    required this.onRemoveTap,
    required this.onMoveTap,
}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3.0,
      shadowColor: Colors.black45,
      color: Color(0xE8E8E8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          onTap: onTap,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                          onPressed: onRemoveTap,
                          icon: const Icon(Icons.delete, color: Colors.red,)
                      ),
                      const SizedBox(width: 2),
                      IconButton(
                          onPressed: onMoveTap,
                          icon: const Icon(Icons.drive_file_move, color: Colors.grey)
                      ),
                    ],
                  ),
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  _buildContentWidget(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentWidget() {
    return switch (item.contentType) {
      ContentType.link => _buildLinkContent(),
      ContentType.document => _buildFileContent(),
      ContentType.photo => _buildFileContent(),
      ContentType.video => _buildFileContent(),
      ContentType.unknown => _buildUnknownContent(),
    };
  }

  Widget _buildLinkContent() {
    if (item.contentData == null || item.contentData!.isEmpty) {
      return _buildPlaceholderText("Ссылка не указана");
    }

    return Text(
      item.contentData!,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPlaceholderText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[500],
      ),
    );
  }

  Widget _buildFileContent() {
    if (item.contentType != ContentType.link && item.filePath == null || item.filePath!.isEmpty) {
      return _buildPlaceholderText("Файл не найден");
    }

    print("${item.title}\n${item.contentType},\n${item.contentData}\n${item.filePath}");
    final fileUrl = _getFileUrl(item.filePath!);

    return switch (item.contentType) {
      ContentType.photo => _buildImageContent(fileUrl),
      ContentType.video => _buildVideoContent(fileUrl),
      ContentType.document => _buildDocumentContent(fileUrl),
      _ => _buildUnknownContent(),
    };
  }

  String _getFileUrl(String filePath) {
    if (filePath.startsWith("http") || filePath.startsWith("https")) return filePath;
    String normalizedPath = filePath.replaceAll('\\', '/');
    return "${ApiService.baseUrl}/files/${userId}/$normalizedPath";
  }

  Widget _buildImageContent(String imageUrl) {
    return FutureBuilder<Map<String, String>>(
      future: ApiService.getHeaders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _buildPlaceholderText("Ошибка получения заголовков");
        }

        final headers = snapshot.data!;

        return Image.network(
          imageUrl,
          headers: headers,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderText("Ошибка загрузки изображения");
          },
        );
      },
    );
  }

  Widget _buildVideoContent(String videoUrl) {
    return InAppVideoPlayer(videoUrl: videoUrl);
  }

  Widget _buildDocumentContent(String documentUrl) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.description, size: 32, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Документ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Нажми чтобы открыть",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => launchUrl(Uri.parse(documentUrl)),
            icon: Icon(Icons.open_in_new),
          ),
        ],
      ),
    );
  }

  Widget _buildUnknownContent() {
    return Text(
      "Неизвестный тип",
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}