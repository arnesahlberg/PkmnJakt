import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_calls.dart';
import '../main.dart'; // for UserSession
import '../widgets/data_matrix_scanner.dart';

class FoundPokemonScannerScreen extends StatefulWidget {
  const FoundPokemonScannerScreen({super.key});
  @override
  State<FoundPokemonScannerScreen> createState() =>
      _FoundPokemonScannerScreenState();
}

class _FoundPokemonScannerScreenState extends State<FoundPokemonScannerScreen> {
  bool _scanned = false;
  bool _isProcessing = false;

  void _onGetResult(String result) async {
    if (_scanned) return;
    _scanned = true;
    setState(() => _isProcessing = true);
    try {
      final session = Provider.of<UserSession>(context, listen: false);
      final foundResponse = await ApiService.foundPokemon(
        result,
        session.token!,
      );
      // sheck whether the Pokémon was already found.
      if (foundResponse['message'] == "Already found pokemon") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Du har redan hittat denna Pokémon")),
        );
        _scanned = false;
        setState(() => _isProcessing = false);
        return;
      }
      // successful catch: extract pokemon_id and message.
      final pokemonId = foundResponse['pokemon_id']?.toString();
      if (pokemonId == null) throw Exception("Koden tillhör inte en pokemon.");
      // fetch detailed pokemon info
      final pokemonInfo = await ApiService.getPokemon(pokemonId);
      if (!mounted) return;
      // show popup with pokemon info and image
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: const Text("Grattis!"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Du har fångat ${pokemonInfo['name']} ${pokemonInfo['number']}!",
                  ),
                  const SizedBox(height: 10),
                  Image.asset(
                    'assets/images/pkmn/$pokemonId.avif',
                    errorBuilder:
                        (context, error, stackTrace) =>
                            const Icon(Icons.image_outlined, size: 80),
                  ),
                  const SizedBox(height: 10),
                  Text(pokemonInfo['description'] ?? ''),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Reset _scanned before navigating to pokedex
                    setState(() {
                      _scanned = false;
                    });
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // return to main screen
                    Navigator.pushReplacementNamed(context, '/pokedex');
                  },
                  child: const Text("Visa Pokedex"),
                ),
                TextButton(
                  onPressed: () {
                    // Reset _scanned and then dismiss dialog and return to main screen
                    setState(() {
                      _scanned = false;
                    });
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // return to main screen
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                  child: const Text("Tillbaka"),
                ),
              ],
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Fel: $e")));
      _scanned = false;
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          DataMatrixScanner(
            onCodeScanned: _onGetResult,
            sheetTitle: "Scanna QR koden för att registrera hittad Pokémon",
          ),
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
