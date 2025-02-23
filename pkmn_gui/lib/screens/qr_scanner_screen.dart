import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/data_matrix_scanner.dart'; // Use the DataMatrixScanner widget
import '../api_calls.dart';
import '../main.dart'; // for UserSession and promptForPassword
import '../widgets/prompt_user_credentials.dart'; // new import for user credentials

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});
  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _scanned = false;
  bool _isProcessing = false; // new flag for UI feedback

  void _onGetResult(String result) async {
    if (!_scanned) {
      _scanned = true;
      setState(() {
        _isProcessing = true;
      });
      final scannedId = result;
      String name;
      String token;
      try {
        // Check if the user exists
        final exists = await ApiService.checkUserExists(scannedId);
        if (exists) {
          // Existing user: prompt for password for login
          final password = await promptForPassword(context);
          if (password == null || password.isEmpty) {
            _scanned = false;
            setState(() {
              _isProcessing = false;
            });
            return;
          }
          final loginResult = await ApiService.login(scannedId, password);
          if (loginResult['message']?.toString().contains(
                "Create new user first",
              ) ==
              true) {
            final createResult = await ApiService.createUser(
              scannedId,
              "Ny Användare",
              password,
            );
            name = "Ny Användare";
            token = createResult['token']?.toString() ?? "";
          } else {
            name = loginResult['name'] ?? "Okänt";
            token = loginResult['token']?.toString() ?? "";
          }
        } else {
          // New user: prompt for username, password and confirmation.
          final credentials = await promptForUserCredentials(
            context,
            scannedId,
          );
          if (credentials == null ||
              credentials['username']?.isEmpty == true ||
              credentials['password']?.isEmpty == true ||
              credentials['confirm']?.isEmpty == true ||
              credentials['password'] != credentials['confirm']) {
            _scanned = false;
            setState(() {
              _isProcessing = false;
            });
            return;
          }
          name = credentials['username'] ?? "Unnamed User";
          final password = credentials['password'] ?? "";
          final createResult = await ApiService.createUser(
            scannedId,
            name,
            password,
          );
          token = createResult['token']?.toString() ?? "";
        }
        Provider.of<UserSession>(
          context,
          listen: false,
        ).login(scannedId, name, token);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
        _scanned = false;
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: const CommonAppBar(title: 'Scanna ditt band'),
          body: Column(
            children: [
              Expanded(child: DataMatrixScanner(onCodeScanned: _onGetResult)),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Rikta kameran mot QR-koden på ditt band',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
        if (_isProcessing)
          Container(
            color: Colors.black45,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
