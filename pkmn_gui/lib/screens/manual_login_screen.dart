import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // for UserSession
import '../api_calls.dart';
import '../constants.dart';
import '../widgets/login_popup.dart'; // for promptForPassword
import '../widgets/new_user_prompt.dart'; // for promptForUserCredentials
import '../widgets/common_app_bar.dart';

class ManualLoginScreen extends StatefulWidget {
  const ManualLoginScreen({super.key});
  @override
  State<ManualLoginScreen> createState() => _ManualLoginScreenState();
}

class _ManualLoginScreenState extends State<ManualLoginScreen> {
  final TextEditingController _idController = TextEditingController();
  bool _isProcessing = false;

  Future<void> _submitId() async {
    final idCode = _idController.text.trim();
    if (idCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ange ID numret fårn ditt deltagarband")),
      );
      return;
    }
    // Basic validation: if code is too long, it might be invalid.
    if (idCode.length > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Det angivna numret verkar felaktig")),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Check if the user exists
      final exists = await ApiService.checkUserExists(idCode);
      String name;
      String encodedToken;
      String validUntil;

      if (exists) {
        // Existing user: prompt for password
        if (!mounted) return;
        final password = await promptForPassword(context);
        if (password == null || password.isEmpty) {
          setState(() {
            _isProcessing = false;
          });
          return;
        }
        final loginResult = await ApiService.login(idCode, password);
        if (loginResult['result_code'] != CallResultCode.ok) {
          final errorMsg =
              (loginResult['result_code'] == CallResultCode.invalidPassword)
                  ? "Fel lösenord, försök igen"
                  : "Något gick fel. Felkod: ${loginResult['result_code']}";
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMsg)));
          setState(() {
            _isProcessing = false;
          });
          return;
        }
        name = loginResult['name'] ?? "Error fetching name";
        encodedToken = loginResult['token']?['encoded_token'].toString() ?? "";
        validUntil = loginResult['token']?['valid_until']?.toString() ?? "";
      } else {
        // New user: prompt for credentials
        if (!mounted) return;
        final credentials = await promptForUserCredentials(context, idCode);
        if (credentials == null ||
            credentials['username']?.isEmpty == true ||
            credentials['password']?.isEmpty == true ||
            credentials['confirm']?.isEmpty == true) {
          setState(() {
            _isProcessing = false;
          });
          return;
        }
        if (credentials['password'] != credentials['confirm']) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Lösenorden matchar inte")),
          );
          setState(() {
            _isProcessing = false;
          });
          return;
        }
        name = credentials['username'] ?? "Could not fetch name";
        final password = credentials['password'] ?? "";
        final createResult = await ApiService.createUser(
          idCode,
          name,
          password,
        );
        if (createResult['result_code'] != CallResultCode.ok) {
          final errorMsg =
              (createResult['result_code'] == CallResultCode.userAlreadyExists)
                  ? "Användaren finns redan"
                  : "Error: ${createResult['result_code']}";
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMsg)));
          setState(() {
            _isProcessing = false;
          });
          return;
        }
        encodedToken =
            createResult['token']?['encoded_token']?.toString() ?? "";
        validUntil = createResult['token']?['valid_until']?.toString() ?? "";
      }
      if (!mounted) return;
      Provider.of<UserSession>(
        context,
        listen: false,
      ).login(idCode, name, encodedToken, validUntil);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: 'Manuell inloggning'),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _idController,
                  decoration: AppInputDecorations.defaultInputDecoration(
                    'Ange numret från ditt deltagarband',
                  ),
                  style: AppTextStyles.bodyLarge,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: AppButtonStyles.buttonStyleWide,
                  onPressed: _isProcessing ? null : _submitId,
                  child: const Text("Skicka"),
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
      ),
    );
  }
}
