import 'package:flutter/material.dart';
import '../constants.dart';
import '../utils/name_suggestions.dart';

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
  const NewUserPrompt({super.key, required this.scannedId});
  final String scannedId;

  @override
  NewUserPromptState createState() => NewUserPromptState();
}

class NewUserPromptState extends State<NewUserPrompt> {
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

  // Show a dialog with multiple username suggestions
  void _showSuggestionsDialog() {
    _displaySuggestions();
  }

  void _displaySuggestions() {
    final suggestions = NameSuggestions.generateMultipleSuggestions(5);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Förslag på användarnamn',
              style: AppTextStyles.titleSmall,
            ),
            backgroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UIConstants.borderRadius12),
              side: AppBorderStyles.primaryBorder,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Klicka på ett namn för att använda det',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                for (final suggestion in suggestions)
                  ListTile(
                    title: Text(suggestion, style: AppTextStyles.bodyMedium),
                    onTap: () {
                      setState(() {
                        _usernameController.text = suggestion;
                        if (errorMessage ==
                                "Användarnamn måste vara minst 2 tecken" ||
                            errorMessage == "Alla fält måste fyllas i") {
                          errorMessage = null;
                        }
                      });
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondaryRed,
                ),
                child: const Text('Stäng'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _displaySuggestions(); // Show new suggestions
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryRed,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.refresh, size: 16),
                    SizedBox(width: 4),
                    Text('Nya förslag'),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  InputDecoration _getInputDecoration(String label) {
    return AppInputDecorations.defaultInputDecoration(label);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.borderRadius12),
        side: AppBorderStyles.primaryBorder,
      ),
      title: const Text("Skapa användare", style: AppTextStyles.titleMedium),
      // used column here before, but it caused error text to disappear behind button
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Band scannat för första gången. Skapa ny användare.',
              style: TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: _getInputDecoration("Användarnamn"),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _showSuggestionsDialog,
                  icon: const Icon(Icons.auto_awesome),
                  tooltip: 'Föreslå användarnamn',
                  color: AppColors.primaryRed,
                ),
              ],
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          style: TextButton.styleFrom(foregroundColor: AppColors.secondaryRed),
          child: const Text("Avbryt"),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: AppButtonStyles.primaryButtonStyle,
          child: const Text("Skapa", style: AppTextStyles.buttonText),
        ),
      ],
    );
  }
}
