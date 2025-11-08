
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pin_tag_client/services/api_service.dart';

import '../models/content_type.dart';

class CreateItemDialog extends StatefulWidget {
  final int userId;
  final int boardId;
  final VoidCallback onItemCreated;

  const CreateItemDialog({
    Key? key,
    required this.userId,
    required this.boardId,
    required this.onItemCreated,
}) : super(key: key);

  @override
  State<CreateItemDialog> createState() => _CreateItemDialog();
}

class _CreateItemDialog extends State<CreateItemDialog> {
  final _apiService = ApiService();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  ContentType _selectedType = ContentType.link;
  bool _isLoading = false;

  PlatformFile? _selectedFile;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedType == ContentType.link) {
      if (!_formKey.currentState!.validate()) return;

    } else {
      if (_selectedFile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Выбери файл для отправки")),
          );
        }
        return;
      }

      if (_titleController.text.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Введи название элемента")),
          );
        }
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final itemData = {
        "board_id": widget.boardId,
        "title": _titleController.text.trim(),
        "content_type": _selectedType.toContentString,
        "content_data": _contentController.text.trim(),
      };

      if(_selectedType == ContentType.link) {
        await _apiService.createItem(widget.userId, itemData);
      } else {
        final file = File(_selectedFile!.path!);
        await _apiService.uploadFile(widget.userId, itemData, file);
      }

      widget.onItemCreated();
      if (mounted) Navigator.of(context).pop();
    } on Exception catch (ex) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка создания: ${ex.toString()}")),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result;

    try {
      if (_selectedType == ContentType.photo) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
        );
      } else if (_selectedType == ContentType.document) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        );
      } else if (_selectedType == ContentType.video) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.video,
        );
      } else {
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка выбора файла: $e")),
        );
      }
      return;
    }


    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = result!.files.single;
        _contentController.clear();
      });
    }
  }

  String _getContentHint() {
    return switch (_selectedType) {
      ContentType.link => "https://example.com",
      ContentType.photo => "Изображение",
      ContentType.video => "Видео",
      ContentType.document => "Документ",
      ContentType.unknown => "Введите данные...",
    };
  }

  bool get _showTextField => _selectedType == ContentType.link || (_selectedFile == null && _contentController.text.isNotEmpty);

  bool get _showFileControls =>
      _selectedType == ContentType.photo ||
      _selectedType == ContentType.video ||
      _selectedType == ContentType.document;

  @override
  Widget build(BuildContext context) {
    if (_selectedFile != null && (_selectedType == ContentType.link || _selectedType == ContentType.unknown)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedFile = null;
        });
      });
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Создать элемент',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: "Название элемента",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Введи название";
                    }
                    if (value.trim().length > 100) {
                      return "Название слишком длинное";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<ContentType>(
                    value: _selectedType,
                    isExpanded: true,
                    underline: const SizedBox(),
                    onChanged: (ContentType? newType) {
                      if (newType != null) {
                        setState(() {
                          _selectedType = newType;
                          _selectedFile = null;
                        });
                      }
                    },
                    items: ContentType.values
                        .where((type) => type != ContentType.unknown)
                        .map((type) {
                      return DropdownMenuItem<ContentType>(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                if (_selectedType == ContentType.link)
                  TextFormField(
                    controller: _contentController,
                    maxLines: _selectedType == ContentType.document ? 4 : 2,
                    decoration: InputDecoration(
                      labelText: _selectedType.displayName,
                      hintText: _getContentHint(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (_selectedType == ContentType.link || _selectedFile == null) {
                        if (value == null || value.trim().isEmpty) {
                          return "Введи данные";
                        }
                        if (_selectedType == ContentType.link) {
                          final url = value.trim();
                          if (!url.startsWith('http://') && !url.startsWith('https://')) {
                            return "Введи корректный URL (начинается с http:// или https://)";
                          }
                        }
                      }
                      return null;
                    },
                  )
                else if (_showFileControls)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getContentHint()),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.upload_file),
                        label: Text(
                            _selectedFile != null ? "Изменить файл" : "Выбрать файл",
                            textAlign: TextAlign.center
                        ),
                        onPressed: _pickFile,
                      ),
                      if (_selectedFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Файл: ${_selectedFile!.name}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text("Отмена"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isLoading || (_selectedType != ContentType.link && _selectedFile == null)
                            ? null
                            : _submit,
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
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