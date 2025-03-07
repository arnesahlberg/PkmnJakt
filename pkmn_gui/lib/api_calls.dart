import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://pkmnapi.notawebsitejustmynotebookgoaway.com'; // for release
  // 'https://192.168.0.73:8081'; // for local test

  static Map<String, String> _headers([String? token]) => {
    "Content-Type": "application/json",
    if (token != null) "Authorization": token,
  };

  // login
  // look for response on the form:
  //   Status code: 200
  // {
  //   "id": "123456",
  //   "token": {
  //     "encoded_token": "TOKEN-HERE",
  //     "valid_until": "2025-03-13T19:32:07.424672Z"
  //   },
  //   "name": "Leif Katt",
  //   "message": "Logged in as Leif Katt",
  //   "result_code": 0
  // }
  static Future<Map<String, dynamic>> login(String id, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      body: jsonEncode({'id': id, 'password': password}),
      headers: _headers(),
    );
    return jsonDecode(response.body);
  }

  // check if user exists
  // look for response on the form:
  static Future<bool> checkUserExists(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/user_exists/$id'));
    final json = jsonDecode(response.body);
    return json['exists'];
  }

  static Future<int> checkUserRanking(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/user_ranking/$id'));
    return int.parse(response.body);
  }

  // create user
  // look for response on the form:
  //   Status code: 200
  // {
  //   "id": "123456",
  //   "token": {
  //     "encoded_token": "TOKEN-HERE",
  //     "valid_until": "2025-03-13T19:32:07.386942Z"
  //   },
  //   "name": "Leif Katt",
  //   "message": "Created new user Leif Katt",
  //   "result_code": 0
  // }
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
      // changed from patch to post to avoid cors error
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

  static Future<bool> validateToken(String token) async {
    debugPrint('validateToken: $token');
    final response = await http.post(
      Uri.parse('$baseUrl/validate_token'),
      headers: _headers(token),
    );
    return response.statusCode == 200;
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

  //Get statistics (no Authorization required)
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

// admin stuff
class AdminApiService {
  static const String baseUrl = ApiService.baseUrl; // same as other

  // get am_i_admin
  static Future<bool> amIAdmin(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/am_i_admin'),
      headers: ApiService._headers(token),
    );
    return response.statusCode == 200;
  }

  // get users in interval (post)
  // returns on form:
  // {
  //   users: Vec<User>,
  //   message: String,
  //   result_code: CallResultCode,
  // }
  static Future<Map<String, dynamic>> getUsersInInterval(
    int n,
    int skip,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/get_users'),
      body: jsonEncode({'n': n, 'skip': skip}),
      headers: ApiService._headers(token),
    );
    return jsonDecode(response.body);
  }

  // get users filtering on id
  // returns as getUsersInInterval
  static Future<Map<String, dynamic>> getUsersFilter(
    String filter,
    int n,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/get_users_filter'),
      body: jsonEncode({'filter': filter, 'n': n}),
      headers: ApiService._headers(token),
    );
    return jsonDecode(response.body);
  }

  // delete user
  // checks if status_code is 200 and then it succeded return bool
  // give body {id: id}
  static Future<bool> deleteUser(String id, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin_delete_user'),
      body: jsonEncode({'id': id}),
      headers: ApiService._headers(token),
    );
    return response.statusCode == 200;
  }

  // reset user password
  // checks if status_code is 200 and then it succeded return bool
  // give input id and new_password
  static Future<bool> resetUserPassword(
    String id,
    String newPassword,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin_reset_user_password'),
      body: jsonEncode({'id': id, 'new_password': newPassword}),
      headers: ApiService._headers(token),
    );
    return response.statusCode == 200;
  }

  // check number of users
  // returns integer
  static Future<int> checkNumberOfUsers(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/num_users'),
      headers: ApiService._headers(token),
    );
    return int.parse(response.body);
  }

  //make user admin
  // input {id: id}
  // returns bool if status_code is 200 and body is true
  static Future<bool> makeUserAdmin(String id, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/make_user_admin'),
      body: jsonEncode({'id': id}),
      headers: ApiService._headers(token),
    );
    return response.statusCode == 200 && response.body == 'true';
  }

  //remove user admin
  // input {id: id}
  // returns bool if status_code is 200 and body is true
  static Future<bool> removeUserAdmin(String id, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/make_user_not_admin'),
      body: jsonEncode({'id': id}),
      headers: ApiService._headers(token),
    );
    return response.statusCode == 200 && response.body == 'true';
  }
}
