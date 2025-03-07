import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_calls.dart';
import '../main.dart';

class PromoteUserDialog extends StatefulWidget {
  final String userId;
  final bool isMainAdmin;
  final VoidCallback? onUserUpdated;
  const PromoteUserDialog({
    super.key,
    required this.userId,
    required this.isMainAdmin,
    this.onUserUpdated,
  });

  @override
  _PromoteUserDialogState createState() => _PromoteUserDialogState();
}

class _PromoteUserDialogState extends State<PromoteUserDialog> {
  final TextEditingController _confirmController = TextEditingController();
  String? _errorMessage;
  bool _isProcessing = false;

  void _promoteUser() async {
    if (_confirmController.text.trim() != widget.userId) {
      setState(() {
        _errorMessage = "Användar-id matchar inte!";
      });
      return;
    }
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
    if (success) {
      widget.onUserUpdated?.call();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Användare ${widget.userId} befordrad till administratör'
              : 'Befordran misslyckades',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bekräfta administratör'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Vill du verkligen göra ${widget.userId} till administratör?\nAnge användar-id för att bekräfta:',
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _confirmController,
            decoration: const InputDecoration(labelText: 'Användar-id'),
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
