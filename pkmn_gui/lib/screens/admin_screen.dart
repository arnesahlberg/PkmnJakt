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
  bool _datamatrixEnabled = true;
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
      final datamatrixEnabled = await ApiService.getDatamatrixLoginEnabled();
      setState(() {
        _datamatrixEnabled = datamatrixEnabled;
      });
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

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    final token = Provider.of<UserSession>(context, listen: false).token;
    if (token != null) {
      await _fetchTotalUsers(token);
      await _fetchUsers(token);
    }
    setState(() {
      _isLoading = false;
    });
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
                style: AppTextStyles.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _adminIdController,
                      decoration: AppInputDecorations.defaultInputDecoration(
                        'Admin ID',
                      ),
                      style: AppTextStyles.bodyLarge,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _handleAdminLogin,
                    style: AppButtonStyles.primaryButtonStyle,
                    child: const Text(
                      'Logga in admin',
                      style: AppTextStyles.buttonText,
                    ),
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
                style: AppButtonStyles.primaryButtonStyle,
                child: const Text(
                  'Gå tillbaka',
                  style: AppTextStyles.buttonText,
                ),
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
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: UIConstants.separatingHeight),
              ElevatedButton(
                onPressed:
                    () => Navigator.pushReplacementNamed(context, "/home"),
                style: AppButtonStyles.primaryButtonStyle,
                child: const Text(
                  'Gå tillbaka',
                  style: AppTextStyles.buttonText,
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
              decoration: AppInputDecorations.defaultInputDecoration(
                'Sök användare',
              ),
              style: AppTextStyles.bodyLarge,
              onChanged: (value) => _onSearchChanged(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: AppColors.primaryRed,
              backgroundColor: AppColors.white,
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
                        style: AppTextStyles.bodyLarge,
                      ),
                      subtitle: Text(
                        'Namn: $userName${isAdmin ? " (Admin)" : ""}',
                        style: AppTextStyles.bodyMedium,
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
                            style: AppButtonStyles.primaryButtonStyle,
                            child: const Text(
                              'Redigera',
                              style: AppTextStyles.buttonText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
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
                  style: AppButtonStyles.primaryButtonStyle,
                  child: const Text(
                    'Previous',
                    style: AppTextStyles.buttonText,
                  ),
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
                  style: AppButtonStyles.primaryButtonStyle,
                  child: const Text('Next', style: AppTextStyles.buttonText),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Sida ${_currentPage + 1} / ${(_totalUsers / _pageSize).ceil()}",
              style: AppTextStyles.bodyMedium,
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: SwitchListTile(
              title: const Text(
                'DataMatrix-inloggning aktiverad',
                style: AppTextStyles.bodyLarge,
              ),
              value: _datamatrixEnabled,
              onChanged: (value) async {
                final token = session.token;
                if (token == null) return;
                setState(() => _datamatrixEnabled = value);
                try {
                  await AdminApiService.setDatamatrixLoginEnabled(value, token);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'DataMatrix-inloggning ${value ? "aktiverad" : "inaktiverad"}',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  setState(() => _datamatrixEnabled = !value);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Misslyckades att ändra inställning: $e')),
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
