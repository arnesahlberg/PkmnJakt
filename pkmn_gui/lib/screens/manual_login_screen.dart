import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // for UserSession
import '../api_calls.dart';
import '../constants.dart';
import '../utils/name_suggestions.dart';
import '../widgets/common_app_bar.dart';

class ManualLoginScreen extends StatefulWidget {
  const ManualLoginScreen({super.key});
  @override
  State<ManualLoginScreen> createState() => _ManualLoginScreenState();
}

class _ManualLoginScreenState extends State<ManualLoginScreen> {
  bool _isSignUp = true;
  bool _isProcessing = false;

  final _userIdController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _errorMessage;

  @override
  void dispose() {
    _userIdController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  void _showSuggestionsDialog() {
    final suggestions = NameSuggestions.generateMultipleSuggestions(5);
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            contentPadding: EdgeInsets.zero,
            backgroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UIConstants.borderRadius12),
              side: AppBorderStyles.primaryBorder,
            ),
            title: null,
            actions: null,
            content: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Förslag på visningsnamn',
                        style: AppTextStyles.titleSmall,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Klicka på ett namn för att använda det',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                    for (final suggestion in suggestions)
                      ListTile(
                        title: Text(
                          suggestion,
                          style: AppTextStyles.bodyMedium,
                        ),
                        onTap: () {
                          setState(() {
                            _displayNameController.text = suggestion;
                            _clearError();
                          });
                          Navigator.of(ctx).pop();
                        },
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.secondaryRed,
                            ),
                            child: const Text('Stäng'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showSuggestionsDialog();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryRed,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.refresh, size: 16),
                                SizedBox(width: 4),
                                Text('Nya förslag'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    final userId = _userIdController.text.trim();
    final password = _passwordController.text;

    if (userId.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Användar-ID och lösenord måste fyllas i');
      return;
    }

    if (_isSignUp) {
      final displayName = _displayNameController.text.trim();
      final confirm = _confirmController.text;

      if (displayName.isEmpty) {
        setState(() => _errorMessage = 'Ange ett visningsnamn');
        return;
      }
      if (displayName.length < 2) {
        setState(
          () => _errorMessage = 'Visningsnamnet måste vara minst 2 tecken',
        );
        return;
      }
      if (password.length < 4) {
        setState(() => _errorMessage = 'Lösenordet måste vara minst 4 tecken');
        return;
      }
      if (password != confirm) {
        setState(() => _errorMessage = 'Lösenorden matchar inte');
        return;
      }

      setState(() => _isProcessing = true);
      try {
        final exists = await ApiService.checkUserExists(userId);
        if (!mounted) return;
        if (exists) {
          setState(
            () => _errorMessage = 'Användar-ID är redan taget, välj ett annat',
          );
          return;
        }
        final result = await ApiService.createUser(
          userId,
          displayName,
          password,
        );
        if (!mounted) return;
        if (result['result_code'] != CallResultCode.ok) {
          setState(
            () =>
                _errorMessage =
                    result['result_code'] == CallResultCode.userAlreadyExists
                        ? 'Användaren finns redan'
                        : 'Något gick fel. Felkod: ${result['result_code']}',
          );
          return;
        }
        final encodedToken =
            result['token']?['encoded_token']?.toString() ?? '';
        final validUntil = result['token']?['valid_until']?.toString() ?? '';
        Provider.of<UserSession>(
          context,
          listen: false,
        ).login(userId, displayName, encodedToken, validUntil);
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        setState(() => _errorMessage = 'Fel: $e');
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    } else {
      // Login mode
      setState(() => _isProcessing = true);
      try {
        final exists = await ApiService.checkUserExists(userId);
        if (!mounted) return;
        if (!exists) {
          setState(
            () =>
                _errorMessage =
                    'Ingen användare med det Användar-ID:t hittades',
          );
          return;
        }
        final result = await ApiService.login(userId, password);
        if (!mounted) return;
        if (result['result_code'] != CallResultCode.ok) {
          setState(
            () =>
                _errorMessage =
                    result['result_code'] == CallResultCode.invalidPassword
                        ? 'Fel lösenord, försök igen'
                        : 'Något gick fel. Felkod: ${result['result_code']}',
          );
          return;
        }
        final name = result['name'] ?? userId;
        final encodedToken =
            result['token']?['encoded_token']?.toString() ?? '';
        final validUntil = result['token']?['valid_until']?.toString() ?? '';
        Provider.of<UserSession>(
          context,
          listen: false,
        ).login(userId, name, encodedToken, validUntil);
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        setState(() => _errorMessage = 'Fel: $e');
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: _isSignUp ? 'Registrera' : 'Logga in'),
      body: Stack(
        children: [
          Container(
            decoration: AppBoxDecorations.gradientBackground,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // User ID
                    TextField(
                      controller: _userIdController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: AppInputDecorations.defaultInputDecoration(
                        'Användar-ID (unikt)',
                      ),
                      onChanged: (_) => _clearError(),
                      autocorrect: false,
                      enableSuggestions: false,
                    ),
                    const SizedBox(height: 16),

                    // Display name (sign-up only)
                    if (_isSignUp) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _displayNameController,
                              style: const TextStyle(color: Colors.black87),
                              decoration:
                                  AppInputDecorations.defaultInputDecoration(
                                    'Visningsnamn',
                                  ),
                              onChanged: (_) => _clearError(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _showSuggestionsDialog,
                            icon: const Icon(Icons.auto_awesome),
                            tooltip: 'Föreslå visningsnamn',
                            color: AppColors.primaryRed,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.black87),
                      decoration: AppInputDecorations.defaultInputDecoration(
                        'Lösenord',
                      ),
                      onChanged: (_) => _clearError(),
                    ),
                    const SizedBox(height: 16),

                    // Confirm password (sign-up only)
                    if (_isSignUp) ...[
                      TextField(
                        controller: _confirmController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.black87),
                        decoration: AppInputDecorations.defaultInputDecoration(
                          'Bekräfta lösenord',
                        ),
                        onChanged: (_) => _clearError(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Inline error
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Submit
                    ElevatedButton(
                      style: AppButtonStyles.buttonStyleWide,
                      onPressed: _isProcessing ? null : _submit,
                      child: Text(_isSignUp ? 'Skapa konto' : 'Logga in'),
                    ),
                    const SizedBox(height: 24),

                    // Mode toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isSignUp
                              ? 'Har du redan ett konto?'
                              : 'Inget konto ännu?',
                          style: AppTextStyles.bodyMedium,
                        ),
                        TextButton(
                          onPressed:
                              () => setState(() {
                                _isSignUp = !_isSignUp;
                                _errorMessage = null;
                              }),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryRed,
                          ),
                          child: Text(
                            _isSignUp ? 'Logga in' : 'Registrera dig',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
