import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/home_page.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/LoginPage': (context) => const LoginPage(),
        '/RegisterPage': (context) => const RegisterPage(),
        '/HomePage': (context) => const HomePage(),
      },
    );
  }
}

