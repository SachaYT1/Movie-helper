// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Основная цветовая схема с использованием ColorScheme
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primaryColor,
        onPrimary: AppColors.textColor,
        primaryContainer: AppColors.primaryColor.withOpacity(0.8),
        onPrimaryContainer: AppColors.textColor,
        secondary: AppColors.secondaryColor,
        onSecondary: AppColors.textColor,
        secondaryContainer: AppColors.secondaryColor.withOpacity(0.8),
        onSecondaryContainer: AppColors.textColor,
        tertiary: AppColors.accentColor,
        onTertiary: AppColors.textColor,
        tertiaryContainer: AppColors.accentColor.withOpacity(0.8),
        onTertiaryContainer: AppColors.textColor,
        error: AppColors.errorColor,
        onError: AppColors.textColor,
        errorContainer: AppColors.errorColor.withOpacity(0.8),
        onErrorContainer: AppColors.textColor,
        background: AppColors.backgroundColor,
        onBackground: AppColors.textColor,
        surface: AppColors.surfaceColor,
        onSurface: AppColors.textColor,
        surfaceVariant: AppColors.cardColor,
        onSurfaceVariant: AppColors.textSecondaryColor,
        outline: AppColors.borderColor,
        outlineVariant: AppColors.dividerColor,
        shadow: AppColors.shadowColor,
        scrim: AppColors.overlayColor,
        inverseSurface: AppColors.textColor,
        onInverseSurface: AppColors.backgroundColor,
        inversePrimary: AppColors.backgroundLightColor,
        surfaceTint: AppColors.surfaceColor,
      ),
      
      // Настройка текстовых тем
      textTheme: TextTheme(
        displayLarge: TextStyle(color: AppColors.textColor),
        displayMedium: TextStyle(color: AppColors.textColor),
        displaySmall: TextStyle(color: AppColors.textColor),
        headlineLarge: TextStyle(color: AppColors.textColor),
        headlineMedium: TextStyle(color: AppColors.textColor),
        headlineSmall: TextStyle(color: AppColors.textColor),
        titleLarge: TextStyle(color: AppColors.textColor),
        titleMedium: TextStyle(color: AppColors.textColor),
        titleSmall: TextStyle(color: AppColors.textColor),
        bodyLarge: TextStyle(color: AppColors.textColor),
        bodyMedium: TextStyle(color: AppColors.textColor),
        bodySmall: TextStyle(color: AppColors.textSecondaryColor),
        labelLarge: TextStyle(color: AppColors.textColor),
        labelMedium: TextStyle(color: AppColors.textSecondaryColor),
        labelSmall: TextStyle(color: AppColors.textSecondaryColor),
      ),
      
      // Настройка полей ввода
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(color: AppColors.hintTextColor),
        labelStyle: TextStyle(color: AppColors.textSecondaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.secondaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.errorColor, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.errorColor, width: 2),
        ),
      ),
      
      // Настройка карточек с использованием актуального CardTheme
      cardTheme: CardTheme(
        color: AppColors.cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        clipBehavior: Clip.antiAlias,
      ),
      
      // Material 3 настройка кнопок через ButtonTheme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.disabled)) {
              return AppColors.secondaryColor.withOpacity(0.5);
            }
            return AppColors.secondaryColor;
          }),
          foregroundColor: MaterialStateProperty.all(AppColors.textColor),
          overlayColor: MaterialStateProperty.all(AppColors.rippleColor),
          elevation: MaterialStateProperty.all(0),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(vertical: 16, horizontal: 24)
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textStyle: MaterialStateProperty.all(
            const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.disabled)) {
              return AppColors.secondaryColor.withOpacity(0.5);
            }
            return AppColors.secondaryColor;
          }),
          overlayColor: MaterialStateProperty.all(AppColors.rippleColor),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(vertical: 8, horizontal: 16)
          ),
          textStyle: MaterialStateProperty.all(
            const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.disabled)) {
              return AppColors.secondaryColor.withOpacity(0.5);
            }
            return AppColors.secondaryColor;
          }),
          overlayColor: MaterialStateProperty.all(AppColors.rippleColor),
          side: MaterialStateProperty.resolveWith<BorderSide>((states) {
            if (states.contains(MaterialState.disabled)) {
              return BorderSide(color: AppColors.secondaryColor.withOpacity(0.5));
            }
            return BorderSide(color: AppColors.secondaryColor);
          }),
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(vertical: 16, horizontal: 24)
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textStyle: MaterialStateProperty.all(
            const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      
      // AppBar тема с использованием правильного синтаксиса
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundColor,
        foregroundColor: AppColors.textColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textColor,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textColor,
        ),
      ),
      
      // Настройка диалогового окна
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Настройка BottomNavigationBar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.backgroundColor,
        selectedItemColor: AppColors.secondaryColor,
        unselectedItemColor: AppColors.hintTextColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
      ),
      
      // Настройка компонентов выбора
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return AppColors.textDisabledColor;
          }
          if (states.contains(MaterialState.selected)) {
            return AppColors.secondaryColor;
          }
          return AppColors.borderColor;
        }),
        checkColor: MaterialStateProperty.all(AppColors.textColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: BorderSide(color: AppColors.borderColor),
      ),
      
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return AppColors.textDisabledColor;
          }
          if (states.contains(MaterialState.selected)) {
            return AppColors.secondaryColor;
          }
          return AppColors.borderColor;
        }),
      ),
      
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return AppColors.textDisabledColor;
          }
          if (states.contains(MaterialState.selected)) {
            return AppColors.secondaryColor;
          }
          return AppColors.textSecondaryColor;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.disabled)) {
            return AppColors.dividerColor;
          }
          if (states.contains(MaterialState.selected)) {
            return AppColors.secondaryColor.withOpacity(0.5);
          }
          return AppColors.borderColor;
        }),
      ),
      
      // Настройка делителей
      dividerTheme: DividerThemeData(
        color: AppColors.dividerColor,
        thickness: 1,
        space: 16,
      ),
      
      // Настройка сетки
      scaffoldBackgroundColor: AppColors.backgroundColor,
      
      // Настройка списочных плиток
      listTileTheme: ListTileThemeData(
        tileColor: AppColors.surfaceColor,
        iconColor: AppColors.textColor,
        textColor: AppColors.textColor,
        selectedTileColor: AppColors.primaryColor.withOpacity(0.2),
        selectedColor: AppColors.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Настройка индикатора прогресса
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.secondaryColor,
        linearTrackColor: AppColors.secondaryColor.withOpacity(0.2),
        circularTrackColor: AppColors.secondaryColor.withOpacity(0.2),
      ),
      
      // Общие настройки
      brightness: Brightness.dark,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      // Настройка табов
      tabBarTheme: TabBarTheme(
        labelColor: AppColors.secondaryColor,
        unselectedLabelColor: AppColors.hintTextColor,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.secondaryColor,
              width: 2,
            ),
          ),
        ),
      ),
      
      // Настройка меню
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
      ),
      
      // NavigationRail тема (для планшетов)
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.backgroundColor,
        selectedIconTheme: IconThemeData(color: AppColors.secondaryColor),
        unselectedIconTheme: IconThemeData(color: AppColors.hintTextColor),
        selectedLabelTextStyle: TextStyle(color: AppColors.secondaryColor),
        unselectedLabelTextStyle: TextStyle(color: AppColors.hintTextColor),
      ),
      
      // NavigationBar тема (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.backgroundColor,
        indicatorColor: AppColors.secondaryColor.withOpacity(0.2),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return IconThemeData(color: AppColors.secondaryColor);
          }
          return IconThemeData(color: AppColors.hintTextColor);
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return TextStyle(color: AppColors.secondaryColor);
          }
          return TextStyle(color: AppColors.hintTextColor);
        }),
      ),
    );
  }
  
  // Метод для получения темы на основе BuildContext
  static ThemeData of(BuildContext context) {
    return darkTheme;
  }
}