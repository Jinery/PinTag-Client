import 'package:flutter/material.dart';
import 'package:pin_tag_client/screens/items_screen.dart';
import 'package:pin_tag_client/services/api_service.dart';
import 'package:pin_tag_client/widgets/create_board_dialog.dart';
import 'package:pin_tag_client/widgets/rename_board_dialog.dart';

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

  Future<void> _createBoard() async {
    showDialog(
        context: context, 
        builder: (context) => CreateBoardDialog(
            userId: widget.userId,
            onBoardCreated: _loadBoards
        ),
    );
  }

  Future<void> _renameBoard(Board board) async {
    showDialog(
        context: context,
        builder: (context) => RenameBoardDialog(
            userId: widget.userId,
            currentBoard: board,
            onRename: _loadBoards
        ),
    );
  }

  Future<void> _removeBoard(int boardId) async {
    try {
      await _apiService.removeBoard(widget.userId, boardId);
      await _loadBoards();
    } on Exception catch (ex) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              ex.toString(), style: TextStyle(color: Colors.red[700]))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Мои доски'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_box),
            onPressed: () => _createBoard(),
          ),
        ],
      ),
      body: _isLoading ? Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue[700], strokeCap: StrokeCap.round),
      ) : _boards.isEmpty ? Center(
        child: Text("Доски отсутствуют"),
      ) : GridView.builder(
        padding: EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.2,
        ),
        itemCount: _boards.length,
        itemBuilder: (context, index) {
          final board = _boards[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
            elevation: 3.0,
            shadowColor: Colors.black45,
            color: Color(0xE8E8E8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ItemsScreen(userId: widget.userId, board: board)),
                  );

                  _loadBoards();
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                            onPressed: () => _renameBoard(board),
                            icon: Icon(Icons.update),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                            onPressed: () async => _removeBoard(board.id),
                            icon: const Icon(Icons.delete, color: Colors.red,)
                        ),
                      ],
                    ),
                    Text(board.emoji, style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text(
                      board.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${board.itemCount} элементов',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}