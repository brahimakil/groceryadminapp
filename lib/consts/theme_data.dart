import 'package:flutter/material.dart';

class Styles {
  static ThemeData themeData(bool isDarkTheme, BuildContext context) {
    return ThemeData(
      scaffoldBackgroundColor:
          //0A1931  // white yellow 0xFFFCF8EC
          isDarkTheme ? const Color(0xFF00001a) : const Color(0xFFFFFFFF),
      primaryColor: Colors.blue,
      primaryColorLight: Colors.blue,
      primaryColorDark: Colors.blue.shade800,
      hintColor: isDarkTheme ? Colors.grey.shade400 : Colors.grey.shade700,
      textTheme: Theme.of(context).textTheme.apply(
        bodyColor: isDarkTheme ? Colors.white : Colors.black,
        displayColor: isDarkTheme ? Colors.white : Colors.black,
      ),
      iconTheme: IconThemeData(
        color: isDarkTheme ? Colors.white : Colors.black,
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(
          color: isDarkTheme ? Colors.white : Colors.black,
        ),
        hintStyle: TextStyle(
          color: isDarkTheme ? Colors.grey.shade400 : Colors.grey.shade700,
        ),
      ),
      colorScheme: ColorScheme.fromSwatch(
        brightness: isDarkTheme ? Brightness.dark : Brightness.light,
        primarySwatch: Colors.blue,
      ).copyWith(
        secondary: isDarkTheme ? const Color(0xFF1a1f3c) : const Color(0xFFE9FCFC),
        brightness: isDarkTheme ? Brightness.dark : Brightness.light,
      ),
      cardColor:
          isDarkTheme ? const Color(0xFF0a0d2c) : const Color(0xFFF2FDFD),
      canvasColor: isDarkTheme ? Colors.black : Colors.grey[50],
      buttonTheme: Theme.of(context).buttonTheme.copyWith(
          colorScheme: isDarkTheme
              ? const ColorScheme.dark()
              : const ColorScheme.light()),
    );
  }
}
