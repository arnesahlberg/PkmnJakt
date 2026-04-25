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
  static const int userNotAdmin = 10;
  static const int userIdTooShort = 11;
  static const int userIdTooLong = 12;
  static const int userIdInvalidFormat = 13;
}

class UIConstants {
  static const double pokedexImageSize = 64;
  static const double separatingHeight = 20;

  // Common padding values
  static const double padding8 = 8.0;
  static const double padding12 = 12.0;
  static const double padding16 = 16.0;
  static const double padding24 = 24.0;

  // Common spacing heights
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing10 = 10.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;

  // Common border radius values
  static const double borderRadius4 = 4.0;
  static const double borderRadius8 = 8.0;
  static const double borderRadius10 = 10.0;
  static const double borderRadius12 = 12.0;
  static const double borderRadius16 = 16.0;

  // Common border widths
  static const double borderWidth1 = 1.0;
  static const double borderWidth2 = 2.0;
  static const double borderWidth3 = 3.0;
  static const double borderWidth4 = 4.0;

  // Common icon sizes
  static const double iconSizeSmall = 12.0;
  static const double iconSizeNormal = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeExtraLarge = 48.0;
  static const double iconSizeHuge = 64.0;
  static const double iconSizeMax = 80.0;
}

class AppColors {
  // Primary colors
  static const Color primaryRed = Color(0xFFE3350D); // Classic Pokédex red
  static const Color secondaryRed = Color(
    0xFF992109,
  ); // Darker red for borders and shadows

  // Background colors
  static const Color backgroundLight = Color(
    0xFFFAF6F6,
  ); // Slight off-white background
  static const Color backgroundRedTint = Color(
    0xFFFAF6F6,
  ); // Same as backgroundLight, consistent naming

  // Text colors
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Color.fromARGB(255, 36, 34, 34);
  static const Color textLight = Colors.white;
  static const Color textError = Colors.red;

  // Accent colors
  static const Color accentBlue = Color(0xFF62B1F6); // Pokédex accent blue
  static const Color accentYellow = Color(0xFFFFD700); // Pokemon yellow

  // Neutral colors
  static const Color white = Colors.white;
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color mediumGrey = Color(0xFFE0E0E0);

  // Medal colors
  static const Color goldMedal = Colors.amber;
  static const Color silverMedal = Color(0xFFBDBDBD); // Colors.grey[400]
  static const Color bronzeMedal = Color(0xFFBCAAA4); // Colors.brown[300]

  // Shadow colors
  static const Color shadowColor = Color(0xFF992109);

  // Legacy compatibility (these should eventually be removed and replaced with the above)
  static const Color primaryColor = primaryRed;
  static const Color secondaryColor = secondaryRed;
  static const Color backgroundColor = backgroundLight;
  static const Color black = Colors.black;
  static const Color primaryTextColor = primaryRed;
  static const Color secondaryTextColor = secondaryRed;
  static const Color buttonTextColor = white;
}

class AppBorderStyles {
  static BorderSide primaryBorder = const BorderSide(
    color: AppColors.secondaryRed,
    width: UIConstants.borderWidth2,
  );

  static BorderSide thinPrimaryBorder = const BorderSide(
    color: AppColors.secondaryRed,
    width: UIConstants.borderWidth1,
  );

  static BorderSide thickPrimaryBorder = const BorderSide(
    color: AppColors.secondaryRed,
    width: UIConstants.borderWidth3,
  );

  static BorderSide errorBorder = BorderSide(
    color: Colors.red.shade700,
    width: UIConstants.borderWidth2,
  );

  static BorderSide lightErrorBorder = BorderSide(
    color: Colors.red.shade300,
    width: UIConstants.borderWidth1,
  );

  static BorderSide focusedPrimaryBorder = const BorderSide(
    color: AppColors.primaryRed,
    width: UIConstants.borderWidth2,
  );

  static BorderSide greyBorder = BorderSide(
    color: Colors.grey.shade400,
    width: UIConstants.borderWidth1,
  );
}

class AppBoxDecorations {
  static BoxDecoration primaryContainer = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(UIConstants.borderRadius12),
    border: Border.all(
      color: AppColors.secondaryRed,
      width: UIConstants.borderWidth2,
    ),
  );

  static BoxDecoration secondaryContainer = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(UIConstants.borderRadius8),
    border: Border.all(
      color: AppColors.secondaryRed,
      width: UIConstants.borderWidth1,
    ),
  );

  static BoxDecoration gradientBackground = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.backgroundLight, Colors.red.shade50],
    ),
  );

  static BoxDecoration dialogDecorations = BoxDecoration(
    borderRadius: BorderRadius.circular(UIConstants.borderRadius12),
    border: Border.all(
      color: AppColors.secondaryRed,
      width: UIConstants.borderWidth2,
    ),
  );

  static BoxDecoration pokedexContainerDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, Colors.grey.shade50],
    ),
  );
}

class AppButtonStyles {
  // Primary button style with red background
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryRed,
    foregroundColor: AppColors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(UIConstants.borderRadius8),
      side: const BorderSide(
        color: AppColors.secondaryRed,
        width: UIConstants.borderWidth2,
      ),
    ),
  );

  // Secondary button style
  static ButtonStyle secondaryButtonStyle = TextButton.styleFrom(
    foregroundColor: AppColors.secondaryRed,
  );

  // Danger button style for delete operations
  static ButtonStyle dangerButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    foregroundColor: AppColors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(UIConstants.borderRadius8),
    ),
  );

  // Legacy styles (for backward compatibility)
  static ButtonStyle get buttonStyleWide => ElevatedButton.styleFrom(
    minimumSize: const Size(double.infinity, 56),
    padding: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(UIConstants.borderRadius8),
    ),
    textStyle: AppTextStyles.buttonText,
  );

  static ButtonStyle get buttonStyleRounder => ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 20),
    textStyle: const TextStyle(fontSize: 20, fontFamily: 'PixelFont'),
  );
}

class AppTextStyles {
  // Title text styles
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'PixelFontTitle',
    fontSize: 24,
    color: AppColors.primaryRed,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'PixelFontTitle',
    fontSize: 20,
    color: AppColors.primaryRed,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: 'PixelFontTitle',
    fontSize: 18,
    color: AppColors.primaryRed,
  );

  // Body text styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'PixelFont',
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'PixelFont',
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'PixelFont',
    fontSize: 12,
    color: AppColors.textPrimary,
  );

  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'PixelFont',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.secondaryRed,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'PixelFont',
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.secondaryRed,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'PixelFont',
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.secondaryRed,
  );

  // Button text
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    fontFamily: 'PixelFont',
    color: AppColors.white,
  );

  // Error text
  static TextStyle errorText = TextStyle(
    color: Colors.red.shade700,
    fontFamily: 'PixelFont',
    fontSize: 14,
  );

  // Legacy styles (for backward compatibility)
  static const TextStyle headerTextStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontFamily: 'PixelFont',
    color: AppColors.primaryTextColor,
  );

  static const TextStyle smallTextBold = TextStyle(
    fontFamily: 'PixelFont',
    fontWeight: FontWeight.bold,
    fontSize: 12,
  );

  static const TextStyle smallText = TextStyle(
    fontFamily: 'PixelFont',
    fontSize: 12,
  );

  static const TextStyle smallTextItallic = TextStyle(
    fontFamily: 'PixelFont',
    fontSize: 12,
    color: Colors.grey,
  );

  static const TextStyle welcomeTextStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    fontFamily: 'PixelFont',
    color: AppColors.primaryTextColor,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    fontFamily: 'PixelFont',
    color: AppColors.buttonTextColor,
  );
}

// For input fields
class AppInputDecorations {
  static InputDecoration defaultInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade700),
      hintStyle: TextStyle(color: Colors.grey.shade500),
      filled: true,
      fillColor: AppColors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(UIConstants.borderRadius8),
        borderSide: AppBorderStyles.greyBorder,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(UIConstants.borderRadius8),
        borderSide: AppBorderStyles.focusedPrimaryBorder,
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(UIConstants.borderRadius8),
        borderSide: AppBorderStyles.errorBorder,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(UIConstants.borderRadius8),
        borderSide: AppBorderStyles.lightErrorBorder,
      ),
    );
  }

  static InputDecoration simpleInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textPrimary),
      border: const OutlineInputBorder(),
    );
  }

  static InputDecoration errorInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textPrimary),
      border: const OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}

// Shadow styles
class AppShadows {
  static const List<Shadow> textShadow = [
    Shadow(
      offset: Offset(1.0, 1.0),
      blurRadius: 2.0,
      color: AppColors.shadowColor,
    ),
  ];

  static const List<Shadow> titleShadow = [
    Shadow(
      offset: Offset(1.0, 1.0),
      blurRadius: 3.0,
      color: AppColors.shadowColor,
    ),
  ];

  static List<BoxShadow> containerShadow = [
    BoxShadow(
      color: AppColors.shadowColor.withOpacity(0.3),
      spreadRadius: 1,
      blurRadius: 2,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> lightShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      spreadRadius: 1,
      blurRadius: 2,
    ),
  ];
}

// redef old classes to use the new structure (to maintain compatibility)
class MyColors extends AppColors {}

class ButtonStyles extends AppButtonStyles {}

class TextStyles extends AppTextStyles {}
