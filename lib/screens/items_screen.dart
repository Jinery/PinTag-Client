import 'package:flutter/material.dart';
import 'package:pin_tag_client/models/item.dart';
import 'package:pin_tag_client/services/api_service.dart';
import 'package:pin_tag_client/widgets/item_card.dart';
import 'package:pin_tag_client/widgets/move_item_dialog.dart';

import '../models/board.dart';

class ItemsScreen extends StatefulWidget {
  final int userId;
  final Board board;

  ItemsScreen({super.key, required this.userId, required this.board});

  @override
  _ItemsScreen createState() => _ItemsScreen();
}

class _ItemsScreen extends State<ItemsScreen> {
  final ApiService _apiService = ApiService();
  List<Item> _items = List.empty();
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _loadItemsForBoard();
  }

  Future<void> _loadItemsForBoard() async {
    try {
      final items = await _apiService.getBoardItems(widget.userId, widget.board.id);
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } on Exception catch (ex) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка загрузки: $ex")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Элементы для доски ${widget.board.name} ${widget.board.emoji} "),
      ),
      body: _isLoading ? Center(
        child: CircularProgressIndicator(),
      ) : _items.isEmpty ? Center(
        child: Text(
          "Элементы для доски ${widget.board.name} ${widget.board.emoji} отсутствуют",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ) : GridView.builder(
        padding: EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.2,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return ItemCard(
            item: item,
            onTap: () => print("Tapped on ${item.title}"),
            onRemoveTap: () => _removeItem(item),
            onMoveTap: () => _moveItem(item),
          );
        },
      ),
    );
  }

  Future<void> _removeItem(Item item) async {
    try {
      final response = await _apiService.removeItem(widget.userId, item.id);
      setState(() async {
        await _loadItemsForBoard();
      });
    } on Exception catch (ex) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка удаления: $ex")),
      );
    }
  }

  Future<void> _moveItem(Item item) async {
    showDialog(
        context: context,
        builder: (context) => MoveItemDialog(
            userId: widget.userId,
            itemId: item.id,
            currentBoardId: widget.board.id,
            itemTitle: item.title,
            onMove: (newBoardId) async {
              await _apiService.moveItem(widget.userId, item.id, newBoardId);
            },
            onSuccess: () {
              setState(() {
                _loadItemsForBoard();
              });
            },
        ),
    );
  }
}