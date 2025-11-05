class Board {
  final int id;
  final String name;
  final String emoji;
  final int itemCount;

  Board({
    required this.id,
    required this.name,
    required this.emoji,
    required this.itemCount,
  });

  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      id: json['id'],
      name: json['name'],
      emoji: json['emoji'],
      itemCount: json['item_count'],
    );
  }
}