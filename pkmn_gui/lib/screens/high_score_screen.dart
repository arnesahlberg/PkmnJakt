import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../api_calls.dart';
import '../widgets/common_app_bar.dart';
import '../main.dart'; // for UserSession

class HighScoreScreen extends StatefulWidget {
  const HighScoreScreen({super.key});
  @override
  State<HighScoreScreen> createState() => _HighScoreScreenState();
}

class _HighScoreScreenState extends State<HighScoreScreen> {
  List<dynamic> _pokemonList = [];
  bool _isLoading = true;

  Future<void> _validateToken() async {
    final session = Provider.of<UserSession>(context, listen: false);
    if (session.token == null) {
      _redirectToWelcome();
      return;
    }

    try {
      final isValid = await ApiService.validateToken(session.token!);
      if (!isValid || session.isExpored()) {
        _redirectToWelcome();
      }
    } catch (e) {
      _redirectToWelcome();
    }
  }

  void _redirectToWelcome() {
    final session = Provider.of<UserSession>(context, listen: false);
    session.logout();

    Future.delayed(Duration.zero, () {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    });
  }

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
    _validateToken().then((_) {
      // Only load data if token validation passed
      _loadHighScore();
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
