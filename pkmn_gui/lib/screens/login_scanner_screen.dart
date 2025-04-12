import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/data_matrix_scanner.dart';
import '../widgets/pokedex_container.dart';
import '../api_calls.dart';
import '../main.dart';
import '../widgets/login_popup.dart';
import '../widgets/new_user_prompt.dart';
import '../constants.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});
  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _scanned = false;
  bool _isProcessing = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _onGetResult(String result) async {
    if (!_scanned) {
      _scanned = true;
      setState(() {
        _isProcessing = true;
      });
      final scannedId = result;
      String name;
      String encodedToken;
      String validUntil;

      try {
        if (scannedId.length > 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Koden du scannade är inte en lägerdeltagares kod",
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Color(0xFFE3350D),
            ),
          );
          setState(() {
            _isProcessing = false;
          });
          return;
        }

        final exists = await ApiService.checkUserExists(scannedId);
        if (exists) {
          final password = await promptForPassword(context);
          if (password == null || password.isEmpty) {
            setState(() {
              _isProcessing = false;
            });
            return;
          }
          final loginResult = await ApiService.login(scannedId, password);
          if (loginResult['result_code'] != CallResultCode.ok) {
            if (loginResult['result_code'] == CallResultCode.invalidPassword) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Fel lösenord, försök igen",
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Color(0xFFE3350D),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Något gick fel. Felkod: ${loginResult['result_code']}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
            setState(() {
              _isProcessing = false;
            });
            return;
          }
          name = loginResult['name'] ?? "Error fetching name";
          encodedToken =
              loginResult['token']?['encoded_token'].toString() ?? "";
          validUntil = loginResult['token']?['valid_until']?.toString() ?? "";
        } else {
          final credentials = await promptForUserCredentials(
            context,
            scannedId,
          );
          if (credentials == null ||
              credentials['username']?.isEmpty == true ||
              credentials['password']?.isEmpty == true ||
              credentials['confirm']?.isEmpty == true) {
            setState(() {
              _isProcessing = false;
            });
            return;
          }
          if (credentials['password'] != credentials['confirm']) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Lösenorden matchar inte",
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Color(0xFFE3350D),
              ),
            );
            setState(() {
              _isProcessing = false;
            });
            return;
          }
          name = credentials['username'] ?? "Could not fetch name";
          final password = credentials['password'] ?? "";
          final createResult = await ApiService.createUser(
            scannedId,
            name,
            password,
          );
          if (createResult['result_code'] != CallResultCode.ok) {
            if (createResult['result_code'] ==
                CallResultCode.userAlreadyExists) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Användaren finns redan",
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Color(0xFFE3350D),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Error: ${createResult['result_code']}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
            setState(() {
              _isProcessing = false;
            });
            return;
          }
          encodedToken =
              createResult['token']?['encoded_token']?.toString() ?? "";
          validUntil = createResult['token']?['valid_until']?.toString() ?? "";
        }
        if (!mounted) return;
        Provider.of<UserSession>(
          context,
          listen: false,
        ).login(scannedId, name, encodedToken, validUntil);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error: $e",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isProcessing = false;
        });
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _scanned = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFFFAF6F6), Colors.red.shade50],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                Expanded(
                  child: DataMatrixScanner(
                    onCodeScanned: _onGetResult,
                    sheetTitle: "Scanna QR-koden på ditt band för att logga in",
                    scannerFormat: ScannerFormat.dataMatrix,
                  ),
                ),
                PokedexContainer(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.qr_code_scanner,
                        size: 32,
                        color: Color(0xFFE3350D),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rikta kameran mot ditt deltagarband. Om du inte loggat in tidigare kommer du få skapa ett konto.',
                        style: TextStyle(
                          fontFamily: 'PixelFont',
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isProcessing)
          Container(
            color: Colors.black45,
            child: Center(
              child: PokedexContainer(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RotationTransition(
                      turns: _rotationController,
                      child: Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3350D),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF992109),
                            width: 3,
                          ),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.catching_pokemon,
                              color: Color(0xFF992109),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Processar...',
                      style: TextStyle(
                        fontFamily: 'PixelFont',
                        fontSize: 16,
                        color: Color(0xFF992109),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
