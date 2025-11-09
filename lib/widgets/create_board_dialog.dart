import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_tag_client/services/api_service.dart';

class CreateBoardDialog extends StatefulWidget {
  final int userId;
  final VoidCallback onBoardCreated;

  const CreateBoardDialog({
    Key? key,
    required this.userId,
    required this.onBoardCreated,
  }) : super(key: key);

  @override
  State<CreateBoardDialog> createState() => _CreateBoardDialog();
}

class _CreateBoardDialog extends State<CreateBoardDialog> {
  final _apiService = ApiService();

  final _titleController = TextEditingController();
  final _emojiController = TextEditingController();
  final emojiRegex = RegExp(
    r'(\p{Emoji_Presentation}|\p{Emoji}\uFE0F)',
    unicode: true,
  );

  bool _isLoading = false;
  List<String> _boardNames = List.empty();

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  @override
  void dispose() {
    _titleController.dispose();
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
          SnackBar(content: Text(ex.toString()), backgroundColor: Colors.red[700]),
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
    String boardTitle = _titleController.text.trim();
    if(boardTitle.isEmpty) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Введи название для доски", style: TextStyle(color: Colors.black87)), backgroundColor: Colors.yellowAccent[700]),
        );
      }
      return;
    }

    if(_boardNames.contains(_titleController.text.toLowerCase())) {
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
      await _apiService.createBoard(widget.userId, boardTitle, boardEmoji: _emojiController.text.trim().isNotEmpty ? _emojiController.text.trim() : null);
      widget.onBoardCreated();
      if (mounted) Navigator.of(context).pop();
    } on Exception catch (ex) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ex.toString(), style: TextStyle(color: Colors.white70)), backgroundColor: Colors.red[700])
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
        constraints: BoxConstraints(
          maxHeight: 600,
          maxWidth: 500,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Создание доски",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: "Название доски",
                        hintText: "Название",
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
                        labelText: "Эмодзи (необязательно)",
                        hintText: "Эмодзи",
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
                            : const Text("Создать"),
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