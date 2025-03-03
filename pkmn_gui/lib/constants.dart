import 'package:flutter/material.dart';

class CallResultCode {
  static const int ok = 0;
  static const int userNotFound = 1;
  static const int invalidPassword = 2;
  static const int userAlreadyExists = 3;
  static const int pokemonNotFound = 4;
  static const int pokemonAlreadyFound = 5;
  static const int invalidToken = 6;
  static const int userNameTooShort = 7;
  static const int userNameTooLong = 8;
  static const int passwordTooShort = 9;
}

class Styles {
  static ButtonStyle get profileButtonStyle => ElevatedButton.styleFrom(
    minimumSize: const Size(
      double.infinity,
      56,
    ), // Full width and taller height
    padding: const EdgeInsets.symmetric(vertical: 12), // More vertical padding
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8), // Slightly rounded corners
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      fontFamily: 'PixelFont',
    ),
  );
}
