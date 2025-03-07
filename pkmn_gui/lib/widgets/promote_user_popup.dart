import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_calls.dart';
import '../main.dart';

class PromoteUserDialog extends StatefulWidget {
  final String userId;
  // Om true visas en vanlig bekräftelse. Om false krävs manuellt inmatad id.
  final bool isMainAdmin;
  const PromoteUserDialog({
    super.key,
    required this.userId,
    required this.isMainAdmin,
  });

  @override
  _PromoteUserDialogState createState() => _PromoteUserDialogState();
}

class _PromoteUserDialogState extends State<PromoteUserDialog> {
  final TextEditingController _confirmController = TextEditingController();
  String? _errorMessage;
  bool _isProcessing = false;

  void _promoteUser() async {
    // Om inte huvud-admin, verifiera att inmatat värde stämmer med userId.
    if (!widget.isMainAdmin &&
        _confirmController.text.trim() != widget.userId) {
      setState(() {
        _errorMessage = "Användar-id matchar inte!";
      });
      return;
    }
    // Bekräfta befordran via API
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    final token = Provider.of<UserSession>(context, listen: false).token;
    if (token == null) return;
    final success = await AdminApiService.makeUserAdmin(widget.userId, token);
    setState(() {
      _isProcessing = false;
    });
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Användare ${widget.userId} befordrad till admin'
              : 'Befordran misslyckades',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bekräfta befordran'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Vill du verkligen göra ${widget.userId} till administratör?\nDu kan inte ångra detta.',
          ),
          if (!widget.isMainAdmin) ...[
            const SizedBox(height: 10),
            const Text('Ange användar-id för att bekräfta:'),
            TextField(
              controller: _confirmController,
              decoration: const InputDecoration(labelText: 'Användar-id'),
            ),
          ],
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
          child: const Text('Avbryt'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _promoteUser,
          child:
              _isProcessing
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Bekräfta'),
        ),
      ],
    );
  }
}
