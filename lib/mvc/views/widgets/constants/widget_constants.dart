import 'package:flutter/material.dart';

class WidgetConstants {
  // TR: Boyutlar | EN: Sizes | RU: Размеры
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;

  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeMedium = 48.0;
  static const double avatarSizeLarge = 64.0;
  static const double avatarSizeXLarge = 96.0;

  static const double buttonHeightSmall = 32.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;

  static const double cardMinHeight = 80.0;
  static const double cardMaxHeight = 200.0;

  // TR: Boşluklar | EN: Spacing | RU: Отступы
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;

  // TR: Kenar yarıçapları | EN: Border radius | RU: Радиус скругления
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusXXLarge = 24.0;

  // TR: Yükseltiler | EN: Elevation | RU: Высота тени
  static const double elevationNone = 0.0;
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;
  static const double elevationXLarge = 16.0;

  // TR: Animasyon süreleri | EN: Animation durations | RU: Длительности анимаций
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // TR: Opaklık değerleri | EN: Opacity | RU: Непрозрачность
  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.6;
  static const double opacityHigh = 0.87;
  static const double opacityFull = 1.0;

  // TR: En-boy oranları | EN: Aspect ratios | RU: Соотношения сторон
  static const double aspectRatioSquare = 1.0;
  static const double aspectRatioGolden = 1.618;
  static const double aspectRatioWide = 16 / 9;
  static const double aspectRatioPortrait = 3 / 4;

  // TR: Kırılım noktaları | EN: Breakpoints | RU: Точки перелома
  static const double breakpointMobile = 600;
  static const double breakpointTablet = 900;
  static const double breakpointDesktop = 1200;

  // TR: Izgara ayarları | EN: Grid settings | RU: Настройки сетки
  static const int gridColumnsMobile = 1;
  static const int gridColumnsTablet = 2;
  static const int gridColumnsDesktop = 3;

  // TR: Liste yükseklikleri | EN: List heights | RU: Высоты списков
  static const int listItemHeight = 56;
  static const int listItemHeightDense = 48;
  static const int listItemHeightLarge = 72;

  // TR: Metin alanı yükseklikleri | EN: Text field heights | RU: Высоты текстовых полей
  static const double textFieldHeight = 56.0;
  static const double textFieldHeightDense = 48.0;
  static const double textFieldHeightLarge = 64.0;

  // TR: Uygulama çubuğu yükseklikleri | EN: App bar heights | RU: Высоты app bar
  static const double appBarHeight = 56.0;
  static const double appBarHeightLarge = 80.0;

  // TR: Alt gezinme yükseklikleri | EN: Bottom navigation heights | RU: Высоты нижней навигации
  static const double bottomNavHeight = 56.0;
  static const double bottomNavHeightLarge = 80.0;

  // TR: Çekmece genişlikleri | EN: Drawer widths | RU: Ширины бокового меню
  static const double drawerWidth = 280.0;
  static const double drawerWidthLarge = 320.0;

  // TR: Diyalog boyutları | EN: Dialog sizes | RU: Размеры диалогов
  static const double dialogMaxWidth = 400.0;
  static const double dialogMaxHeight = 600.0;

  // TR: Snackbar ayarları | EN: Snackbar settings | RU: Параметры snackbar
  static const double snackbarHeight = 48.0;
  static const Duration snackbarDuration = Duration(seconds: 3);

  // TR: Yükleme göstergeleri | EN: Loading indicators | RU: Индикаторы загрузки
  static const double loadingIndicatorSize = 24.0;
  static const double loadingIndicatorSizeLarge = 48.0;

  // TR: İlerleme çubukları | EN: Progress bars | RU: Полосы прогресса
  static const double progressBarHeight = 4.0;
  static const double progressBarHeightLarge = 8.0;

  // TR: Ayraç kalınlıkları | EN: Divider thickness | RU: Толщина разделителей
  static const double dividerThickness = 1.0;
  static const double dividerThicknessThick = 2.0;

  // TR: Chip yükseklikleri | EN: Chip heights | RU: Высоты чипов
  static const double chipHeight = 32.0;
  static const double chipHeightSmall = 24.0;
  static const double chipHeightLarge = 40.0;

  // TR: Rozet boyutları | EN: Badge sizes | RU: Размеры бейджей
  static const double badgeSize = 16.0;
  static const double badgeSizeSmall = 12.0;
  static const double badgeSizeLarge = 20.0;

  // TR: İpucu süreleri | EN: Tooltip durations | RU: Длительность подсказок
  static const Duration tooltipDelay = Duration(milliseconds: 500);
  static const Duration tooltipDuration = Duration(seconds: 2);

  // TR: Kaydırma eşikleri | EN: Swipe thresholds | RU: Пороги свайпа
  static const double swipeThreshold = 50.0;
  static const Duration swipeAnimationDuration = Duration(milliseconds: 200);

  // TR: Yenileme ayarları | EN: Refresh settings | RU: Настройки обновления
  static const double refreshIndicatorSize = 24.0;
  static const Duration refreshDuration = Duration(milliseconds: 1000);

  // TR: Geçiş (fade) süreleri | EN: Fade durations | RU: Длительности эффектов fade
  static const Duration fadeInDuration = Duration(milliseconds: 300);
  static const Duration fadeOutDuration = Duration(milliseconds: 200);

  // TR: Kaydırma animasyon süreleri | EN: Slide animation durations | RU: Длительности анимаций slide
  static const Duration slideInDuration = Duration(milliseconds: 300);
  static const Duration slideOutDuration = Duration(milliseconds: 200);

  // TR: Ölçekleme animasyon süreleri | EN: Scale animation durations | RU: Длительности анимаций scale
  static const Duration scaleInDuration = Duration(milliseconds: 200);
  static const Duration scaleOutDuration = Duration(milliseconds: 150);

  // TR: Döndürme süresi | EN: Rotation duration | RU: Длительность вращения
  static const Duration rotationDuration = Duration(milliseconds: 500);

  // TR: Zıplama süresi | EN: Bounce duration | RU: Длительность bounce
  static const Duration bounceDuration = Duration(milliseconds: 400);

  // TR: Elastik animasyon süresi | EN: Elastic duration | RU: Длительность elastic
  static const Duration elasticDuration = Duration(milliseconds: 600);

  // TR: Eğriler | EN: Curves | RU: Кривые
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve fastCurve = Curves.fastOutSlowIn;
  static const Curve slowCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve elasticCurve = Curves.elasticOut;
}
