import 'package:flutter/material.dart';
import 'package:pkmn_gui/api_calls.dart';
import 'package:pkmn_gui/constants.dart';
import 'package:pkmn_gui/screens/user_detail_screen.dart';
import 'package:pkmn_gui/widgets/edit_user_popup.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'package:pkmn_gui/widgets/common_app_bar.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);
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

  @override
  void initState() {
    super.initState();
    _checkAdminAndLoad();
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
      final result = await AdminApiService.getUsersFilterId(
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

  void _promoteUser(String userId) {
    // For demonstration we simply show a snackbar.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User $userId promoted to admin (dummy action)')),
    );
  }

  void _goToDetail(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserDetailScreen(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<UserSession>(context);
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
                child: const Text('Gå tillbaka'),
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
              decoration: const InputDecoration(
                labelText: 'Sök användare (användar id)',
                border: OutlineInputBorder(),
              ),
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
                    title: Text('Användar id: $userId'),
                    subtitle: Text(
                      'Namn: $userName${isAdmin ? " (Admin)" : ""}',
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
                                    ),
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
                  child: const Text('Next'),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
