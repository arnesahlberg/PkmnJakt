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

  void _resetPassword() async {
    if (_newPasswordController.text.isEmpty ||
        _confirmController.text.isEmpty) {
      setState(() {
        _errorMessage = "Alla fält måste fyllas i";
      });
      return;
    }
    if (_newPasswordController.text != _confirmController.text) {
      setState(() {
        _errorMessage = "Lösenorden matchar inte";
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
      _newPasswordController.text,
      token,
    );
    setState(() {
      _isProcessing = false;
    });
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response
              ? 'Lösenord återställt'
              : 'Misslyckades att återställa lösenord',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Återställ lösenord"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Avbryt"),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _resetPassword,
          child:
              _isProcessing
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text("Återställ lösenord"),
        ),
      ],
    );
  }
}
