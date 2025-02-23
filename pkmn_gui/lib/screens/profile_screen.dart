import 'package:flutter/material.dart';
import 'package:pkmn_gui/screens/welcome_screen.dart';
import 'package:provider/provider.dart';
import '../widgets/common_app_bar.dart';
import '../main.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final session = Provider.of<UserSession>(context);
    return Scaffold(
      appBar: const CommonAppBar(title: 'Min Profil'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Inloggad som: ${session.userName}",
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                session.logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text("Logga ut"),
            ),
          ],
        ),
      ),
    );
  }
}
