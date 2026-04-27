import 'package:flutter/material.dart';
import 'package:pkmn_gui/api_calls.dart';
import 'package:pkmn_gui/constants.dart';
import 'package:pkmn_gui/widgets/edit_user_popup.dart';
import 'package:pkmn_gui/widgets/login_popup.dart';
import 'package:pkmn_gui/widgets/reset_game_popup.dart';
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
  DateTime? _gameStartTime;
  DateTime? _gameEndTime;
  bool _gameTimesLoading = true;
  int _currentPage = 0;
  int _totalUsers = 0;
  List<dynamic> _users = [];
  final int _pageSize = 10;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final TextEditingController _adminIdController = TextEditingController();
  String _loginError = '';

  List<dynamic> _allPokemon = [];
  String _pokemonSearch = '';
  bool _pokemonLoading = true;
  final TextEditingController _pokemonSearchController =
      TextEditingController();

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
    _pokemonSearchController.dispose();
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
      await _fetchPokemonList(token);
      await _fetchGameTimes(token);
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchGameTimes(String token) async {
    try {
      final result = await AdminApiService.getGameTimes(token);
      setState(() {
        _gameStartTime = _parseGameTime(result['game_start_time'] as String?);
        _gameEndTime = _parseGameTime(result['game_end_time'] as String?);
        _gameTimesLoading = false;
      });
    } catch (e) {
      setState(() => _gameTimesLoading = false);
    }
  }

  DateTime? _parseGameTime(String? s) {
    if (s == null) return null;
    try {
      return DateTime.parse(s.replaceAll(' ', 'T'));
    } catch (_) {
      return null;
    }
  }

  String _formatGameTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$y-$mo-$d $h:$mi:00';
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

  Future<void> _fetchPokemonList(String token) async {
    setState(() => _pokemonLoading = true);
    try {
      final result = await AdminApiService.getAdminPokemonList(token);
      setState(() {
        _allPokemon = result['pokemon'] as List<dynamic>? ?? [];
        _pokemonLoading = false;
      });
    } catch (e) {
      setState(() => _pokemonLoading = false);
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
      final password = await promptForPassword(context);
      if (password == null || password.isEmpty) return;
      final loginResponse = await ApiService.login(adminId, password);
      if (loginResponse['result_code'] == 0 && loginResponse['token'] != null) {
        final name = loginResponse['name'] ?? "Admin";
        final encodedToken = loginResponse['token']['encoded_token'];
        final validUntil = loginResponse['token']['valid_until'];
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

  Widget _buildUsersTab(UserSession session) {
    return Column(
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
                  color: Colors.white,
                  child: ListTile(
                    title: Text(
                      'Användar id: $userId',
                      style: AppTextStyles.bodyLarge,
                    ),
                    subtitle: Text(
                      'Namn: $userName${isAdmin ? " (Admin)" : ""}',
                      style: AppTextStyles.bodyMedium,
                    ),
                    trailing: ElevatedButton(
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
                                    if (token != null) await _fetchUsers(token);
                                  },
                                ),
                          ),
                      style: AppButtonStyles.primaryButtonStyle,
                      child: const Text(
                        'Redigera',
                        style: AppTextStyles.buttonText,
                      ),
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
                  setState(() => _currentPage--);
                  final token = session.token;
                  if (token != null) await _fetchUsers(token);
                },
                style: AppButtonStyles.primaryButtonStyle,
                child: const Text('Previous', style: AppTextStyles.buttonText),
              ),
            if ((_currentPage + 1) * _pageSize < _totalUsers)
              ElevatedButton(
                onPressed: () async {
                  setState(() => _currentPage++);
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
      ],
    );
  }

  Future<void> _pickGameTime({
    required Future<void> Function(String value, String token) save,
    required DateTime? current,
    required void Function(DateTime) onPicked,
    required String token,
  }) async {
    final now = DateTime.now();
    final initialDate = current ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder:
          (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primaryRed,
              ),
            ),
            child: child!,
          ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      builder:
          (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primaryRed,
              ),
            ),
            child: child!,
          ),
    );
    if (time == null || !mounted) return;
    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    onPicked(picked);
    try {
      await save(_formatGameTime(picked), token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sparat: ${_formatGameTime(picked)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Misslyckades att spara: $e')));
      }
    }
  }

  Widget _buildSpelinstallningarTab(UserSession session) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          color: Colors.white,
          child: SwitchListTile(
            title: const Text(
              'Logga in med kamera och DataMatrix',
              style: AppTextStyles.bodyLarge,
            ),
            value: _datamatrixEnabled,
            activeThumbColor: AppColors.primaryRed,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.shade300,
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
                    SnackBar(
                      content: Text('Misslyckades att ändra inställning: $e'),
                    ),
                  );
                }
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        // Game timing section
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('Speltider', style: AppTextStyles.titleMedium),
        ),
        if (_gameTimesLoading)
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
            ),
          )
        else
          ..._buildGameTimeCards(session),
        const SizedBox(height: 24),
        // Reset game data section
        const Divider(),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Farlig zon',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ),
        Card(
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Återställ all speldata',
                  style: AppTextStyles.bodyLarge,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Raderar alla fångade Pokémon för samtliga användare. Milstolpar återställs automatiskt. Kan inte ångras.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    final token = session.token;
                    if (token == null) return;
                    showDialog(
                      context: context,
                      builder:
                          (_) => ResetGamePopup(
                            token: token,
                            onReset: () {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Speldata återställt.'),
                                  ),
                                );
                              }
                            },
                          ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: const Text('Återställ speldata'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGameTimeCards(UserSession session) {
    final token = session.token;
    return [
      Card(
        color: Colors.white,
        child: ListTile(
          title: const Text('Spelstart', style: AppTextStyles.bodyLarge),
          subtitle: Text(
            _gameStartTime != null
                ? _formatGameTime(_gameStartTime!)
                : 'Ej inställd',
            style: AppTextStyles.bodyMedium,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_calendar,
                  color: AppColors.primaryRed,
                ),
                tooltip: 'Ändra spelstart',
                onPressed:
                    token == null
                        ? null
                        : () => _pickGameTime(
                          save: AdminApiService.setGameStartTime,
                          current: _gameStartTime,
                          onPicked: (dt) => setState(() => _gameStartTime = dt),
                          token: token,
                        ),
              ),
              if (_gameStartTime != null)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  tooltip: 'Ta bort spelstart',
                  onPressed:
                      token == null
                          ? null
                          : () async {
                            await AdminApiService.setGameStartTime('', token);
                            setState(() => _gameStartTime = null);
                          },
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      Card(
        color: Colors.white,
        child: ListTile(
          title: const Text('Spelslut', style: AppTextStyles.bodyLarge),
          subtitle: Text(
            _gameEndTime != null
                ? _formatGameTime(_gameEndTime!)
                : 'Ej inställd',
            style: AppTextStyles.bodyMedium,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_calendar,
                  color: AppColors.primaryRed,
                ),
                tooltip: 'Ändra spelslut',
                onPressed:
                    token == null
                        ? null
                        : () => _pickGameTime(
                          save: AdminApiService.setGameEndTime,
                          current: _gameEndTime,
                          onPicked: (dt) => setState(() => _gameEndTime = dt),
                          token: token,
                        ),
              ),
              if (_gameEndTime != null)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  tooltip: 'Ta bort spelslut',
                  onPressed:
                      token == null
                          ? null
                          : () async {
                            await AdminApiService.setGameEndTime('', token);
                            setState(() => _gameEndTime = null);
                          },
                ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildPokemonTab(UserSession session) {
    if (_pokemonLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
        ),
      );
    }

    final filtered =
        _pokemonSearch.isEmpty
            ? _allPokemon
            : _allPokemon.where((p) {
              final name = (p['name'] as String? ?? '').toLowerCase();
              final id = p['id']?.toString() ?? '';
              return name.contains(_pokemonSearch.toLowerCase()) ||
                  id.contains(_pokemonSearch);
            }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final token = session.token;
                    if (token == null) return;
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                            title: const Text('Aktivera alla Pokémon'),
                            content: const Text(
                              'Vill du verkligen aktivera alla Pokémon?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Avbryt'),
                              ),
                              ElevatedButton(
                                style: AppButtonStyles.primaryButtonStyle,
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text(
                                  'Aktivera',
                                  style: AppTextStyles.buttonText,
                                ),
                              ),
                            ],
                          ),
                    );
                    if (confirmed != true) return;
                    try {
                      await AdminApiService.setAllPokemonActive(true, token);
                      await _fetchPokemonList(token);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Alla Pokémon aktiverade'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Misslyckades: $e')),
                        );
                      }
                    }
                  },
                  style: AppButtonStyles.primaryButtonStyle,
                  child: const Text(
                    'Aktivera alla',
                    style: AppTextStyles.buttonText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final token = session.token;
                    if (token == null) return;
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                            title: const Text('Inaktivera alla Pokémon'),
                            content: const Text(
                              'Vill du verkligen inaktivera alla Pokémon? Detta är svårt att ångra.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Avbryt'),
                              ),
                              ElevatedButton(
                                style: AppButtonStyles.primaryButtonStyle,
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text(
                                  'Inaktivera',
                                  style: AppTextStyles.buttonText,
                                ),
                              ),
                            ],
                          ),
                    );
                    if (confirmed != true) return;
                    try {
                      await AdminApiService.setAllPokemonActive(false, token);
                      await _fetchPokemonList(token);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Alla Pokémon inaktiverade'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Misslyckades: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        UIConstants.borderRadius8,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Inaktivera alla',
                    style: AppTextStyles.buttonText,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _pokemonSearchController,
            decoration: AppInputDecorations.defaultInputDecoration(
              'Sök Pokémon',
            ),
            style: AppTextStyles.bodyLarge,
            onChanged: (value) {
              setState(() => _pokemonSearch = value.trim());
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (_, index) {
              final pokemon = filtered[index];
              final pokemonId = pokemon['id'] as int? ?? 0;
              final pokemonName = pokemon['name'] as String? ?? '';
              final isActive = pokemon['active'] as bool? ?? false;
              return Card(
                color: Colors.white,
                child: ListTile(
                  title: Text(
                    '#$pokemonId $pokemonName',
                    style: AppTextStyles.bodyLarge,
                  ),
                  trailing: Switch(
                    value: isActive,
                    activeColor: AppColors.primaryRed,
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey.shade300,
                    onChanged: (value) async {
                      final token = session.token;
                      if (token == null) return;
                      setState(() {
                        pokemon['active'] = value;
                      });
                      try {
                        await AdminApiService.setPokemonActive(
                          pokemonId,
                          value,
                          token,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '$pokemonName ${value ? "aktiverad" : "inaktiverad"}',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() {
                          pokemon['active'] = !value;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Misslyckades att ändra status: $e',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<UserSession>(context);
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: const CommonAppBar(title: 'Admin-sida'),
        body: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Användare'),
                Tab(text: 'Spelinställningar'),
                Tab(text: 'Pokémon'),
              ],
              labelColor: AppColors.primaryRed,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primaryRed,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildUsersTab(session),
                  _buildSpelinstallningarTab(session),
                  _buildPokemonTab(session),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
