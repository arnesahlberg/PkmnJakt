import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_calls.dart';
import '../main.dart';

class DeleteUserDialog extends StatefulWidget {
  final String userId;
  final VoidCallback? onDeleted; // new
  const DeleteUserDialog({Key? key, required this.userId, this.onDeleted})
    : super(key: key);

  @override
  _DeleteUserDialogState createState() => _DeleteUserDialogState();
}

class _DeleteUserDialogState extends State<DeleteUserDialog> {
  final TextEditingController _confirmController1 = TextEditingController();
  final TextEditingController _confirmController2 = TextEditingController();
  bool _confirmChecked = false;
  String? _errorMessage;
  bool _isProcessing = false;

  void _deleteUser() async {
    if (_confirmController1.text != widget.userId ||
        _confirmController2.text != widget.userId) {
      setState(() {
        _errorMessage = "User ID måste matcha exakt!";
      });
      return;
    }
    if (!_confirmChecked) {
      setState(() {
        _errorMessage = "Du måste bekräfta att du förstår konsekvenserna.";
      });
      return;
    }
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    final token = Provider.of<UserSession>(context, listen: false).token;
    if (token == null) return;
    final success = await AdminApiService.deleteUser(widget.userId, token);
    setState(() {
      _isProcessing = false;
    });
    Navigator.of(context).pop();
    if (success && widget.onDeleted != null) {
      widget.onDeleted!(); // refresh list callback
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Användare raderad' : 'Radering misslyckades'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bekräfta radering'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sluta med de här dumheterna! Det här går inte att ångra!',
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmController1,
              decoration: const InputDecoration(labelText: 'Ange användar id'),
            ),
            TextField(
              controller: _confirmController2,
              decoration: const InputDecoration(
                labelText: 'Ange användar id igen',
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: _confirmChecked,
                  onChanged: (value) {
                    setState(() {
                      _confirmChecked = value ?? false;
                    });
                  },
                ),
                const Expanded(
                  child: Text('Jag förstår att detta inte går att ångra'),
                ),
              ],
            ),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Avbryt'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _deleteUser,
          child:
              _isProcessing
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Radera användare'),
        ),
      ],
    );
  }
}
