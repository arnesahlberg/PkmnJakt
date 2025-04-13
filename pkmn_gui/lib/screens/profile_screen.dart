import 'package:flutter/material.dart';
import 'package:pkmn_gui/screens/welcome_screen.dart';
import 'package:provider/provider.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/pokedex_container.dart';
import '../widgets/pokedex_button.dart';
import '../main.dart';
import '../api_calls.dart';
import '../utils/auth_utils.dart';
import '../widgets/change_user_name_popup.dart';
import '../widgets/change_password_popup.dart';
import '../constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    AuthUtils.validateTokenAndRedirect(context).then((isValid) {
      if (isValid && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<UserSession>(context);

    return Scaffold(
      appBar: const CommonAppBar(title: 'Min Profil'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFFFAF6F6), Colors.red.shade50],
          ),
        ),
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFE3350D),
                    ),
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      PokedexContainer(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.account_circle,
                              size: 80,
                              color: Color(0xFFE3350D),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              session.userName ?? '',
                              style: const TextStyle(
                                fontFamily: 'PixelFontTitle',
                                fontSize: 24,
                                color: Color(0xFFE3350D),
                              ),
                            ),
                            Text(
                              "Tränare ID: ${session.userId}",
                              style: const TextStyle(
                                fontFamily: 'PixelFont',
                                fontSize: 16,
                                color: Color(0xFF992109),
                              ),
                            ),
                            const SizedBox(height: 24),
                            PokedexButton(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final newName = await changeUserNamePopup(
                                  context,
                                );
                                if (newName != null) {
                                  final result = await ApiService.setUserName(
                                    newName,
                                    session.token!,
                                  );
                                  final int resultCode = result['result_code'];
                                  if (resultCode == CallResultCode.ok) {
                                    session.setUserName(newName);
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Användarnamn ändrat",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        backgroundColor: Color(0xFFE3350D),
                                      ),
                                    );
                                  } else {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Kunde inte ändra användarnamn",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text("Ändra användarnamn"),
                            ),
                            const SizedBox(height: 16),
                            PokedexButton(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final result = await changePasswordPopup(
                                  context,
                                  session.token!,
                                );
                                if (result != null) {
                                  final resultCode = result['result_code'];
                                  if (resultCode == CallResultCode.ok) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Lösenord ändrat",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        backgroundColor: Color(0xFFE3350D),
                                      ),
                                    );
                                  } else {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Kunde inte ändra lösenord",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text("Byt lösenord"),
                            ),
                            const SizedBox(height: 16),
                            PokedexButton(
                              color: Colors.red.shade700,
                              onPressed: () {
                                session.logout();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const WelcomeScreen(),
                                  ),
                                );
                              },
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.logout, size: 20, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text("Logga ut"),
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
    );
  }
}
