import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_calls.dart';
import '../main.dart';
import '../constants.dart';

class DeleteUserDialog extends StatefulWidget {
  final String userId;
  final VoidCallback? onDeleted; // new
  const DeleteUserDialog({Key? key, required this.userId, this.onDeleted})
    : super(key: key);

  @override
  _DeleteUserDialogState createState() => _DeleteUserDialogState();
}

class _DeleteUserDialogState extends State<DeleteUserDialog> {
  final TextEditingController _confirmController = TextEditingController();
  final TextEditingController _confirmController2 = TextEditingController();
  bool _confirmChecked = false;
  String? _errorMessage;
  bool _isProcessing = false;

  void _deleteUser() async {
    if (_confirmController.text != widget.userId ||
        _confirmController2.text != widget.userId) {
      setState(() {
        _errorMessage = "Båda fälten måste matcha användar-ID:et exakt!";
      });
      return;
    }

    if (!_confirmChecked) {
      setState(() {
        _errorMessage =
            "Du måste bekräfta att du förstår att detta inte kan ångras!";
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
    Navigator.of(context).pop(success);
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
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.borderRadius12),
        side: const BorderSide(
          color: Colors.red,
          width: UIConstants.borderWidth2,
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bekräfta radering',
            style: AppTextStyles.titleMedium.copyWith(color: Colors.red),
          ),
          Text(
            'Sluta! Det här går inte att ångra!',
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'För att ta bort användaren, skriv in användar-ID:et två gånger:',
              style: TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              decoration: InputDecoration(
                labelText: 'Användar-ID första gången',
                labelStyle: TextStyle(color: Colors.grey.shade700),
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: AppColors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    UIConstants.borderRadius8,
                  ),
                  borderSide: BorderSide(
                    color: Colors.red.shade200,
                    width: UIConstants.borderWidth1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    UIConstants.borderRadius8,
                  ),
                  borderSide: BorderSide(
                    color: Colors.red,
                    width: UIConstants.borderWidth2,
                  ),
                ),
              ),
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController2,
              decoration: const InputDecoration(
                labelText: 'Användar-ID andra gången',
                labelStyle: TextStyle(color: Colors.black87),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
              ),
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _confirmChecked,
                  onChanged: (value) {
                    setState(() {
                      _confirmChecked = value ?? false;
                    });
                  },
                  activeColor: Colors.red,
                  checkColor: Colors.white,
                  fillColor: MaterialStateProperty.resolveWith<Color>((
                    Set<MaterialState> states,
                  ) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.red;
                    }
                    return Colors
                        .grey
                        .shade300; // Light grey background when unchecked
                  }),
                  side: BorderSide(color: Colors.red.shade700, width: 1.5),
                ),
                const Expanded(
                  child: Text(
                    'Jag förstår att detta INTE kan ångras och att all användardata kommer att försvinna permanent.',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
          child: const Text(
            'Avbryt',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _deleteUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child:
              _isProcessing
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text(
                    'Ta bort användare',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
        ),
      ],
    );
  }
}
