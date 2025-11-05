

import 'package:flutter/material.dart';

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

      bool isApproved = await _waitForApproval(connectId);

      if(isApproved) {
        await _storageService.saveUserData(userId, connectId);
        _apiService.setConnectId(connectId);
        
        Navigator.pushReplacementNamed(context, '/home');
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

  Future<bool> _waitForApproval(String connectId) async {
    for (int i = 0; i < 100; i++) {
      await Future.delayed(Duration(seconds: 3));

      try {
        final status = await _apiService.getConnectionStatus(connectId);

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
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            if(_isLoading) CircularProgressIndicator(),
            if(_status.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                ),
              ),
            ElevatedButton(
                onPressed: _isLoading ? null : _connectToAccount,
                child: Text("Подключиться"),
            ),
          ],
        ),
      ),
    );
  }

}