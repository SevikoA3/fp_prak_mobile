import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_endpoints.dart';
import '../models/item.dart';
import '../services/user_service.dart';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Service class to handle CRUD operations for items
class ItemService {
  /// Ambil semua item
  Future<List<Item>> getItems(String token) async {
    try {
      var response = await http.get(
        Uri.parse(ApiEndpoints.baseUrl + ApiEndpoints.getItems),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 401) {
        final newToken = await UserService().refreshAccessToken();
        if (newToken != null) {
          response = await http.get(
            Uri.parse(ApiEndpoints.baseUrl + ApiEndpoints.getItems),
            headers: {
              'Authorization': 'Bearer $newToken',
              'Content-Type': 'application/json',
            },
          );
        }
      }
      if (response.statusCode == 200) {
        final List<dynamic> itemsJson = jsonDecode(response.body);
        return itemsJson.map((e) => Item.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load items');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Ambil item berdasarkan ID
  Future<Item?> getItemById(String id, String token) async {
    try {
      var response = await http.get(
        Uri.parse(ApiEndpoints.baseUrl + ApiEndpoints.getItems + '/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 401) {
        final newToken = await UserService().refreshAccessToken();
        if (newToken != null) {
          response = await http.get(
            Uri.parse(ApiEndpoints.baseUrl + ApiEndpoints.getItems + '/$id'),
            headers: {
              'Authorization': 'Bearer $newToken',
              'Content-Type': 'application/json',
            },
          );
        }
      }
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Jika ada field category/creator, tetap simpan di toJson()
        return Item.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Tambah item baru
  Future<void> addItem(Item item, String token, {dynamic imageFile}) async {
    if (kIsWeb) {
      var uri = Uri.parse(ApiEndpoints.baseUrl + ApiEndpoints.postItems);
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['name'] = item.name;
      request.fields['description'] = item.description ?? '';
      request.fields['quantity'] = item.quantity.toString();
      request.fields['category_id'] = item.categoryId.toString();
      if (imageFile != null) {
        final reader = html.FileReader();
        final completer = Completer<List<int>>();
        reader.readAsArrayBuffer(imageFile);
        reader.onLoadEnd.listen((event) {
          completer.complete(reader.result as List<int>);
        });
        final bytes = await completer.future;
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: imageFile.name,
          ),
        );
      }
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Failed to add item');
      }
      return;
    }
    var uri = Uri.parse(ApiEndpoints.baseUrl + ApiEndpoints.postItems);
    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['name'] = item.name;
    request.fields['description'] = item.description ?? '';
    request.fields['quantity'] = item.quantity.toString();
    request.fields['category_id'] = item.categoryId.toString();
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    }
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 401) {
      final newToken = await UserService().refreshAccessToken();
      if (newToken != null) {
        request.headers['Authorization'] = 'Bearer $newToken';
        streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      }
    }
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to add item');
    }
  }

  /// Update item yang sudah ada
  Future<void> updateItem(Item item, String token, {dynamic imageFile}) async {
    if (kIsWeb) {
      var uri = Uri.parse(
        (ApiEndpoints.baseUrl + ApiEndpoints.putItem).replaceFirst(
          ':id',
          item.id,
        ),
      );
      var request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['name'] = item.name;
      request.fields['description'] = item.description ?? '';
      request.fields['quantity'] = item.quantity.toString();
      request.fields['category_id'] = item.categoryId.toString();
      if (imageFile != null) {
        final reader = html.FileReader();
        final completer = Completer<List<int>>();
        reader.readAsArrayBuffer(imageFile);
        reader.onLoadEnd.listen((event) {
          completer.complete(reader.result as List<int>);
        });
        final bytes = await completer.future;
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: imageFile.name,
          ),
        );
      }
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode != 200) {
        throw Exception('Failed to update item');
      }
      return;
    }
    Future<http.Response> sendRequest(String authToken) async {
      var uri = Uri.parse(
        (ApiEndpoints.baseUrl + ApiEndpoints.putItem).replaceFirst(
          ':id',
          item.id,
        ),
      );
      var request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $authToken';
      request.fields['name'] = item.name;
      request.fields['description'] = item.description ?? '';
      request.fields['quantity'] = item.quantity.toString();
      request.fields['category_id'] = item.categoryId.toString();
      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }
      var streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    }

    var response = await sendRequest(token);
    if (response.statusCode == 401) {
      final newToken = await UserService().refreshAccessToken();
      if (newToken != null) {
        response = await sendRequest(newToken);
      }
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to update item');
    }
  }

  /// Hapus item berdasarkan ID
  Future<void> deleteItem(String id, String token) async {
    var response = await http.delete(
      Uri.parse(
        (ApiEndpoints.baseUrl + ApiEndpoints.deleteItem).replaceFirst(
          ':id',
          id,
        ),
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 401) {
      final newToken = await UserService().refreshAccessToken();
      if (newToken != null) {
        response = await http.delete(
          Uri.parse(
            (ApiEndpoints.baseUrl + ApiEndpoints.deleteItem).replaceFirst(
              ':id',
              id,
            ),
          ),
          headers: {
            'Authorization': 'Bearer $newToken',
            'Content-Type': 'application/json',
          },
        );
      }
    }
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete item');
    }
  }
}
