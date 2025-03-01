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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Skapa användare"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: "Användarnamn"),
          ),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: "Lösenord"),
            obscureText: true,
          ),
          TextField(
            controller: _confirmController,
            decoration: const InputDecoration(labelText: "Bekräfta lösenord"),
            obscureText: true,
          ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: _submit, child: const Text("Skapa")),
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Avbryt"),
        ),
      ],
    );
  }
}
