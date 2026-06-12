import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static Future<void> saveSession({
    required int idAkun,
    required String username,
    String? nama,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('id_akun', idAkun); 
    await prefs.setString('username', username);
    if (nama != null) {
      await prefs.setString('nama', nama);
    }
  }

  static Future<int> getIdAkun() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('id_akun') ?? 0;
  }

  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? 'Pengguna';
  }

  static Future<String> getNama() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nama') ?? '';
  }

  static Future<void> saveNama(String nama) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nama', nama);
  }

  static Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}