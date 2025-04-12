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
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF992109), width: 2),
      ),
      title: const Text(
        'Ge administratörsrättigheter',
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
            'För att ge administratörsrättigheter, skriv in användar-id:et.',
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF992109)),
          child: const Text('Avbryt'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _promoteUser,
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
                  : const Text('Ge administratörsrättigheter'),
        ),
      ],
    );
  }
}
