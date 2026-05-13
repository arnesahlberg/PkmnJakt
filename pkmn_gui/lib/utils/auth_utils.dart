import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_calls.dart';
import '../main.dart';

class AuthUtils {
  /// Validates user token and redirects to welcome screen if invalid
  /// Returns true if token is valid, false otherwise
  static Future<bool> validateTokenAndRedirect(BuildContext context) async {
    // Capture providers and navigator synchronously.
    final session = Provider.of<UserSession>(context, listen: false);
    final navigator = Navigator.of(context);

    if (session.token == null) {
      session.logout();
      // Use the captured navigator, avoiding BuildContext after async gap.
      Future.microtask(() {
        navigator.pushNamedAndRemoveUntil('/', (route) => false);
      });
      return false;
    }

    if (session.isExpored()) {
      session.logout();
      Future.microtask(() {
        navigator.pushNamedAndRemoveUntil('/', (route) => false);
      });
      return false;
    }

    try {
      final token = session.token;
      final isValid = await ApiService.validateToken(token!);
      if (!isValid) {
        session.logout();
        Future.microtask(() {
          navigator.pushNamedAndRemoveUntil('/', (route) => false);
        });
        return false;
      }
      return true;
    } catch (e) {
      if (isBackendUnavailableError(e)) {
        Future.microtask(() {
          navigator.pushNamedAndRemoveUntil(
            '/backend_unavailable',
            (route) => false,
          );
        });
        return false;
      }

      session.logout();
      Future.microtask(() {
        navigator.pushNamedAndRemoveUntil('/', (route) => false);
      });
      return false;
    }
  }

  /// Logs out and redirects user to welcome screen
  static void redirectToWelcome(BuildContext context) {
    final session = Provider.of<UserSession>(context, listen: false);
    session.logout();

    final navigator = Navigator.of(context);
    Future.delayed(Duration.zero, () {
      navigator.pushNamedAndRemoveUntil('/', (route) => false);
    });
  }
}
