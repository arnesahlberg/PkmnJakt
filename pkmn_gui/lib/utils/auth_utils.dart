import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_calls.dart';
import '../main.dart';

class AuthUtils {
  /// Validates user token and redirects to welcome screen if invalid
  /// Returns true if token is valid, false otherwise
  static Future<bool> validateTokenAndRedirect(BuildContext context) async {
    final session = Provider.of<UserSession>(context, listen: false);
    if (session.token == null) {
      redirectToWelcome(context);
      return false;
    }

    try {
      final isValid = await ApiService.validateToken(session.token!);
      if (!isValid || session.isExpored()) {
        redirectToWelcome(context);
        return false;
      }
      return true;
    } catch (e) {
      redirectToWelcome(context);
      return false;
    }
  }

  /// Logs out and redirects user to welcome screen
  static void redirectToWelcome(BuildContext context) {
    final session = Provider.of<UserSession>(context, listen: false);
    session.logout();

    Future.delayed(Duration.zero, () {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    });
  }
}
