import 'package:flutter/material.dart';
import '../controllers/storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    // TR: Splash ekranını göstermek için gecikme ekle | EN: Add delay to show splash screen | RU: Добавить задержку для показа заставки
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // TR: Kullanıcı giriş yapmış mı kontrol et | EN: Check if user is logged in | RU: Проверить, выполнен ли вход пользователя
    final isLoggedIn = await Storage.isLoggedIn();
    
    if (!mounted) return;
    
    if (isLoggedIn) {
      // TR: Kullanıcı giriş yapmış, ana sayfaya git | EN: User logged in, go to home | RU: Пользователь вошел, перейти на главную
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // TR: Kullanıcı giriş yapmamış, giriş ekranına git | EN: User not logged in, go to login | RU: Пользователь не вошел, перейти на вход
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.visibility,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                'OPTIX',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Smart Glasses',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
