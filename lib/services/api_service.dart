import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/board.dart';
import '../models/item.dart';

class ApiService {
  static const String baseUrl = "http://localhost:8000";
  String? connectId;

  void setConnectId(String connectId) {
    this.connectId = connectId;
  }

  Map<String, String> get _headers {
    return {
      "X-Auth-Token": connectId ?? "pending",
      "Content-Type": "application/json",
    };
  }

  Future<Map<String, dynamic>> generateConnect(int userId, String clientName) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users/$userId/generate-connect"),
      headers: _headers,
      body: json.encode({"client_name": clientName}),
    );

    if(response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Не удалось установить подключение\nКод: ${response.statusCode}");
    }
  }

  Future<Map<String, dynamic>> getConnectionStatus(String connectId, int userId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/connections/$connectId/status?user_id=$userId"),
      headers: _headers,
    );

    if(response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Не удалось получить статус подключения\nКод: ${response.statusCode}");
    }
  }

  Future<List<Board>> getBoards(int userId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/users/$userId/boards"),
      headers: _headers,
    );

    if(response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Board.fromJson(json)).toList();
    } else {
      throw Exception("Не удалось получить доски для текущего пользователя\nКод: ${response.statusCode}");
    }
  }

  Future<List<Item>> getBoardItems(int userId, int boardId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/users/$userId/boards/$boardId/items"),
      headers: _headers,
    );

    if(response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Item.fromJson(json)).toList();
    } else {
      throw Exception("Не удалось получить все элементы доски\nКод: ${response.statusCode}");
    }
  }

  Future<List<Item>> searchItems(int userId, String query) async {
    final response = await http.get(
      Uri.parse("$baseUrl/users/$userId/search?q=$query"),
      headers: _headers,
    );

    if(response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Item.fromJson(json)).toList();
    } else {
      throw Exception("Не удалось найти элементы по запросу $query\nКод: ${response.statusCode}");
    }
  }

  Future<Map<String, dynamic>> createItem(int userId, Map<String, dynamic> itemData) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users/$userId/items"),
      headers: _headers,
      body: jsonEncode(itemData),
    );

    if(response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Ошибка при создании элемента\nКод: ${response.statusCode}");
    }
  }

  Future<Map<String, dynamic>> moveItem(int userId, int itemId, int newBoardId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users/$userId/items/$itemId"),
      headers: _headers,
      body: jsonEncode({
        "new_board_id": newBoardId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Ошибка при перемещении элемента: ${response.statusCode}");
    }
  }

  Future<Map<String, dynamic>> removeItem(int userId, int itemId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/users/$userId/items/$itemId"),
      headers: _headers,
    );

    if(response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Ошибка при удалении элемента\nКод: ${response.statusCode}");
    }
  }
}