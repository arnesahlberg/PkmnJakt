import 'package:flutter/material.dart';
import 'package:pkmn_gui/constants.dart';
import 'package:provider/provider.dart';
import '../api_calls.dart';
import '../main.dart';

class ResetUserPasswordDialog extends StatefulWidget {
  const ResetUserPasswordDialog({super.key});

  @override
  ResetUserPasswordDialogState createState() => ResetUserPasswordDialogState();
}

class ResetUserPasswordDialogState extends State<ResetUserPasswordDialog> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _errorMessage;
  bool _isProcessing = false;
  bool _success = false;

  void _resetPassword() async {
    // Reset any previous error messages
    setState(() {
      _errorMessage = null;
    });

    // Validate inputs
    final userId = _userIdController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (userId.isEmpty) {
      setState(() {
        _errorMessage = "Användar-id måste anges";
      });
      return;
    }

    if (newPassword.isEmpty) {
      setState(() {
        _errorMessage = "Nytt lösenord måste anges";
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _errorMessage = "Lösenorden matchar inte";
      });
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Get the token for authorization
    final token = Provider.of<UserSession>(context, listen: false).token;
    if (token == null) {
      setState(() {
        _isProcessing = false;
        _errorMessage = "Du är inte inloggad";
      });
      return;
    }

    try {
      final response = await AdminApiService.resetUserPassword(
        userId,
        newPassword,
        token,
      );

      setState(() {
        _isProcessing = false;
        if (response) {
          _success = true;
        } else {
          _errorMessage = "Felaktigt användar-id eller användaren finns inte.";
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = "Ett fel uppstod: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF992109), width: 2),
      ),
      title: const Text(
        'Återställ lösenord',
        style: TextStyle(
          color: Colors.black87,
          fontFamily: 'PixelFontTitle',
          fontSize: 20,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_success) ...[
              const Text(
                'Ange användar-id och nytt lösenord för att återställa lösenordet.',
                style: TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _userIdController,
                decoration: const InputDecoration(
                  labelText: 'Användar-id',
                  labelStyle: TextStyle(color: Colors.black87),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nytt lösenord',
                  labelStyle: TextStyle(color: Colors.black87),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Bekräfta nytt lösenord',
                  labelStyle: TextStyle(color: Colors.black87),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.black87),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 0, 0, 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ] else ...[
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Lösenordet har återställts!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Användar-id: ${_userIdController.text}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_success) ...[
          TextButton(
            onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
            child: const Text('Avbryt', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _isProcessing ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE3350D),
              foregroundColor: Colors.white,
            ),
            child:
                _isProcessing
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                    : const Text(
                      'Återställ lösenord',
                      style: TextStyle(color: Colors.white),
                    ),
          ),
        ] else ...[
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF992109),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Stäng'),
          ),
        ],
      ],
    );
  }
}
