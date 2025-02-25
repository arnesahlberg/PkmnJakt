import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart'; // import UserSession from main.dart

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const CommonAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<UserSession>(context);
    return AppBar(
      title: Text(title, style: const TextStyle(fontFamily: 'PixelFontTitle')),
      // Added a gradient background
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.blue, Colors.yellow],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        if (session.isLoggedIn)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.pushNamed(context, '/profile');
              } else if (value == 'logout') {
                session.logout();
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            itemBuilder:
                (context) => const [
                  PopupMenuItem(value: 'profile', child: Text('Profil')),
                  PopupMenuItem(value: 'logout', child: Text('Logga ut')),
                ],
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
