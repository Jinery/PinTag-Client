import 'package:flutter/material.dart';
import 'package:pin_tag_client/services/api_service.dart';

import '../models/board.dart';

class MoveItemDialog extends StatefulWidget {
  final int userId;
  final int itemId;
  final int currentBoardId;
  final String itemTitle;
  final Future<void> Function(int newBoardId) onMove;
  final VoidCallback onSuccess;

  const MoveItemDialog({
    Key? key,
    required this.userId,
    required this.itemId,
    required this.currentBoardId,
    required this.itemTitle,
    required this.onMove,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<MoveItemDialog> createState() => _MoveItemDialogState();
}

class _MoveItemDialogState extends State<MoveItemDialog> {
  final _apiService = ApiService();

  List<Board> _boards = [];
  Board? _selectedBoard;
  bool _isLoading = false;
  bool _isMoving = false;

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  Future<void> _loadBoards() async {
    setState(() => _isLoading = true);

    try {
      final boards = await _apiService.getBoards(widget.userId);
      setState(() {
        _boards = boards.where((board) => board.id != widget.currentBoardId).toList();
        if (_boards.isNotEmpty) {
          _selectedBoard = _boards.first;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка загрузки досок: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedBoard == null) return;

    setState(() => _isMoving = true);

    try {
      await widget.onMove(_selectedBoard!.id);
      widget.onSuccess();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка перемещения: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isMoving = false);
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
        child:Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Переместить элемент",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "'${widget.itemTitle}'",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),

              if (_isLoading) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                ),
              ] else if (_boards.isEmpty) ...[
                const Icon(Icons.folder_off, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                const Text(
                  "Нет других досок",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  "Создайте еще одну доску",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<Board>(
                    value: _selectedBoard,
                    isExpanded: true,
                    underline: const SizedBox(),
                    borderRadius: BorderRadius.circular(12),
                    items: _boards.map((board) {
                      return DropdownMenuItem<Board>(
                        value: board,
                        child: Row(
                          children: [
                            Text(board.emoji),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                board.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: _isMoving ? null : (Board? board) {
                      setState(() => _selectedBoard = board);
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isMoving ? null : () => Navigator.of(context).pop(),
                      child: const Text("Отмена"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red.withValues(alpha: 0.8),
                        shadowColor: Colors.blue.withValues(alpha: 0.7),
                        elevation: 1.0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: (_selectedBoard == null || _isMoving) ? null : _submit,
                      child: _isMoving
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ) : const Text("Переместить"),
                      style: FilledButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green.withValues(alpha: 0.8),
                        shadowColor: Colors.green.withValues(alpha: 0.7),
                        elevation: 1.0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}