import 'package:flutter/material.dart';
import 'package:pin_tag_client/services/api_service.dart';

import '../models/board.dart';

class BoardsScreen extends StatefulWidget {
  final int userId;

  BoardsScreen({super.key, required this.userId});

  @override
  _BoardsScreen createState() => _BoardsScreen();
}

class _BoardsScreen extends State<BoardsScreen> {
  final _apiService = ApiService();
  List<Board> _boards = List.empty();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  Future<void> _loadBoards() async {
    try {
      final boards = await _apiService.getBoards(widget.userId);
      setState(() {
        _boards = boards;
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
        title: Text('Мои доски'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
        ],
      ),
      body: _isLoading ? Center(
        child: CircularProgressIndicator(),
      ) : _boards.isEmpty ? Center(
        child: Text("Доски отсутствуют"),
      ) : GridView.builder(
        padding: EdgeInsets.all(8.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.2,
        ),
        itemCount: _boards.length,
        itemBuilder: (context, index) {
          final board = _boards[index];
          return Card(
            child: InkWell(
              onTap: () => print(board.name),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(board.emoji, style: TextStyle(fontSize: 32)),
                  SizedBox(height: 8),
                  Text(
                    board.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${board.itemCount} элементов',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}