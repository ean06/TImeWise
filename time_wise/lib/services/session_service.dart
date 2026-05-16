import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static Future<void> saveSession({
    required int idAkun,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('idAkun', idAkun);
    await prefs.setString('username', username);
  }

  static Future<int> getIdAkun() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('idAkun') ?? 0;
  }

  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? 'Pengguna';
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}