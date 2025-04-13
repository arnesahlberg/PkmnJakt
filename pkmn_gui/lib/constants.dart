import 'package:flutter/material.dart';

class CallResultCode {
  // API response codes
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

class UIConstants {
  static const double pokedexImageSize = 64;
  static const double separatingHeight = 20;
}

class MyColors {
  static const Color primaryColor = Color(0xFFE3350D);
  static const Color secondaryColor = Color(0xFF992109);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color primaryTextColor = primaryColor;
  static const Color secondaryTextColor = secondaryColor;
  static const Color buttonTextColor = white;
}

class ButtonStyles {
  static ButtonStyle get buttonStyleWide => ElevatedButton.styleFrom(
    minimumSize: const Size(
      double.infinity,
      56,
    ), // Full width and taller height
    padding: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8), // rounded corners
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      fontFamily: 'PixelFont',
    ),
  );

  // other style of button
  static ButtonStyle get buttonStyleRounder => ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 20),
    textStyle: const TextStyle(fontSize: 20, fontFamily: 'PixelFont'),
  );
}

class TextStyles {
  static const headerTextStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontFamily: 'PixelFont',
    color: MyColors.primaryTextColor,
  );

  static const smallTextBold = TextStyle(
    fontFamily: 'PixelFont',
    fontWeight: FontWeight.bold,
    fontSize: 12,
  );

  static const smallText = TextStyle(fontFamily: 'PixelFont', fontSize: 12);

  static const smallTextItallic = TextStyle(
    fontFamily: 'PixelFont',
    fontSize: 12,
    color: Colors.grey,
  );

  static const welcomeTextStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    fontFamily: 'PixelFont',
    color: MyColors.primaryTextColor,
  );

  static const buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    fontFamily: 'PixelFont',
    color: MyColors.buttonTextColor,
  );
}
