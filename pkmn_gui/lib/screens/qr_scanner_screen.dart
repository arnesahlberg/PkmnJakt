import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/data_matrix_scanner.dart';
import '../api_calls.dart';
import '../main.dart'; // for UserSession
import '../widgets/login_popup.dart';
import '../widgets/new_user_prompt.dart';
import '../constants.dart';

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
      String encodedToken;
      String validUntil;

      try {
        // chekc if this is a user_id and not something else (like pokemon_id)
        // thing they should be 6 digits long, but just check it's shorter than 10 for now
        if (scannedId.length > 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Felaktig kod, försök igen")),
          );
          _scanned = false;
          setState(() {
            _isProcessing = false;
          });
          return;
        }

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
          // Check CallResultCode instead of message string
          if (loginResult['result_code'] != CallResultCode.ok) {
            if (loginResult['result_code'] == CallResultCode.invalidPassword) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Fel lösenord, försök igen")),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Något gick fel. Felkod: ${loginResult['result_code']}",
                  ),
                ),
              );
            }
            _scanned = false;
            setState(() {
              _isProcessing = false;
            });
            return;
          }
          name = loginResult['name'] ?? "Error fetching name";
          encodedToken =
              loginResult['token']?['encoded_token'].toString() ?? "";
          validUntil = loginResult['token']?['valid_until']?.toString() ?? "";
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
          name = credentials['username'] ?? "Could not fetch name";
          final password = credentials['password'] ?? "";
          final createResult = await ApiService.createUser(
            scannedId,
            name,
            password,
          );
          // Use CallResultCode to validate creation attempt
          if (createResult['result_code'] != CallResultCode.ok) {
            if (createResult['result_code'] ==
                CallResultCode.userAlreadyExists) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Användaren finns redan")),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Error: ${createResult['result_code']}"),
                ),
              );
            }
            _scanned = false;
            setState(() {
              _isProcessing = false;
            });
            return;
          }
          encodedToken =
              createResult['token']?['encoded_token']?.toString() ?? "";
          validUntil = createResult['token']?['valid_until']?.toString() ?? "";
        }
        // Debug: print token to verify correctness
        debugPrint("Encoded token received: $encodedToken");
        Provider.of<UserSession>(
          context,
          listen: false,
        ).login(scannedId, name, encodedToken, validUntil);
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
          // appBar: const CommonAppBar(title: 'Scanna ditt band'),
          body: Column(
            children: [
              Expanded(
                child: DataMatrixScanner(
                  onCodeScanned: _onGetResult,
                  sheetTitle: "Scanna QR-koden på ditt band för att logga in",
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
