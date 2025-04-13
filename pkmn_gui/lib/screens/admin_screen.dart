import 'package:flutter/material.dart';
import 'package:pkmn_gui/api_calls.dart';
import 'package:pkmn_gui/constants.dart';
import 'package:pkmn_gui/widgets/edit_user_popup.dart';
import 'package:pkmn_gui/widgets/login_popup.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'package:pkmn_gui/widgets/common_app_bar.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isAdmin = false;
  bool _isLoading = true;
  int _currentPage = 0;
  int _totalUsers = 0;
  List<dynamic> _users = [];
  final int _pageSize = 10;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final TextEditingController _adminIdController = TextEditingController();
  String _loginError = '';

  @override
  void initState() {
    super.initState();
    final token = Provider.of<UserSession>(context, listen: false).token;
    if (token != null) {
      _checkAdminAndLoad();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _adminIdController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminAndLoad() async {
    final token = Provider.of<UserSession>(context, listen: false).token;
    if (token == null) return;
    final isAdmin = await AdminApiService.amIAdmin(token);
    setState(() {
      _isAdmin = isAdmin;
    });
    if (isAdmin) {
      await _fetchTotalUsers(token);
      await _fetchUsers(token);
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchTotalUsers(String token) async {
    _totalUsers = await AdminApiService.checkNumberOfUsers(token);
  }

  Future<void> _fetchUsers(String token) async {
    if (_searchQuery.isEmpty) {
      final result = await AdminApiService.getUsersInInterval(
        _pageSize,
        _currentPage * _pageSize,
        token,
      );
      setState(() {
        _users = result['users'] ?? [];
        debugPrint('Users: $_users');
      });
    } else {
      final result = await AdminApiService.getUsersFilter(
        _searchQuery,
        _pageSize,
        token,
      );
      setState(() {
        _users = result['users'] ?? [];
      });
    }
  }

  void _onSearchChanged() {
    _searchQuery = _searchController.text.trim();
    _currentPage = 0;
    final token = Provider.of<UserSession>(context, listen: false).token;
    if (token != null) {
      _fetchUsers(token);
    }
  }

  // New method to handle admin login when not logged in
  Future<void> _handleAdminLogin() async {
    setState(() {
      _loginError = '';
    });
    final adminId = _adminIdController.text.trim();
    if (adminId.isEmpty) {
      setState(() {
        _loginError = "Ange ett giltigt id.";
      });
      return;
    }
    try {
      final userResponse = await ApiService.getUser(adminId);
      final user = userResponse['user'];
      if (user == null || user['admin'] != true) {
        setState(() {
          _loginError = "Det är inte ett adminkonto.";
        });
        return;
      }
      // Prompt for password
      final password = await promptForPassword(context);
      if (password == null || password.isEmpty) return;
      // Attempt login
      final loginResponse = await ApiService.login(adminId, password);
      if (loginResponse['result_code'] == 0 && loginResponse['token'] != null) {
        final name = loginResponse['name'] ?? "Admin";
        final encodedToken = loginResponse['token']['encoded_token'];
        final validUntil = loginResponse['token']['valid_until'];
        // Use the login method to set cookies instead of shared preferences
        Provider.of<UserSession>(
          context,
          listen: false,
        ).login(adminId, name, encodedToken, validUntil);
        setState(() {
          _isLoading = true;
        });
        await _checkAdminAndLoad();
      } else {
        setState(() {
          _loginError = "Fel lösenord.";
        });
      }
    } catch (e) {
      setState(() {
        _loginError = "Inloggning misslyckades.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<UserSession>(context);
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // New branch: when not logged in show the login form
    if (session.token == null) {
      return Scaffold(
        appBar: const CommonAppBar(title: 'Admin-sida'),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Det här är admin-sidan. Du måste logga in som admin.",
                style: TextStyles.welcomeTextStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _adminIdController,
                      decoration: InputDecoration(
                        labelText: 'Admin ID',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(color: Colors.black87),
                      ),
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _handleAdminLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE3350D),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Logga in admin'),
                  ),
                ],
              ),
              if (_loginError.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _loginError,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    () => Navigator.pushReplacementNamed(context, "/home"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE3350D),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Gå tillbaka'),
              ),
            ],
          ),
        ),
      );
    }
    // Existing branch for logged in users
    if (!_isAdmin) {
      return Scaffold(
        appBar: const CommonAppBar(
          title: 'Admin-panel',
          showBackButton: true,
          backRoute: '/home',
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Det här är en admin sida. Du har inte tillgång till den.',
                style: TextStyles.welcomeTextStyle,
              ),
              const SizedBox(height: UIConstants.separatingHeight),
              ElevatedButton(
                onPressed:
                    () => Navigator.pushReplacementNamed(context, "/home"),
                style: ButtonStyles.buttonStyleRounder,
                child: const Text(
                  'Gå tillbaka',
                  style: TextStyles.buttonTextStyle,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: CommonAppBar(title: 'Admin-sida'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Sök användare',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Colors.black87),
              ),
              style: TextStyle(color: Colors.black87),
              onChanged: (value) => _onSearchChanged(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _users.length,
              itemBuilder: (_, index) {
                final user = _users[index];
                final userId = user['user_id']?.toString() ?? 'okänd';
                final userName = user['name']?.toString() ?? '';
                final isAdmin = user['admin'] == true;
                return Card(
                  child: ListTile(
                    title: Text(
                      'Användar id: $userId',
                      style: TextStyle(
                        color: Colors.black,
                      ), // Changed to black for better contrast
                    ),
                    subtitle: Text(
                      'Namn: $userName${isAdmin ? " (Admin)" : ""}',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 36, 34, 34),
                      ), // Changed to grey for better readability
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed:
                              () => showDialog(
                                context: context,
                                builder:
                                    (context) => EditUserDialog(
                                      userId: userId,
                                      userName: userName,
                                      userIsAdmin: isAdmin,
                                      onUserUpdated: () async {
                                        final token =
                                            Provider.of<UserSession>(
                                              context,
                                              listen: false,
                                            ).token;
                                        if (token != null)
                                          await _fetchUsers(token);
                                      },
                                    ),
                              ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE3350D),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Redigera'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (_currentPage > 0)
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _currentPage--;
                    });
                    final token = session.token;
                    if (token != null) await _fetchUsers(token);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE3350D),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Previous'),
                ),
              if ((_currentPage + 1) * _pageSize < _totalUsers)
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _currentPage++;
                    });
                    final token = session.token;
                    if (token != null) await _fetchUsers(token);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE3350D),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Next'),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Sida ${_currentPage + 1} / ${(_totalUsers / _pageSize).ceil()}",
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
