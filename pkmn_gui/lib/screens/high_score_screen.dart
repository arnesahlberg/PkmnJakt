import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../api_calls.dart';
import '../widgets/common_app_bar.dart';
import '../main.dart';
import '../utils/auth_utils.dart'; // Import auth utilities

class HighScoreScreen extends StatefulWidget {
  const HighScoreScreen({super.key});
  @override
  State<HighScoreScreen> createState() => _HighScoreScreenState();
}

class _HighScoreScreenState extends State<HighScoreScreen> {
  List<dynamic> _pokemonList = [];
  bool _isLoading = true;

  Future<void> _loadHighScore() async {
    final session = Provider.of<UserSession>(context, listen: false);
    try {
      final result = await ApiService.viewFoundPokemon(10, session.token!);
      setState(() {
        _pokemonList = result['pokemon_found'] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Fel vid hämtning: $e")));
    }
  }

  @override
  void initState() {
    super.initState();
    AuthUtils.validateTokenAndRedirect(context).then((isValid) {
      if (isValid) {
        // Only load data if token validation passed
        _loadHighScore();
      }
    });
  }

  String _formatTime(String isoTime) {
    final dateTime = DateTime.parse(isoTime);
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: "Mina fångster"),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: _pokemonList.length,
                itemBuilder: (context, index) {
                  final pokemon = _pokemonList[index];
                  return ListTile(
                    title: Text(
                      "${pokemon['name']} (Nr. ${pokemon['number']})",
                    ),
                    subtitle: Text(
                      "Tid: ${_formatTime(pokemon['time_found'])}",
                    ),
                  );
                },
              ),
    );
  }
}
