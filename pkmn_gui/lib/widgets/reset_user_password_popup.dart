import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_calls.dart';
import '../main.dart';

class ResetUserPasswordDialog extends StatefulWidget {
  final String userId;
  const ResetUserPasswordDialog({Key? key, required this.userId})
    : super(key: key);

  @override
  _ResetUserPasswordDialogState createState() =>
      _ResetUserPasswordDialogState();
}

class _ResetUserPasswordDialogState extends State<ResetUserPasswordDialog> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  String? _errorMessage;
  bool _isProcessing = false;
  String? _newPassword;

  void _resetPassword() async {
    if (_confirmController.text.isEmpty) {
      setState(() {
        _errorMessage = "Användar-id måste fyllas i";
      });
      return;
    }
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    final token = Provider.of<UserSession>(context, listen: false).token;
    if (token == null) return;
    final response = await AdminApiService.resetUserPassword(
      widget.userId,
      _confirmController.text,
      token,
    );
    setState(() {
      _isProcessing = false;
      _newPassword = response ? _confirmController.text : null;
    });
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'För att återställa lösenordet, skriv in användar-id:et.',
            style: TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmController,
            decoration: InputDecoration(
              labelText: 'Användar-id',
              labelStyle: TextStyle(color: Colors.black87),
              border: OutlineInputBorder(),
            ),
            style: TextStyle(color: Colors.black87),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          if (_newPassword != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Column(
                children: [
                  Text(
                    'Nytt lösenord:',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SelectableText(
                    _newPassword!,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF992109)),
          child: const Text('Stäng'),
        ),
        if (_newPassword == null)
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Återställ lösenord'),
          ),
      ],
    );
  }
}
