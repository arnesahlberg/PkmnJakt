import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api_calls.dart';
import '../main.dart'; // for UserSession
import '../widgets/data_matrix_scanner.dart';
import '../constants.dart';

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
      // Check CallResultCode for errors
      if (foundResponse['result_code'] != CallResultCode.ok) {
        if (foundResponse['result_code'] ==
            CallResultCode.pokemonAlreadyFound) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Du har redan hittat denna Pokémon")),
          );
        } else if (foundResponse['result_code'] ==
            CallResultCode.pokemonNotFound) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Koden du scannade tillhör inte en pokemon"),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Fel: ${foundResponse['result_code']}")),
          );
        }
        _scanned = false;
        setState(() => _isProcessing = false);
        return;
      }
      final pokemonId = foundResponse['pokemon_id']?.toString();
      if (pokemonId == null) {
        throw Exception("Koden du scannade tillhör inte en pokemon.");
      }
      // fetch detailed pokemon info
      final pokemonInfo = await ApiService.getPokemon(pokemonId);
      if (!mounted) return;
      // show popup with pokemon info and image
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text("Grattis!"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Du har fångat ${pokemonInfo['name']} ${pokemonInfo['number']}!",
                  ),
                  const SizedBox(height: 10),
                  Image.asset(
                    'assets/images/pkmn/$pokemonId.jpg',
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
                    // Dispose scanner and refresh by replacing the route
                    Navigator.pop(dialogContext); // close dialog
                    Navigator.pushReplacementNamed(context, '/pokedex');
                  },
                  child: const Text("Mitt Pokédex"),
                ),
                TextButton(
                  onPressed: () {
                    // Dispose scanner and refresh by replacing the route
                    Navigator.pop(dialogContext); // close dialog
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
          if (!_scanned) // Only show scanner when not processing a scan
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
