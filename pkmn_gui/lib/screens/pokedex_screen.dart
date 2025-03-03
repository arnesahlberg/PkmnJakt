import 'package:flutter/material.dart';
import 'package:pkmn_gui/widgets/common_app_bar.dart';
import 'package:provider/provider.dart';
import '../api_calls.dart';
import '../main.dart'; // for UserSession

class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key});
  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  late Future<List<dynamic>> _pokedexFuture;

  Future<List<dynamic>> _fetchPokedex() async {
    final session = Provider.of<UserSession>(context, listen: false);
    final result = await ApiService.getMyPokedex(session.token!);
    return result['pokedex'] as List<dynamic>;
  }

  @override
  void initState() {
    super.initState();
    _pokedexFuture = _fetchPokedex();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: "Stensund Pokemon-Jakt 2025"),
      body: FutureBuilder<List<dynamic>>(
        future: _pokedexFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final pokedex = snapshot.data!;
          return ListView.builder(
            itemCount: pokedex.length,
            itemBuilder: (context, index) {
              final pokemon = pokedex[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Image.asset(
                    'assets/images/pkmn/${pokemon['number']}.jpg',
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            const Icon(Icons.image_outlined, size: 48),
                  ),
                  title: Text("${pokemon['name']} (Nr. ${pokemon['number']})"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pokemon['description']),
                      Text("Höjd: ${pokemon['height']} m"),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
