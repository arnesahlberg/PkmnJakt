import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../api_calls.dart';
import '../screens/welcome_screen.dart';

class AuthChecker extends StatelessWidget {
  final Widget child;
  const AuthChecker({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<UserSession>(context);
    if (session.token == null) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      });
      return Container();
    }
    return FutureBuilder<bool>(
      future: ApiService.validateToken(session.token!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data != true) {
          session.logout();
          Future.microtask(() {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            );
          });
          return Container();
        }
        return child;
      },
    );
  }
}
