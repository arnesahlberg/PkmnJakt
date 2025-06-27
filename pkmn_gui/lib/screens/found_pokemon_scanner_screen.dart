import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_calls.dart';
import '../main.dart'; // for UserSession
import '../widgets/data_matrix_scanner.dart';
import '../widgets/pokedex_container.dart';
import '../widgets/pokedex_button.dart';
import '../constants.dart';

class FoundPokemonScannerScreen extends StatefulWidget {
  const FoundPokemonScannerScreen({super.key});
  @override
  State<FoundPokemonScannerScreen> createState() =>
      _FoundPokemonScannerScreenState();
}

class _FoundPokemonScannerScreenState extends State<FoundPokemonScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _scanned = false;
  bool _isProcessing = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _onGetResult(String result) async {
    if (_scanned) return;
    _scanned = true;
    setState(() => _isProcessing = true);
    try {
      final session = Provider.of<UserSession>(context, listen: false);
      debugPrint("foundPokemon: $result");
      debugPrint("token: ${session.token}");

      final foundResponse = await ApiService.foundPokemon(
        result,
        session.token!,
      );

      debugPrint("catchResult: $foundResponse");

      // Check CallResultCode for errors
      if (foundResponse['result_code'] != CallResultCode.ok) {
        if (foundResponse['result_code'] ==
            CallResultCode.pokemonAlreadyFound) {
          if (!mounted) return;

          // Set processing to false *before* showing the dialog
          setState(() => _isProcessing = false);

          // Show dialog for already caught Pokemon
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (dialogContext) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: PokedexContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: UIConstants.iconSizeHuge,
                            color: AppColors.primaryRed,
                          ),
                          const SizedBox(height: UIConstants.spacing16),
                          const Text(
                            "Redan fångad!",
                            style: AppTextStyles.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Du har redan hittat denna Pokémon",
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.secondaryRed,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          PokedexButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              Navigator.pushReplacementNamed(context, '/home');
                            },
                            child: const Text("Okej"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          );

          // Reset scanning after dialog is closed
          _scanned = false;
        } else if (foundResponse['result_code'] ==
            CallResultCode.pokemonNotFound) {
          if (!mounted) return;

          // Set processing to false *before* showing the dialog
          setState(() => _isProcessing = false);

          // Show dialog for invalid code
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (dialogContext) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: PokedexContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: UIConstants.iconSizeHuge,
                            color: AppColors.primaryRed,
                          ),
                          const SizedBox(height: UIConstants.spacing16),
                          const Text(
                            "Ogiltig kod",
                            style: AppTextStyles.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Koden du scannade tillhör inte en Pokémon",
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.secondaryRed,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          PokedexButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              Navigator.pushReplacementNamed(context, '/home');
                            },
                            child: const Text("Okej"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          );

          // Reset scanning after dialog is closed
          _scanned = false;
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Fel: ${foundResponse['result_code']}",
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
              backgroundColor: AppColors.primaryRed,
            ),
          );
          _scanned = false;
          setState(() => _isProcessing = false);
        }
        return;
      }

      final pokemonId = foundResponse['pokemon_id']?.toString();

      if (pokemonId == null) {
        throw Exception("Koden du scannade tillhör inte en pokemon.");
      }

      // Fetch pokemon details to get name and description
      final pokemonDetails = await ApiService.getPokemon(pokemonId);
      final pokemonName = pokemonDetails['name'];
      final pokemonDescription = pokemonDetails['description'];
      
      // Check if a milestone was reached
      final milestoneReached = foundResponse['milestone_reached'];

      if (!mounted) return;

      // Set processing to false *before* showing the dialog
      setState(() => _isProcessing = false);
      
      // If milestone was reached, show milestone dialog first
      if (milestoneReached != null) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: PokedexContainer(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.stars,
                        size: UIConstants.iconSizeHuge * 1.5,
                        color: Colors.amber,
                      ),
                      const SizedBox(height: UIConstants.spacing16),
                      const Text(
                        "MILSTOLPE!",
                        style: TextStyle(
                          fontFamily: 'PixelFontTitle',
                          fontSize: 28,
                          color: AppColors.primaryRed,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Du har fångat $milestoneReached Pokémon!",
                        style: const TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 20,
                          color: AppColors.secondaryRed,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        milestoneReached == 151 
                          ? "Grattis! Du har fångat alla 151 original Pokémon!"
                          : "Grattis! Här får du en $milestoneReached-medalj!",
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Milestone badge icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.amber,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "$milestoneReached",
                            style: const TextStyle(
                              fontFamily: 'PixelFontTitle',
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryRed,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      PokedexButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        child: const Text("Fortsätt"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        
        if (!mounted) return;
      }

      // show popup with pokemon info and image
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (dialogContext) => Dialog(
              // insetPadding: const EdgeInsets.all(16), // wider
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                // width:
                //     MediaQuery.of(dialogContext).size.width * 0.9, // screen 90%
                // height: MediaQuery.of(dialogContext).size.height * 0.9,
                child: PokedexContainer(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.catching_pokemon,
                            size: UIConstants.iconSizeHuge,
                            color: AppColors.primaryRed,
                          ),
                          const SizedBox(height: UIConstants.spacing16),
                          const Text(
                            "Grattis!",
                            style: AppTextStyles.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Du har fångat $pokemonName!",
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.secondaryRed,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            "(Nr. $pokemonId)",
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: 180,
                            height: 180,
                            padding: const EdgeInsets.all(
                              UIConstants.padding16,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(
                                UIConstants.borderRadius16,
                              ),
                              border: Border.all(
                                color: AppColors.secondaryRed,
                                width: UIConstants.borderWidth2,
                              ),
                            ),
                            child: Image.asset(
                              'assets/images/pkmn/$pokemonId.jpg',
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (context, error, stackTrace) => const Icon(
                                    Icons.image_outlined,
                                    size: 80,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (pokemonDescription != null &&
                              pokemonDescription.isNotEmpty)
                            Text(
                              pokemonDescription,
                              style: TextStyle(
                                fontFamily: 'PixelFont',
                                fontSize: 16,
                                color: Colors.grey.shade800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: PokedexButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/pokedex',
                                      );
                                    },
                                    child: const Text("Mitt Pokédex"),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: PokedexButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      Navigator.pushReplacementNamed(
                                        context,
                                        '/home',
                                      );
                                    },
                                    child: const Text("Tillbaka"),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Fel: $e", style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      _scanned = false;
      // Ensure processing is false even on error
      setState(() => _isProcessing = false);
    } finally {
      // No need to set _isProcessing here anymore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: AppBoxDecorations.gradientBackground,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                if (!_scanned) // Only show scanner when not processing a scan
                  Expanded(
                    child: DataMatrixScanner(
                      onCodeScanned: _onGetResult,
                      sheetTitle: "Scanna QR-koden för att fånga Pokémon",
                      scannerFormat: ScannerFormat.qrCode,
                    ),
                  ),
                PokedexContainer(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Rikta kameran mot Pokémonens QR-kod för att fånga den!',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isProcessing)
          Container(
            color: Colors.black45,
            child: Center(
              child: PokedexContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RotationTransition(
                      turns: _rotationController,
                      child: Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.secondaryRed,
                            width: UIConstants.borderWidth3,
                          ),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.catching_pokemon,
                              color: Color(0xFF992109),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Fångar Pokémon...',
                      style: TextStyle(
                        fontFamily: 'PixelFont',
                        fontSize: 16,
                        color: Color(0xFF992109),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
