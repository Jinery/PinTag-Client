class Item {
  final int id;
  final String title;
  final String contentType;
  final String? contentData;
  final String createdAt;
  final String boardName;
  final String boardEmoji;

  Item({
    required this.id,
    required this.title,
    required this.contentType,
    this.contentData,
    required this.createdAt,
    required this.boardName,
    required this.boardEmoji,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      title: json['title'],
      contentType: json['content_type'],
      contentData: json['content_data'],
      createdAt: json['created_at'],
      boardName: json['board_name'],
      boardEmoji: json['board_emoji']
    );
  }
}