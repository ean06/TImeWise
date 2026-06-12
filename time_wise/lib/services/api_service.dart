import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:8080";
    } else if (Platform.isAndroid) {
      return "http://192.168.0.101:8080";
    } else {
      return "http://10.0.2.2:8080";
    }
  }


  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<String> register(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      final data = jsonDecode(response.body);
      return data['status'] ?? 'error';
    } catch (_) {
      return 'error';
    }
  }

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } catch (e) {
      return {'status': 'error', 'message': 'Koneksi gagal. Periksa server.'};
    }
  }

  // ── Jadwal ────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getJadwal(int idAkun) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/jadwal/$idAkun'),
      );
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> tambahJadwal(
      Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tambah-jadwal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } catch (_) {
      return {'status': 'error', 'message': 'Koneksi gagal'};
    }
  }

  static Future<bool> updateJadwal(
      int idJadwal, Map<String, dynamic> body) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/jadwal/$idJadwal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteJadwal(int idJadwal) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/jadwal/$idJadwal'),
      );
      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    } catch (_) {
      return false;
    }
  }
}