import 'package:flutter/material.dart';
import 'package:pkmn_gui/screens/welcome_screen.dart';
import 'package:provider/provider.dart';
import '../widgets/common_app_bar.dart';
import '../main.dart';
import '../api_calls.dart';
import '../widgets/change_user_name_popup.dart';
import '../widgets/change_password_popup.dart';
import '../constants.dart';

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
              "Inloggad som: ${session.userName} (${session.userId})",
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final newName = await changeUserNamePopup(context);
                if (newName != null) {
                  final result = await ApiService.setUserName(
                    newName,
                    session.token!,
                  );
                  final int resultCode = result['result_code'];
                  if (resultCode == CallResultCode.ok) {
                    session.setUserName(newName);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Användarnamn ändrat")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Kunde inte ändra användarnamn"),
                      ),
                    );
                  }
                }
              },
              child: const Text("Ändra användarnamn"),
            ),
            // space between buttons
            const SizedBox(height: 20),
            // to change password
            ElevatedButton(
              onPressed: () async {
                final result = await changePasswordPopup(
                  context,
                  session.token!,
                );
                if (result != null) {
                  final resultCode = result['result_code'];
                  if (resultCode == CallResultCode.ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Lösenord ändrat")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Kunde inte ändra lösenord"),
                      ),
                    );
                  }
                }
              },
              child: const Text("Byt lösenord"),
            ),
            // space between buttons
            const SizedBox(height: 20),

            // to log out
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
