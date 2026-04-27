import 'package:flutter/material.dart';
import 'package:pkmn_gui/api_calls.dart';
import 'package:pkmn_gui/constants.dart';

class ResetGamePopup extends StatefulWidget {
  final String token;
  final VoidCallback? onReset;

  const ResetGamePopup({super.key, required this.token, this.onReset});

  @override
  State<ResetGamePopup> createState() => _ResetGamePopupState();
}

class _ResetGamePopupState extends State<ResetGamePopup> {
  int _step = 1;
  final TextEditingController _confirmController = TextEditingController();
  bool _check1 = false;
  bool _check2 = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  bool get _step1Valid =>
      _confirmController.text.trim().toLowerCase() == 'reset';

  bool get _step2Valid => _check1 && _check2;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _step == 1 ? 'Återställ speldata (1/2)' : 'Återställ speldata (2/2)',
      ),
      content: _step == 1 ? _buildStep1() : _buildStep2(),
      actions: _step == 1 ? _step1Actions() : _step2Actions(),
    );
  }

  Widget _buildStep1() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detta raderar alla fångade Pokémon för alla användare. '
          'Milstolpar återställs automatiskt.',
        ),
        const SizedBox(height: 16),
        const Text('Skriv "RESET" för att fortsätta:'),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'RESET',
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sista chansen. Bekräfta att du förstår konsekvenserna:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _check1,
          onChanged: (v) => setState(() => _check1 = v ?? false),
          title: const Text('Ja, jag vill verkligen radera allt'),
          activeColor: AppColors.primaryRed,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: _check2,
          onChanged: (v) => setState(() => _check2 = v ?? false),
          title: const Text('Ja, jag förstår att detta inte kan återställas'),
          activeColor: AppColors.primaryRed,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  List<Widget> _step1Actions() {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Avbryt'),
      ),
      ElevatedButton(
        onPressed: _step1Valid ? () => setState(() => _step = 2) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: const Text('Nästa', style: TextStyle(color: Colors.white)),
      ),
    ];
  }

  List<Widget> _step2Actions() {
    return [
      TextButton(
        onPressed: _isLoading ? null : () => Navigator.pop(context),
        child: const Text('Avbryt'),
      ),
      ElevatedButton(
        onPressed: (_step2Valid && !_isLoading) ? _doReset : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child:
            _isLoading
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : const Text(
                  'Återställ spelet',
                  style: TextStyle(color: Colors.white),
                ),
      ),
    ];
  }

  Future<void> _doReset() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final success = await AdminApiService.resetGameData(widget.token);
      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
        widget.onReset?.call();
      } else {
        setState(() {
          _errorMessage = 'Återställningen misslyckades. Försök igen.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Fel: $e';
        _isLoading = false;
      });
    }
  }
}
