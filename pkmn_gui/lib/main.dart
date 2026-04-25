import 'package:flutter/material.dart';
import 'package:pkmn_gui/screens/admin_screen.dart';
import 'package:pkmn_gui/screens/pokedex_screen.dart';
import 'package:pkmn_gui/screens/admin_pokemon_found_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // import shared_preferences
import 'screens/main_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/highscore_page.dart';
import 'screens/game_statistics_screen.dart';
import 'screens/manual_login_screen.dart';
import 'constants.dart';

// ------------------------------
// User Session Provider
class UserSession extends ChangeNotifier {
  String? userId;
  String? userName;
  String? token; // this will hold the encoded token only
  String? validUntil; // field to store validity info
  Future<void>? _initializationFuture; // to await loading

  UserSession() {
    _initializationFuture = _loadFromStorage(); // call and store the future
  }

  Future<void> ensureInitialized() async {
    await _initializationFuture; // allow awaiting the loading process
  }

  // load from shared preferences
  Future<void> _loadFromStorage() async {
    // ensure it returns Future<void>
    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString("userId");
      userName = prefs.getString("userName");
      token = prefs.getString("token");
      validUntil = prefs.getString("valid_until");
      notifyListeners();
    } catch (e, s) {
      rethrow; // Rethrow to indicate initialization failure
    }
  }

  // login and save to shared preferences
  void login(
    String id,
    String name,
    String encodedToken,
    String validUntilValue,
  ) async {
    userId = id;
    userName = name;
    token = encodedToken;
    validUntil = validUntilValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("userId", id);
    await prefs.setString("userName", name);
    await prefs.setString("token", encodedToken);
    await prefs.setString("valid_until", validUntilValue);
    notifyListeners();
  }

  // logout and clear shared preferences
  void logout() async {
    userId = null;
    userName = null;
    token = null;
    validUntil = null; // clear validUntil
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("userId");
    await prefs.remove("userName");
    await prefs.remove("token");
    await prefs.remove("valid_until"); // remove valid_until
    notifyListeners();
  }

  // set username and save to shared preferences
  void setUserName(String newValue) async {
    userName = newValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("userName", newValue);
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
void main() async {
  // make main async
  WidgetsFlutterBinding.ensureInitialized(); // ensure bindings are initialized

  final userSession = UserSession(); // create instance
  try {
    await userSession.ensureInitialized(); // wait for storage to load
  } catch (e, s) {
    // Silent failure - app will continue with empty session
  }

  runApp(
    ChangeNotifierProvider.value(
      // use .value constructor
      value: userSession,
      child: const MyApp(),
    ),
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
        cardTheme: CardThemeData(
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
        '/highscore': (_) => const HighscorePage(),
        '/pokemon_found': (_) => const AdminPokemonFoundScreen(),
        '/game_statistics': (_) => const GameStatisticsScreen(),
        '/manual_login': (_) => const ManualLoginScreen(),
      },
    );
  }
}
