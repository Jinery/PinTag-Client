

import 'package:flutter/material.dart';
import 'package:pin_tag_client/screens/board_screen.dart';

import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreen createState() => _AuthScreen();
}

class _AuthScreen extends State<AuthScreen> {
  final _userIdController = TextEditingController();
  final _apiService = ApiService();
  final _storageService = StorageService();
  bool _isLoading = false;
  String _status = '';

  Future<void> _connectToAccount() async {
    if(_userIdController.text.isEmpty) {
      setState(() {
        _status = "Введи Id своего телеграмм-аккаунта.";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _status = "Подключение...";
    });

    try {
      final userId = int.parse(_userIdController.text);
      
      final response = await _apiService.generateConnect(userId, "Flutter Client");
      final connectId = response["connect_id"];

      setState(() {
        _status = "Запрос отправлен, ожидаю подтверждения...";
      });

      bool isApproved = await _waitForApproval(connectId, userId);

      if(isApproved) {
        await _storageService.saveUserData(userId, connectId);
        
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => BoardsScreen(userId: userId)),
        );
      } else {
        setState(() {
          _status = "Подключение отклонено";
          _isLoading = false;
        });
      }
    } on Exception catch (ex) {
      setState(() {
        _status = "Ошибка: $ex";
        _isLoading = false;
      });
    }
  }

  Future<bool> _waitForApproval(String connectId, int userId) async {
    for (int i = 0; i < 100; i++) {
      await Future.delayed(Duration(seconds: 3));

      try {
        final status = await _apiService.getConnectionStatus(connectId, userId);

        if (status['status'] == 'accepted') {
          return true;
        } else if (status['status'] == 'rejected') {
          return false;
        }
      } catch (e) {
        print('Error checking status: $e');
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PinTag - Подключение')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _userIdController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'ID пользователя',
                hintText: 'Введи свой Telegram ID',
                border: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.black54,
                    width: 1.5,
                    style: BorderStyle.solid
                  ),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                  color: Colors.black54,
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.blue,
                    width: 2.5,
                    style: BorderStyle.solid,
                  ),
                ),
                labelStyle: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20),
            if(_isLoading) CircularProgressIndicator(),
            if(_status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                ),
              ),
            ElevatedButton(
                onPressed: _isLoading ? null : _connectToAccount,
                child: Text("Подключиться",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  shadowColor: Colors.blue.withValues(alpha: 0.7),
                  elevation: 3.0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
                  minimumSize: Size(160, 50)
                ),
            ),
          ],
        ),
      ),
    );
  }

}