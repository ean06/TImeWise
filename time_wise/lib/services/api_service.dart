import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // AUTO DETECT PLATFORM
  static String get baseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:5000"; // Web
    } else {
      return "http://10.0.2.2:5000"; // Android Emulator
    }
  }

  // LOGIN
  static Future<String> login(String username, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "password": password,
      }),
    );

    final data = jsonDecode(response.body);
    return data["status"];
  }

  // REGISTER
  static Future<String> register(String username, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "password": password,
      }),
    );

    final data = jsonDecode(response.body);
    return data["status"];
  }
}