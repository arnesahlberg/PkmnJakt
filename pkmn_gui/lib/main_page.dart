import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart'; // for ApiService and UserSession
import 'widgets/common_app_bar.dart';
import 'package:intl/intl.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<dynamic> _pokemonList = [];
  bool _isLoading = true;

  Future<void> _loadData() async {
    final session = Provider.of<UserSession>(context, listen: false);
    try {
      final result = await ApiService.viewFoundPokemon(session.userId!, 10);
      setState(() {
        _pokemonList = result['pokemon_found'] as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Fel vid hämtning: $e")));
    }
  }

  String _formatTime(String isoTime) {
    final dateTime = DateTime.parse(isoTime);
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    return formatter.format(dateTime);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<UserSession>(context);
    return Scaffold(
      appBar: const CommonAppBar(title: "Startsida"),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Välkommen ${session.userName}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Dummy stats; extend as needed
                    const Text("Ranking: #10", style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 16),
                    const Text(
                      "Senaste fångade Pokémon:",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
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
                    ),
                  ],
                ),
              ),
    );
  }
}
