import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_calls.dart';
import '../constants.dart';
import '../main.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/pokedex_button.dart';
import '../widgets/pokedex_container.dart';

class BackendUnavailableScreen extends StatefulWidget {
  const BackendUnavailableScreen({super.key});

  @override
  State<BackendUnavailableScreen> createState() =>
      _BackendUnavailableScreenState();
}

class _BackendUnavailableScreenState extends State<BackendUnavailableScreen> {
  bool _isRetrying = false;
  String? _retryMessage;

  Future<void> _retry() async {
    setState(() {
      _isRetrying = true;
      _retryMessage = null;
    });

    final session = Provider.of<UserSession>(context, listen: false);

    try {
      if (session.token != null && !session.isExpored()) {
        final isValid = await ApiService.validateToken(session.token!);
        if (!mounted) return;
        if (isValid) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
          return;
        }
        session.logout();
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
        return;
      }

      if (session.token != null && session.isExpored()) {
        session.logout();
      }

      await ApiService.getDatamatrixLoginEnabled(fallbackOnError: false);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _retryMessage = 'Servern svarar fortfarande inte. Försök igen strax.';
      });
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<UserSession>(context);

    return Scaffold(
      appBar: const CommonAppBar(title: 'Ingen kontakt', showBackButton: false),
      body: Container(
        decoration: AppBoxDecorations.gradientBackground,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(UIConstants.padding16),
            child: PokedexContainer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off,
                    size: UIConstants.iconSizeHuge,
                    color: AppColors.primaryRed,
                  ),
                  const SizedBox(height: UIConstants.spacing16),
                  const Text(
                    'Servern nås inte just nu',
                    style: AppTextStyles.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: UIConstants.spacing16),
                  Text(
                    session.isLoggedIn
                        ? 'Du är fortfarande inloggad. Kontrollera täckningen och försök igen.'
                        : 'Kontrollera täckningen och försök igen.',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_retryMessage != null) ...[
                    const SizedBox(height: UIConstants.spacing16),
                    Text(
                      _retryMessage!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.secondaryRed,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: UIConstants.spacing24),
                  PokedexButton(
                    onPressed: _isRetrying ? () {} : _retry,
                    child:
                        _isRetrying
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white,
                                ),
                              ),
                            )
                            : const Text('Försök igen'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
