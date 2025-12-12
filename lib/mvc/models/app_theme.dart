import 'package:flutter/material.dart';

class AppTheme {
  // TR: Renk şemaları | EN: Color schemes | RU: Цветовые схемы
  static const ColorScheme lightColorScheme = ColorScheme.light(
    primary: Color(0xFF6366F1),
    secondary: Color(0xFF8B5CF6),
    surface: Color(0xFFF8FAFC),
    error: Color(0xFFEF4444),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1E293B),
    onError: Color(0xFFFFFFFF),
  );

  static const ColorScheme darkColorScheme = ColorScheme.dark(
    primary: Color(0xFF6366F1),
    secondary: Color(0xFF8B5CF6),
    surface: Color(0xFF1E293B),
    error: Color(0xFFEF4444),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onSurface: Color(0xFFF1F5F9),
    onError: Color(0xFFFFFFFF),
  );

  // TR: Metin stilleri | EN: Text styles | RU: Текстовые стили
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // TR: Buton stilleri | EN: Button styles | RU: Стили кнопок
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
  );

  static ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    side: const BorderSide(width: 1.5),
  );

  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  // TR: Kart stilleri | EN: Card styles | RU: Стили карточек
  static CardThemeData cardTheme = CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    margin: const EdgeInsets.all(8),
  );

  // TR: Girdi süslemeleri | EN: Input decoration | RU: Оформление полей ввода
  static InputDecoration inputDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // TR: Uygulama çubuğu teması | EN: App bar theme | RU: Тема app bar
  static AppBarTheme appBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: titleLarge.copyWith(color: colorScheme.onSurface),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
    );
  }

  // TR: Alt gezinme çubuğu teması | EN: Bottom navigation bar theme | RU: Тема нижней навигации
  static BottomNavigationBarThemeData bottomNavTheme(ColorScheme colorScheme) {
    return BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.6),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    );
  }

  // TR: Çekmece teması | EN: Drawer theme | RU: Тема бокового меню
  static DrawerThemeData drawerTheme(ColorScheme colorScheme) {
    return DrawerThemeData(
      backgroundColor: colorScheme.surface,
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
    );
  }

  // TR: Cam kart stili | EN: Glass card style | RU: Стиль стеклянной карточки
  static BoxDecoration glassCardDecoration({
    required Color backgroundColor,
    required List<Color> gradientColors,
  }) {
    return BoxDecoration(
      color: backgroundColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // TR: Gradyan renkleri | EN: Gradient colors | RU: Цвета градиента
  static const List<Color> lightGradientColors = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
  ];
  static const List<Color> darkGradientColors = [
    Color(0xFF1E293B),
    Color(0xFF0F172A),
  ];

  // TR: Gradyan arka planlar | EN: Gradient backgrounds | RU: Градиентные фоны
  static const LinearGradient lightGradient = LinearGradient(
    colors: lightGradientColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: darkGradientColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // TR: Tema verisi | EN: Theme data | RU: Данные темы
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: lightColorScheme,
    appBarTheme: appBarTheme(lightColorScheme),
    cardTheme: cardTheme,
    bottomNavigationBarTheme: bottomNavTheme(lightColorScheme),
    drawerTheme: drawerTheme(lightColorScheme),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    appBarTheme: appBarTheme(darkColorScheme),
    cardTheme: cardTheme,
    bottomNavigationBarTheme: bottomNavTheme(darkColorScheme),
    drawerTheme: drawerTheme(darkColorScheme),
  );
}
