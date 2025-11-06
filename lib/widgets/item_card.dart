import 'package:flutter/material.dart';

import '../models/content_type.dart';
import '../models/item.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;
  final VoidCallback onRemoveTap;
  final VoidCallback onMoveTap;

  const ItemCard({
    Key? key,
    required this.item,
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
    );
  }

  Widget _buildContentWidget() {
    return switch (item.contentType) {
      ContentType.link => _buildLinkContent(),
      ContentType.document => _buildUnsupportedContent(),
      ContentType.photo => _buildUnsupportedContent(),
      ContentType.video => _buildUnsupportedContent(),
      ContentType.unknown => _buildUnsupportedContent(),
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

  Widget _buildUnsupportedContent() {
    return Text(
      "Элемент типа ${item.contentType.displayName} пока что не поддерживается",
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
        fontStyle: FontStyle.italic,
      ),
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
}