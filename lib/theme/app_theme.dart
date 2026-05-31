import 'dart:ui';
import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color surfaceVariant = Color(0xFF1B2A4A);

  // Egyptian Judicial Golden Accents
  static const Color primary = Color(0xFFC8A951);
  static const Color primaryDark = Color(0xFFB8962E);
  static const Color onPrimary = Color(0xFF0D1117);

  static const Color secondary = Color(0xFF3B82F6); // Blue info/civil
  static const Color error = Color(0xFFEF4444); // Red warning/criminal
  static const Color success = Color(0xFF22C55E); // Green active/paid
  static const Color warning = Color(0xFFF59E0B); // Amber alerts/suspended

  static const Color onSurface = Color(0xFFE6EDF3);
  static const Color onSurfaceDim = Color(0xFF8B949E);
  static const Color border = Color(0x14FFFFFF); // 8% White border

  static const Color glassBackground = Color(0xD9161B22); // 85% opacity surface

  static const LinearGradient goldGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [background, Color(0xFF161E2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
      ),
      fontFamily: 'Cairo',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppColors.onSurface),
        headlineMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppColors.onSurface),
        headlineSmall: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppColors.onSurface),
        titleLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, color: AppColors.onSurface),
        titleMedium: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w500, color: AppColors.onSurface),
        bodyLarge: TextStyle(fontFamily: 'Cairo', color: AppColors.onSurface),
        bodyMedium: TextStyle(fontFamily: 'Cairo', color: AppColors.onSurfaceDim),
        labelLarge: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: const TextStyle(color: AppColors.onSurfaceDim, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.onSurfaceDim, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.onSurfaceDim,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: AppColors.onSurfaceDim);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontFamily: 'Cairo', color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12);
          }
          return const TextStyle(fontFamily: 'Cairo', color: AppColors.onSurfaceDim, fontSize: 12);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        selectedIconTheme: const IconThemeData(color: AppColors.primary),
        unselectedIconTheme: const IconThemeData(color: AppColors.onSurfaceDim),
        selectedLabelTextStyle: const TextStyle(fontFamily: 'Cairo', color: AppColors.primary, fontWeight: FontWeight.bold),
        unselectedLabelTextStyle: const TextStyle(fontFamily: 'Cairo', color: AppColors.onSurfaceDim),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        space: 1,
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? accentColor;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.accentColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: accentColor != null
              ? Row(
                  children: [
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: child),
                  ],
                )
              : child,
        ),
      ),
    );
  }
}
