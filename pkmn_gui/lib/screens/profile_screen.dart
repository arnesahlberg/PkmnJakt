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
import '../widgets/type_badge.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _typeStats;

  @override
  void initState() {
    super.initState();
    AuthUtils.validateTokenAndRedirect(context).then((isValid) async {
      if (isValid && mounted) {
        final session = Provider.of<UserSession>(context, listen: false);
        try {
          final typeStats = await ApiService.getUserPokemonByType(
            session.userId!,
          );
          if (mounted) {
            setState(() {
              _typeStats = typeStats;
              _isLoading = false;
            });
          }
        } catch (e) {
          if (mounted && isBackendUnavailableError(e)) {
            Navigator.pushReplacementNamed(context, '/backend_unavailable');
            return;
          }
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<UserSession>(context);

    return Scaffold(
      appBar: const CommonAppBar(title: 'Min Profil'),
      body: Container(
        decoration: AppBoxDecorations.gradientBackground,
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryRed,
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
                              size: UIConstants.iconSizeMax,
                              color: AppColors.primaryRed,
                            ),
                            const SizedBox(height: UIConstants.spacing16),
                            Text(
                              session.userName ?? '',
                              style: AppTextStyles.titleLarge,
                            ),
                            Text(
                              "Tränare ID: ${session.userId}",
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.secondaryRed,
                              ),
                            ),
                            const SizedBox(height: UIConstants.spacing24),
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
                                  Icon(
                                    Icons.logout,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text("Logga ut"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_typeStats != null && _typeStats!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: PokedexContainer(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Center(
                                  child: Text(
                                    "Mina Pokémon-typer",
                                    style: TextStyle(
                                      fontFamily: 'PixelFontTitle',
                                      fontSize: 18,
                                      color: AppColors.primaryRed,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ..._typeStats!.entries
                                    .where((entry) => entry.value > 0)
                                    .map(
                                      (entry) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4.0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            TypeBadge(typeName: entry.key),
                                            Text(
                                              '${entry.value} st',
                                              style: const TextStyle(
                                                fontFamily: 'PixelFont',
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
      ),
    );
  }
}
