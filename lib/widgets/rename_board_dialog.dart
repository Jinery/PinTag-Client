import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_tag_client/services/api_service.dart';
import '../models/board.dart';

class RenameBoardDialog extends StatefulWidget {
  final int userId;
  final Board currentBoard;
  final VoidCallback onRename;

  const RenameBoardDialog({Key? key, required this.userId, required this.currentBoard, required this.onRename})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _RenameBoardDialog();
}

class _RenameBoardDialog extends State<RenameBoardDialog> {
  final ApiService _apiService = ApiService();
  List<String> _boardNames = List.empty();
  bool _isLoading = false;

  final TextEditingController _controller = TextEditingController();
  final TextEditingController _emojiController = TextEditingController();
  final emojiRegex = RegExp(
    r'(\p{Emoji_Presentation}|\p{Emoji}\uFE0F)',
    unicode: true,
  );

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _loadBoards() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final boards = await _apiService.getBoards(widget.userId);
      if(boards.isEmpty) return;
      _boardNames = boards.map((board) => board.name.toLowerCase()).toList();
    } on Exception catch (ex) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка загрузки досок: $ex"), backgroundColor: Colors.red[700]),
        );
      }
    } finally {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    String controllerText = _controller.text.trim();
    if(controllerText.isEmpty) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Введи новое название для доски", style: TextStyle(color: Colors.black87)), backgroundColor: Colors.yellowAccent[700]),
        );
      }
      return;
    }

    if(controllerText.toLowerCase() == widget.currentBoard.name.toLowerCase()) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Нельзя использовать старое название доски", style: TextStyle(color: Colors.black87)), backgroundColor: Colors.yellowAccent[700])
        );
      }
      return;
    } else if(_boardNames.contains(controllerText.toLowerCase())) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Доска с таким названием уже существует", style: TextStyle(color: Colors.black87)), backgroundColor: Colors.yellowAccent[700])
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.renameBoard(widget.userId, widget.currentBoard.id, controllerText,
          newBoardEmoji: _emojiController.text.isNotEmpty ? _emojiController.text : widget.currentBoard.emoji);
      widget.onRename();
      if (mounted) Navigator.of(context).pop();
    } on Exception catch (ex) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ex.toString(), style: TextStyle(color: Colors.black87)), backgroundColor: Colors.yellowAccent[700])
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? Center(
            child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blue[700],
                strokeCap: StrokeCap.round
            ),
          )
              : SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Новое название для доски ${widget.currentBoard.name}",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Column(
                  children: [
                    TextFormField(
                      controller: _controller,
                      decoration: InputDecoration(
                        labelText: "Новое название доски",
                        hintText: widget.currentBoard.name,
                        floatingLabelStyle: TextStyle(color: Colors.blue, fontSize: 18),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue, width: 1.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(width: 1.0),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 1,
                      cursorColor: Colors.blue,
                      cursorWidth: 0.7,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emojiController,
                      decoration: InputDecoration(
                        labelText: "Новое эмодзи (необязательно)",
                        hintText: widget.currentBoard.emoji,
                        floatingLabelStyle: TextStyle(color: Colors.blue, fontSize: 18),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue, width: 1.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(width: 1.0),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 1,
                      maxLength: 2,
                      cursorColor: Colors.blue,
                      cursorWidth: 0.7,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(emojiRegex),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red[600],
                          elevation: 2.0,
                        ),
                        child: const Text("Назад"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green[600],
                          elevation: 2.0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white70,
                              strokeCap: StrokeCap.round
                          ),
                        )
                            : const Text("Переименовать"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}