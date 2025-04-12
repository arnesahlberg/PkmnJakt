import 'package:flutter/material.dart';

Future<Map<String, String>?> promptForUserCredentials(
  BuildContext context,
  String scannedId,
) async {
  return showDialog<Map<String, String>>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return NewUserPrompt(scannedId: scannedId);
    },
  );
}

class NewUserPrompt extends StatefulWidget {
  const NewUserPrompt({Key? key, required this.scannedId}) : super(key: key);
  final String scannedId;

  @override
  _NewUserPromptState createState() => _NewUserPromptState();
}

class _NewUserPromptState extends State<NewUserPrompt> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  String? errorMessage;

  void _submit() {
    if (_usernameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmController.text.isEmpty) {
      setState(() {
        errorMessage = "Alla fält måste fyllas i";
      });
      return;
    }
    if (_usernameController.text.length < 2) {
      setState(() {
        errorMessage = "Användarnamn måste vara minst 2 tecken";
      });
      return;
    }
    if (_passwordController.text.length < 4) {
      setState(() {
        errorMessage = "Lösenordet måste vara minst 4 tecken";
      });
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      setState(() {
        errorMessage = "Lösenorden matchar inte";
      });
      return;
    }
    Navigator.of(context).pop({
      'username': _usernameController.text,
      'password': _passwordController.text,
      'confirm': _confirmController.text,
    });
  }

  InputDecoration _getInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade700),
      hintStyle: TextStyle(color: Colors.grey.shade500),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE3350D), width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade700, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF992109), width: 2),
      ),
      title: const Text(
        "Skapa användare",
        style: TextStyle(
          color: Colors.black87,
          fontFamily: 'PixelFontTitle',
          fontSize: 20,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Band scannat för första gången. Skapa ny användare.',
            style: TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _usernameController,
            style: const TextStyle(color: Colors.black87),
            decoration: _getInputDecoration("Användarnamn"),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            style: const TextStyle(color: Colors.black87),
            decoration: _getInputDecoration("Lösenord"),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmController,
            style: const TextStyle(color: Colors.black87),
            decoration: _getInputDecoration("Bekräfta lösenord"),
            obscureText: true,
          ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF992109)),
          child: const Text("Avbryt"),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE3350D),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFF992109), width: 2),
            ),
          ),
          child: const Text("Skapa"),
        ),
      ],
    );
  }
}
