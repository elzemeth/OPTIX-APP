import 'package:flutter/material.dart';

class WidgetConstants {
  // Sizes
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

  // Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;

  // Border Radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusXXLarge = 24.0;

  // Elevation
  static const double elevationNone = 0.0;
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;
  static const double elevationXLarge = 16.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Opacity
  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.6;
  static const double opacityHigh = 0.87;
  static const double opacityFull = 1.0;

  // Aspect Ratios
  static const double aspectRatioSquare = 1.0;
  static const double aspectRatioGolden = 1.618;
  static const double aspectRatioWide = 16 / 9;
  static const double aspectRatioPortrait = 3 / 4;

  // Breakpoints
  static const double breakpointMobile = 600;
  static const double breakpointTablet = 900;
  static const double breakpointDesktop = 1200;

  // Grid
  static const int gridColumnsMobile = 1;
  static const int gridColumnsTablet = 2;
  static const int gridColumnsDesktop = 3;

  // List
  static const int listItemHeight = 56;
  static const int listItemHeightDense = 48;
  static const int listItemHeightLarge = 72;

  // Text Field
  static const double textFieldHeight = 56.0;
  static const double textFieldHeightDense = 48.0;
  static const double textFieldHeightLarge = 64.0;

  // App Bar
  static const double appBarHeight = 56.0;
  static const double appBarHeightLarge = 80.0;

  // Bottom Navigation
  static const double bottomNavHeight = 56.0;
  static const double bottomNavHeightLarge = 80.0;

  // Drawer
  static const double drawerWidth = 280.0;
  static const double drawerWidthLarge = 320.0;

  // Dialog
  static const double dialogMaxWidth = 400.0;
  static const double dialogMaxHeight = 600.0;

  // Snackbar
  static const double snackbarHeight = 48.0;
  static const Duration snackbarDuration = Duration(seconds: 3);

  // Loading
  static const double loadingIndicatorSize = 24.0;
  static const double loadingIndicatorSizeLarge = 48.0;

  // Progress
  static const double progressBarHeight = 4.0;
  static const double progressBarHeightLarge = 8.0;

  // Divider
  static const double dividerThickness = 1.0;
  static const double dividerThicknessThick = 2.0;

  // Chip
  static const double chipHeight = 32.0;
  static const double chipHeightSmall = 24.0;
  static const double chipHeightLarge = 40.0;

  // Badge
  static const double badgeSize = 16.0;
  static const double badgeSizeSmall = 12.0;
  static const double badgeSizeLarge = 20.0;

  // Tooltip
  static const Duration tooltipDelay = Duration(milliseconds: 500);
  static const Duration tooltipDuration = Duration(seconds: 2);

  // Swipe
  static const double swipeThreshold = 50.0;
  static const Duration swipeAnimationDuration = Duration(milliseconds: 200);

  // Refresh
  static const double refreshIndicatorSize = 24.0;
  static const Duration refreshDuration = Duration(milliseconds: 1000);

  // Fade
  static const Duration fadeInDuration = Duration(milliseconds: 300);
  static const Duration fadeOutDuration = Duration(milliseconds: 200);

  // Slide
  static const Duration slideInDuration = Duration(milliseconds: 300);
  static const Duration slideOutDuration = Duration(milliseconds: 200);

  // Scale
  static const Duration scaleInDuration = Duration(milliseconds: 200);
  static const Duration scaleOutDuration = Duration(milliseconds: 150);

  // Rotation
  static const Duration rotationDuration = Duration(milliseconds: 500);

  // Bounce
  static const Duration bounceDuration = Duration(milliseconds: 400);

  // Elastic
  static const Duration elasticDuration = Duration(milliseconds: 600);

  // Curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve fastCurve = Curves.fastOutSlowIn;
  static const Curve slowCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve elasticCurve = Curves.elasticOut;
}
