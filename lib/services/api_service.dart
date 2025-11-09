import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:pin_tag_client/services/storage_service.dart';

import '../models/board.dart';
import '../models/item.dart';

class ApiService {
  static const String baseUrl = "http://localhost:8000";
  
  static Future<Map<String, String>> getHeaders({bool isMultipart = false}) async {
    final storage = StorageService();
    final connectId = await storage.getConnectId();

    final Map<String, String> headers = {
      "X-Auth-Token": connectId ?? "pending",
    };

    if(!isMultipart) {
      headers["Content-Type"] = "application/json";
    }

    return headers;
  }

  String _getBodyError(String body) {
    Map<String, dynamic> jsonBody = jsonDecode(body);
    return jsonBody["detail"] ?? "Детали ошибки отсутствуют";
  }

  Future<Map<String, dynamic>> generateConnect(int userId, String clientName) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users/$userId/generate-connect"),
      headers: await getHeaders(),
      body: json.encode({"client_name": clientName}),
    );

    if(response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Ошибка ${response.statusCode}\n${_getBodyError(response.body)}");
    }
  }

  Future<Map<String, dynamic>> getConnectionStatus(String connectId, int userId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/connections/$connectId/status?user_id=$userId"),
      headers: await getHeaders(),
    );

    if(response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Ошибка ${response.statusCode}\n${_getBodyError(response.body)}");
    }
  }

  Future<Map<String, dynamic>> createBoard(int userId, String boardName, {String? boardEmoji}) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users/$userId/boards"),
      headers: await getHeaders(),
      body: jsonEncode({
        "board_name": boardName,
        "board_emoji": boardEmoji ?? "📁"
      }),
    );

    if(response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Ошибка ${response.statusCode}\n${_getBodyError(response.body)}");
    }
  }

  Future<Map<String, dynamic>> renameBoard(int userId, int boardId, String newBoardName, {String? newBoardEmoji}) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users/$userId/boards/$boardId").replace(queryParameters: {
        "new_board_name": newBoardName,
        "new_board_emoji": newBoardEmoji,
      }),
      headers: await getHeaders()
    );

    if(response.statusCode == 200 || response.statusCode == 206) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Ошибка ${response.statusCode}\n${_getBodyError(response.body)}");
    }
  }

  Future<Map<String, dynamic>> removeBoard(int userId, int boardId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/users/$userId/boards/$boardId"),
      headers: await getHeaders(),
    );

    if(response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Ошибка ${response.statusCode}\n${_getBodyError(response.body)}");
    }
  }

  Future<List<Board>> getBoards(int userId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/users/$userId/boards"),
      headers: await getHeaders(),
    );

    if(response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Board.fromJson(json)).toList();
    } else {
      throw Exception("Ошибка ${response.statusCode}\n${_getBodyError(response.body)}");
    }
  }

  Future<List<Item>> getBoardItems(int userId, int boardId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/users/$userId/boards/$boardId/items"),
      headers: await getHeaders(),
    );

    if(response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Item.fromJson(json)).toList();
    } else {
      throw Exception("Ошибка ${response.statusCode}\n${_getBodyError(response.body)}");
    }
  }

  Future<List<Item>> searchItems(int userId, String query) async {
    final response = await http.get(
      Uri.parse("$baseUrl/users/$userId/search?q=$query"),
      headers: await getHeaders(),
    );

    if(response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Item.fromJson(json)).toList();
    } else {
      throw Exception("Ошибка ${response.statusCode}\n${_getBodyError(response.body)}");
    }
  }

  Future<Map<String, dynamic>> createItem(int userId, Map<String, dynamic> itemData) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users/$userId/items"),
      headers: await getHeaders(),
      body: jsonEncode(itemData),
    );

    if(response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Ошибка ${response.statusCode}\n${_getBodyError(response.body)}");
    }
  }

  Future<Map<String, dynamic>> uploadFile(int userId, Map<String, dynamic> itemData, File file) async {
    final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/users/$userId/items/upload"));
    request.headers.addAll(await getHeaders(isMultipart: true));
    itemData.forEach((key, value) {
      request.fields[key] = value.toString();
    });
    
    request.files.add(
      await http.MultipartFile.fromPath("file", file.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if(response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Ошибка ${response.statusCode}\n${_getBodyError(response.body)}");
    }
  }

  Future<Map<String, dynamic>> moveItem(int userId, int itemId, int newBoardId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users/$userId/items/$itemId"),
      headers: await getHeaders(),
      body: jsonEncode({
        "new_board_id": newBoardId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Ошибка ${response.statusCode}\n${_getBodyError(response.body)}");
    }
  }

  Future<Map<String, dynamic>> removeItem(int userId, int itemId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/users/$userId/items/$itemId"),
      headers: await getHeaders(),
    );

    if(response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Ошибка ${response.statusCode}\n${_getBodyError(response.body)}");
    }
  }
}