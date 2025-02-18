import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;
import 'package:flutter_web_qrcode_scanner/flutter_web_qrcode_scanner.dart';
import 'package:intl/intl.dart';
import 'widgets/common_app_bar.dart'; // import the common app bar
import 'widgets/data_matrix_scanner.dart'; // import the data matrix scanner
import 'main_page.dart'; // import the new main page

// ------------------------------
// API Service
class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8080';

  static Future<Map<String, dynamic>> login(String id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      body: jsonEncode({'id': id}),
      headers: {"Content-Type": "application/json"},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createUser(String id, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create_user'),
      body: jsonEncode({'id': id, 'name': name}),
      headers: {"Content-Type": "application/json"},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> setUserName(
    String id,
    String name,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/set_user_name'),
      body: jsonEncode({'id': id, 'name': name}),
      headers: {"Content-Type": "application/json"},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> foundPokemon(
    String userId,
    String pokemonId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/found_pokemon'),
      body: jsonEncode({'id': userId, 'pokemon_id': pokemonId}),
      headers: {"Content-Type": "application/json"},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> viewFoundPokemon(
    String userId,
    int n,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/view_found_pokemon'),
      body: jsonEncode({'id': userId, 'n': n}),
      headers: {"Content-Type": "application/json"},
    );
    return jsonDecode(response.body);
  }
}

// ------------------------------
// User Session Provider
class UserSession extends ChangeNotifier {
  String? userId;
  String? userName;

  void login(String id, String name) {
    userId = id;
    userName = name;
    // Save cookie to keep user logged in
    html.document.cookie = "userId=$id; path=/";
    notifyListeners();
  }

  void logout() {
    userId = null;
    userName = null;
    // Remove cookie
    html.document.cookie =
        "userId=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/";
    notifyListeners();
  }

  bool get isLoggedIn => userId != null;
}

// ------------------------------
// Main App
// ------------------------------
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
        primarySwatch: Colors.red,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.red,
        ).copyWith(secondary: Colors.yellowAccent),
      ),
      home: const WelcomeScreen(),
      routes: {
        '/scanner': (_) => const DataMatrixScannerScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/highscore': (_) => const HighScoreScreen(),
        '/home':
            (_) => const MainPage(), // new main page route for logged in users
      },
    );
  }
}

// ------------------------------
// WelcomeScreen: Displays welcome message and login button if not logged in,
// otherwise shows a button to go to the main page.
// ------------------------------
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<UserSession>(context);
    return Scaffold(
      appBar: const CommonAppBar(title: 'Stensund Pkmn-Jakt 2025!'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child:
              session.isLoggedIn
                  ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Välkommen tillbaka, ${session.userName}!',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          textStyle: const TextStyle(fontSize: 20),
                        ),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                        child: const Text('Gå till startsidan'),
                      ),
                    ],
                  )
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Välkommen till Stensund Pkmn-Jakt 2025!',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Klicka på knappen nedan och scanna ditt deltagar-band för rikslägret.',
                        style: TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                          textStyle: const TextStyle(fontSize: 20),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/scanner');
                        },
                        child: const Text('Logga in med bandet'),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}

// ------------------------------
// QRScannerScreen: Web QR code scanner using flutter_web_qrcode_scanner
// ------------------------------
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _scanned = false;

  void _onGetResult(String result) async {
    if (!_scanned) {
      _scanned = true;
      final scannedId = result;
      // Call API with scanned ID
      final loginResult = await ApiService.login(scannedId);
      if (loginResult['message'].toString().contains("Create new user first")) {
        await ApiService.createUser(scannedId, "Ny Användare");
        Provider.of<UserSession>(
          context,
          listen: false,
        ).login(scannedId, "Ny Användare");
      } else {
        Provider.of<UserSession>(
          context,
          listen: false,
        ).login(scannedId, loginResult['name'] ?? "Okänt");
      }
      if (!mounted) return;
      // Navigate to main page instead of the caught pokemon page
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Scanna ditt band'),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: FlutterWebQrcodeScanner(
                    cameraDirection: CameraDirection.back,
                    stopOnFirstResult: true,
                    onGetResult: _onGetResult,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Rikta kameran mot QR-koden på ditt band',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class DataMatrixScannerScreen extends StatelessWidget {
  const DataMatrixScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Data Matrix Code')),
      body: Column(
        children: [
          Expanded(
            child: DataMatrixScanner(
              onCodeScanned: (scannedCode) async {
                // Process the scanned code (e.g., log in or create a user)
                // For example:
                final result = await ApiService.login(scannedCode);
                if (result['message'].toString().contains(
                  "Create new user first",
                )) {
                  await ApiService.createUser(scannedCode, "Ny Användare");
                  Provider.of<UserSession>(
                    context,
                    listen: false,
                  ).login(scannedCode, "Ny Användare");
                } else {
                  Provider.of<UserSession>(
                    context,
                    listen: false,
                  ).login(scannedCode, result['name'] ?? "Okänt");
                }
                // Navigate to the highscore screen after scanning.
                Navigator.pushReplacementNamed(context, '/highscore');
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Rikta kameran mot din Data Matrix-kod.',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------
// ProfileScreen: User profile with common top bar
// ------------------------------
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<UserSession>(context);
    return Scaffold(
      appBar: const CommonAppBar(title: 'Min Profil'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Inloggad som: ${session.userName}",
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                session.logout();
                // Navigate back to the welcome screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text("Logga ut"),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------
// HighScoreScreen: Display the latest caught Pokémon with common top bar
// ------------------------------
class HighScoreScreen extends StatefulWidget {
  const HighScoreScreen({super.key});
  @override
  State<HighScoreScreen> createState() => _HighScoreScreenState();
}

class _HighScoreScreenState extends State<HighScoreScreen> {
  List<dynamic> _pokemonList = [];
  bool _isLoading = true;

  Future<void> _loadHighScore() async {
    final session = Provider.of<UserSession>(context, listen: false);
    try {
      final result = await ApiService.viewFoundPokemon(session.userId!, 10);
      setState(() {
        _pokemonList = result['pokemon_found'] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Fel vid hämtning: $e")));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHighScore();
  }

  String _formatTime(String isoTime) {
    // Convert ISO8601 to DateTime and format to a Swedish friendly format
    final dateTime = DateTime.parse(isoTime);
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    return formatter.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: "Mina fångster"),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _pokemonList.length,
                itemBuilder: (context, index) {
                  final pokemon = _pokemonList[index];
                  return ListTile(
                    title: Text(
                      "${pokemon['name']} (Nr. ${pokemon['number']})",
                    ),
                    subtitle: Text(
                      "Tid: ${_formatTime(pokemon['time_found'])}",
                    ),
                  );
                },
              ),
    );
  }
}
