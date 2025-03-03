import 'package:flutter/material.dart';
import '../api_calls.dart';

Future<Map<String, dynamic>?> changePasswordPopup(
  BuildContext context,
  String token,
) async {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) {
      return ChangePasswordPrompt(token: token);
    },
  );
}

class ChangePasswordPrompt extends StatefulWidget {
  const ChangePasswordPrompt({Key? key, required this.token}) : super(key: key);
  final String token;

  @override
  _ChangePasswordPromptState createState() => _ChangePasswordPromptState();
}

class _ChangePasswordPromptState extends State<ChangePasswordPrompt> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  String? errorMessage;
  bool isValidating = false;

  void _submit() async {
    setState(() {
      errorMessage = null;
      isValidating = true;
    });

    // Validate local fields
    if (_oldPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmController.text.isEmpty) {
      setState(() {
        errorMessage = "Alla fält måste fyllas i";
        isValidating = false;
      });
      return;
    }

    if (_newPasswordController.text.length < 4) {
      setState(() {
        errorMessage = "Lösenordet måste vara minst 4 tecken";
        isValidating = false;
      });
      return;
    }

    if (_newPasswordController.text != _confirmController.text) {
      setState(() {
        errorMessage = "Lösenorden matchar inte";
        isValidating = false;
      });
      return;
    }

    try {
      // validate old password
      final validationResponse = await ApiService.validatePassword(
        _oldPasswordController.text,
        widget.token,
      );
      if (validationResponse['valid'] != true) {
        setState(() {
          errorMessage = "Fel nuvarande lösenord";
          isValidating = false;
        });
        return;
      }

      // change password
      final changeResponse = await ApiService.setNewPassword(
        _oldPasswordController.text,
        _newPasswordController.text,
        widget.token,
      );

      Navigator.of(context).pop(changeResponse);
    } catch (e) {
      setState(() {
        errorMessage = "Kunde inte validera lösenord: $e";
        debugPrint("Error validating password: $e");
        isValidating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Byt lösenord"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _oldPasswordController,
            decoration: const InputDecoration(labelText: "Nuvarande lösenord"),
            obscureText: true,
          ),
          TextField(
            controller: _newPasswordController,
            decoration: const InputDecoration(labelText: "Nytt lösenord"),
            obscureText: true,
          ),
          TextField(
            controller: _confirmController,
            decoration: const InputDecoration(
              labelText: "Bekräfta nytt lösenord",
            ),
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
        TextButton(
          onPressed: isValidating ? null : () => Navigator.pop(context, null),
          child: const Text("Avbryt"),
        ),
        ElevatedButton(
          onPressed: isValidating ? null : _submit,
          child:
              isValidating
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text("Byt lösenord"),
        ),
      ],
    );
  }
}
