import 'package:flutter/material.dart';
import 'package:pkmn_gui/widgets/common_app_bar.dart';
import 'package:pkmn_gui/widgets/pokedex_container.dart';
import 'package:pkmn_gui/widgets/pokedex_button.dart';
import 'package:provider/provider.dart';
import '../api_calls.dart';
import '../main.dart';
import '../utils/auth_utils.dart';
import '../constants.dart';

class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key});
  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  late Future<List<dynamic>> _pokedexFuture;
  bool _isLoading = true;

  Future<List<dynamic>> _fetchPokedex() async {
    final session = Provider.of<UserSession>(context, listen: false);
    final result = await ApiService.getMyPokedex(session.token!);
    setState(() {
      _isLoading = false;
    });
    return result['pokedex'] as List<dynamic>;
  }

  @override
  void initState() {
    super.initState();
    AuthUtils.validateTokenAndRedirect(context).then((isValid) {
      if (isValid) {
        _pokedexFuture = _fetchPokedex();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: "Min Pokédex"),
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
                : FutureBuilder<List<dynamic>>(
                  future: _pokedexFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryRed,
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error: ${snapshot.error}",
                          style: const TextStyle(
                            color: AppColors.primaryRed,
                            fontFamily: 'PixelFont',
                          ),
                        ),
                      );
                    }

                    final pokedex = snapshot.data!;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          PokedexContainer(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: UIConstants.iconSizeSmall,
                                      height: UIConstants.iconSizeSmall,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.blue.shade300,
                                        border: Border.all(
                                          color: AppColors.white,
                                          width: UIConstants.borderWidth2,
                                        ),
                                        boxShadow: AppShadows.lightShadow,
                                      ),
                                    ),
                                    const SizedBox(width: UIConstants.spacing8),
                                    Text(
                                      "Fångade Pokémon: ${pokedex.length}",
                                      style: AppTextStyles.titleMedium,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: pokedex.length,
                                  itemBuilder: (context, index) {
                                    final pokemon = pokedex[index];
                                    return Container(
                                      margin: const EdgeInsets.only(
                                        bottom: UIConstants.spacing12,
                                      ),
                                      padding: const EdgeInsets.all(
                                        UIConstants.padding12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(
                                          UIConstants.borderRadius12,
                                        ),
                                        border: Border.all(
                                          color: AppColors.secondaryRed,
                                          width: UIConstants.borderWidth2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.secondaryRed
                                                .withOpacity(0.1),
                                            spreadRadius: 1,
                                            blurRadius: 4,
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    UIConstants.borderRadius8,
                                                  ),
                                              border: Border.all(
                                                color: AppColors.secondaryRed,
                                                width: UIConstants.borderWidth1,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(7),
                                              child: Image.asset(
                                                'assets/images/pkmn/${pokemon['number']}.jpg',
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.contain,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Icon(
                                                      Icons.image_outlined,
                                                      size: 48,
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  pokemon['name'],
                                                  style: const TextStyle(
                                                    fontFamily:
                                                        'PixelFontTitle',
                                                    fontSize: 18,
                                                    color: AppColors.primaryRed,
                                                  ),
                                                ),
                                                Text(
                                                  "Nr. ${pokemon['number']}",
                                                  style: TextStyle(
                                                    fontFamily: 'PixelFont',
                                                    fontSize: 14,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  pokemon['description'],
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primaryRed
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    "Höjd: ${pokemon['height']} m",
                                                    style: const TextStyle(
                                                      fontFamily: 'PixelFont',
                                                      fontSize: 12,
                                                      color: Color(0xFF992109),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
