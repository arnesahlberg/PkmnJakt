import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

Map<String, dynamic> decodeUtf8Json(http.Response response) {
  final decodedString = utf8.decode(response.bodyBytes);
  final decoded = jsonDecode(decodedString);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  } else {
    throw FormatException(
      'Expected Map<String, dynamic> but got ${decoded.runtimeType}',
    );
  }
}

class ApiService {
  static const String baseUrl = String.fromEnvironment('API_URL');

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
    return decodeUtf8Json(response);
  }

  // check if user exists
  // look for response on the form:
  static Future<bool> checkUserExists(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/user_exists/$id'));
    final json = decodeUtf8Json(response);
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
    return decodeUtf8Json(response);
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
    return decodeUtf8Json(response);
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
    return decodeUtf8Json(response);
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
    return decodeUtf8Json(response);
  }

  static Future<bool> validateToken(String token) async {
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
    final response = await http.post(
      Uri.parse('$baseUrl/found_pokemon'),
      body: jsonEncode({'catch_code': catchCode}),
      headers: _headers(token),
    );
    return decodeUtf8Json(response);
  }

  static Future<Map<String, dynamic>> viewFoundPokemon(
    int n,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/view_found_pokemon'),
      body: jsonEncode({'n': n}),
      headers: _headers(token),
    );
    return decodeUtf8Json(response);
  }

  //Get statistics (no Authorization required)
  static Future<Map<String, dynamic>> getStatisticsHighscore() async {
    final response = await http.get(Uri.parse('$baseUrl/statistics_highscore'));
    return decodeUtf8Json(response);
  }

  static Future<Map<String, dynamic>> getStatisticsLatestPokemonFound() async {
    final response = await http.get(
      Uri.parse('$baseUrl/statistics_latest_pokemon_found'),
    );
    return decodeUtf8Json(response);
  }

  // returns
  /*
    name: String,
    number: u32,
    photo_path: Option<String>, (won't use)
    description: Option<String>,
    height: f32,
  */
  static Future<Map<String, dynamic>> getPokemon(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/get_pokemon/$id'));
    return decodeUtf8Json(response);
  }

  static Future<Map<String, dynamic>> getMyPokedex(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/my_pokedex'),
      headers: _headers(token),
    );
    return decodeUtf8Json(response);
  }

  // get user
  // returns on form:
  //   {
  //     user: {
  //        user_id: String,
  //        name: String,
  //        email: Option<String>,
  //        phone : Option<String>,
  //        admin : bool,
  //     },
  //     message: String,
  //     result_code: CallResultCode,
  //   }
  static Future<Map<String, dynamic>> getUser(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/get_user/$id'));
    return decodeUtf8Json(response);
  }

  static Future<List<dynamic>> getUserPokedex(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/user_pokedex/$userId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load user pokedex: ${response.statusCode}');
    }
    // decode the response body
    // and return as List<dynamic>
    // this is a json array with pokemon data
    final decodedString = utf8.decode(response.bodyBytes);
    final List<dynamic> jsonList = jsonDecode(decodedString) as List<dynamic>;
    return jsonList.toList();
  }

  static Future<List<int>> getUserMilestones(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user_milestones/$userId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load user milestones: ${response.statusCode}');
    }
    final decodedString = utf8.decode(response.bodyBytes);
    final List<dynamic> jsonList = jsonDecode(decodedString) as List<dynamic>;
    return jsonList.map((e) => e as int).toList();
  }

  static Future<List<dynamic>> getUserMilestoneDefinitions(
    String userId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user_milestone_definitions/$userId'),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load user milestone definitions: ${response.statusCode}',
      );
    }
    final decodedString = utf8.decode(response.bodyBytes);
    final List<dynamic> jsonList = jsonDecode(decodedString) as List<dynamic>;
    return jsonList;
  }

  // Paginated highscores
  static Future<Map<String, dynamic>> getHighscores({
    required int page,
    int perPage = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/highscores?page=$page&per_page=$perPage'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load highscores: ${response.statusCode}');
    }
    return decodeUtf8Json(response);
  }

  // Search highscores
  static Future<Map<String, dynamic>> searchHighscores({
    required String search,
    required int page,
    int perPage = 20,
  }) async {
    final encodedSearch = Uri.encodeQueryComponent(search);
    final response = await http.get(
      Uri.parse(
        '$baseUrl/highscores/search?search=$encodedSearch&page=$page&per_page=$perPage',
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to search highscores: ${response.statusCode}');
    }
    return decodeUtf8Json(response);
  }

  // Get user Pokemon count by type
  static Future<Map<String, dynamic>> getUserPokemonByType(
    String userId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user_pokemon_by_type/$userId'),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load user Pokemon by type: ${response.statusCode}',
      );
    }
    final decodedString = utf8.decode(response.bodyBytes);
    final decoded = jsonDecode(decodedString);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    } else if (decoded is List) {
      // If API returns a list, convert it to a Map
      // Assuming the list contains objects with 'type' and 'count' fields
      final Map<String, dynamic> typeMap = {};
      for (var item in decoded) {
        if (item is Map<String, dynamic> &&
            item.containsKey('type') &&
            item.containsKey('count')) {
          typeMap[item['type']] = item['count'];
        }
      }
      return typeMap;
    } else {
      // Return empty map as fallback
      return {};
    }
  }

  // Get total Pokemon count by type (global statistics)
  static Future<Map<String, dynamic>> getTotalPokemonByType() async {
    final response = await http.get(
      Uri.parse('$baseUrl/total_pokemon_by_type'),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load total Pokemon by type: ${response.statusCode}',
      );
    }
    return decodeUtf8Json(response);
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
    if (response.statusCode != 200 && response.statusCode != 401) {
      throw Exception('Failed to check admin status: ${response.statusCode}');
    }
    final json = decodeUtf8Json(response);
    return json['is_admin'] ?? false;
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
    return decodeUtf8Json(response);
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
    return decodeUtf8Json(response);
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
