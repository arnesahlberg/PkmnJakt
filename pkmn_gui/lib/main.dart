import 'package:flutter/material.dart';
import 'package:pkmn_gui/screens/admin_screen.dart';
import 'package:pkmn_gui/screens/pokedex_screen.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import 'screens/main_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/profile_screen.dart';
import 'constants.dart';

// ------------------------------
// User Session Provider
class UserSession extends ChangeNotifier {
  String? userId;
  String? userName;
  String? token; // this will hold the encoded token only
  String? validUntil; // field to store validity info

  UserSession() {
    _loadFromCookies();
  }
  void _loadFromCookies() {
    final cookies = html.document.cookie;
    if (cookies != null) {
      for (var part in cookies.split(';')) {
        final trimmed = part.trim();
        if (trimmed.startsWith("userId=")) {
          userId = trimmed.substring("userId=".length);
        } else if (trimmed.startsWith("userName=")) {
          userName = trimmed.substring("userName=".length);
        } else if (trimmed.startsWith("token=")) {
          token = trimmed.substring("token=".length);
        } else if (trimmed.startsWith("valid_until=")) {
          validUntil = trimmed.substring("valid_until=".length);
          debugPrint("Loaded validUntil: $validUntil");
        }
      }
      notifyListeners();
    }
  }

  void login(
    String id,
    String name,
    String encodedToken,
    String validUntilValue,
  ) {
    userId = id;
    userName = name;
    token = encodedToken;
    validUntil = validUntilValue;
    final expDate = DateTime.now().add(const Duration(days: 30));
    final expDateStr = expDate.toUtc().toIso8601String();
    html.document.cookie = "userId=$id; expires=$expDateStr; path=/";
    html.document.cookie = "userName=$name; expires=$expDateStr; path=/";
    html.document.cookie = "token=$encodedToken; expires=$expDateStr; path=/";
    html.document.cookie =
        "valid_until=$validUntilValue; expires=$expDateStr; path=/";
    notifyListeners();
  }

  void logout() {
    userId = null;
    userName = null;
    token = null;
    html.document.cookie =
        "userId=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/";
    html.document.cookie =
        "userName=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/";
    html.document.cookie =
        "token=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/";
    notifyListeners();
  }

  void setUserName(String newValue) {
    userName = newValue;
    html.document.cookie = "userName=$newValue; path=/";
    notifyListeners();
  }

  bool isExpored() {
    if (validUntil == null) return true;
    final expDate = DateTime.parse(validUntil!);
    return DateTime.now().isAfter(expDate);
  }

  bool get isLoggedIn => userId != null;
}

// ------------------------------
// Main App
void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => UserSession(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stensund Pokemon-Jakt 2025!',
      theme: ThemeData(
        fontFamily: 'PixelFont',
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primaryRed,
          onPrimary: AppColors.white,
          secondary: AppColors.accentBlue,
          onSecondary: AppColors.white,
          tertiary: AppColors.accentYellow,
          error: Colors.red.shade700,
          onError: AppColors.white,
          background: AppColors.backgroundLight,
          onBackground: AppColors.textPrimary,
          surface: AppColors.primaryRed,
          onSurface: AppColors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: AppButtonStyles.primaryButtonStyle,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(UIConstants.borderRadius12),
            side: BorderSide(
              color: AppColors.primaryRed.withOpacity(0.5),
              width: UIConstants.borderWidth2,
            ),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primaryRed,
          elevation: 0,
          centerTitle: true,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
      ),
      home: const WelcomeScreen(),
      routes: {
        '/profile': (_) => const ProfileScreen(),
        '/home': (_) => const UserHomeScreen(),
        '/pokedex': (_) => const PokedexScreen(),
        '/admin': (_) => const AdminScreen(),
      },
    );
  }
}
