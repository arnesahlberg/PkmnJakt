import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import 'main_page.dart';
import 'screens/welcome_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/high_score_screen.dart';

// New: Global function to prompt for a password.
Future<String?> promptForPassword(BuildContext context) async {
  String password = "";
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Enter Password"),
        content: TextField(
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Password"),
          onChanged: (value) {
            password = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, password),
            child: const Text("Submit"),
          ),
        ],
      );
    },
  );
}

// ------------------------------
// User Session Provider
class UserSession extends ChangeNotifier {
  String? userId;
  String? userName;
  String? token;
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
        }
      }
      notifyListeners();
    }
  }

  void login(String id, String name, String newToken) {
    userId = id;
    userName = name;
    token = newToken;
    final expDate = DateTime.now().add(const Duration(days: 30));
    final expDateStr = expDate.toUtc().toIso8601String();
    html.document.cookie = "userId=$id; expires=$expDateStr; path=/";
    html.document.cookie = "userName=$name; expires=$expDateStr; path=/";
    html.document.cookie = "token=$newToken; expires=$expDateStr; path=/";
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
      title: 'Stensund Pkmn-Jakt 2025!',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepPurple,
        ).copyWith(secondary: Colors.yellowAccent),
      ),
      home: const WelcomeScreen(),
      routes: {
        '/scanner': (_) => const QRScannerScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/highscore': (_) => const HighScoreScreen(),
        '/home': (_) => const MainPage(),
      },
    );
  }
}

// ...other shared code remains...
