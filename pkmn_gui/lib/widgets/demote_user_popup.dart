import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_calls.dart';
import '../main.dart';

class DemoteUserDialog extends StatefulWidget {
  final String userId;
  final VoidCallback? onUserUpdated;
  const DemoteUserDialog({super.key, required this.userId, this.onUserUpdated});

  @override
  _DemoteUserDialogState createState() => _DemoteUserDialogState();
}

class _DemoteUserDialogState extends State<DemoteUserDialog> {
  final TextEditingController _confirmController = TextEditingController();
  String? _errorMessage;
  bool _isProcessing = false;

  void _demoteUser() async {
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
    final success = await AdminApiService.removeUserAdmin(widget.userId, token);
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
              ? 'Användare ${widget.userId} gjord till icke administratör'
              : 'Återkallande av admin-status misslyckades',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bekräfta demotering'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Vill du verkligen göra ${widget.userId} till icke administratör?\nAnge användar-id för att bekräfta:',
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
          onPressed: _isProcessing ? null : _demoteUser,
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
