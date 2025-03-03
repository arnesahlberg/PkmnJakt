import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://pkmnapi.notawebsitejustmynotebookgoaway.com'; // for release
  // 'https://192.168.0.73:8081 '; // for local test

  static Map<String, String> _headers([String? token]) => {
    "Content-Type": "application/json",
    if (token != null) "Authorization": token,
  };

  static Future<Map<String, dynamic>> login(String id, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      body: jsonEncode({'id': id, 'password': password}),
      headers: _headers(),
    );
    return jsonDecode(response.body);
  }

  static Future<bool> checkUserExists(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/user_exists/$id'));
    final json = jsonDecode(response.body);
    return json['exists'];
  }

  static Future<int> checkUserRanking(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/user_ranking/$id'));
    return int.parse(response.body);
  }

  static Future<Map<String, dynamic>> createUser(
    String id,
    String name,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create_user'),
      body: jsonEncode({'id': id, 'name': name, 'password': password}),
      headers: _headers(),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> setUserName(
    String name,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/set_user_name'),
      body: jsonEncode({'name': name}),
      headers: _headers(token),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> setNewPassword(
    String oldPassword,
    String newPassword,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/set_password'),
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
      headers: _headers(token),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> validatePassword(
    String password,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/validate_password'),
      body: jsonEncode({'password': password}),
      headers: _headers(token),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> foundPokemon(
    String catchCode,
    String token,
  ) async {
    debugPrint('foundPokemon: $catchCode');
    debugPrint("token: $token");
    final response = await http.post(
      Uri.parse('$baseUrl/found_pokemon'),
      body: jsonEncode({'catch_code': catchCode}),
      headers: _headers(token),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> viewFoundPokemon(
    int n,
    String token,
  ) async {
    debugPrint('viewFoundPokemon: $n');
    debugPrint("token: $token");
    final response = await http.post(
      Uri.parse('$baseUrl/view_found_pokemon'),
      body: jsonEncode({'n': n}),
      headers: _headers(token),
    );
    return jsonDecode(response.body);
  }

  // New: Get statistics (no Authorization required)
  static Future<Map<String, dynamic>> getStatisticsHighscore() async {
    final response = await http.get(Uri.parse('$baseUrl/statistics_highscore'));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getStatisticsLatestPokemonFound() async {
    final response = await http.get(
      Uri.parse('$baseUrl/statistics_latest_pokemon_found'),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getPokemon(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/get_pokemon/$id'));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getMyPokedex(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/my_pokedex'),
      headers: _headers(token),
    );
    return jsonDecode(response.body);
  }
}
